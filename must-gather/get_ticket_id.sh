#!/usr/bin/env bash
shopt -s extglob

usage() {
  echo "$0 [-h] [-s duration] [-o <output-directory>] [-n <ads_namespace>] [-d <must_gather_dir] [-v] [<ticket-id>] "
  echo
  echo "Searches for ADS tickets IDs in ADS pods.  If <ticket-id> is not given, search for all the ticket ids in the time frame."
  echo "By default it works on a remote cluster, provided that the kubectl command is configured to access this cluster."
  echo "If the -d option is provided, it works on logs gathered by the gather.sh command."
  echo
  echo "Options:"
  echo "  -s   option is equivalent to --since option in kubectl logs command i.e taking a duration controlling the amount of logs to scan."
  echo "       Incompatible with the -d option."
  echo "  -n   name of the Kubernetes namespace where ADS is installled; defaults to 'ads'."
  echo "  -o   is used to write the log file for a given ticket-id. Default value is /tmp/ads and file name will always follow this pattern <ticket-id>.log"
  echo "  -v   is a search correlation_ids capability flag. For easier reading, this is saved in files "
  echo "  -d   path of the folder where the tar.gz file has been uncompressed; the command will search in"
  echo "       these files instead of reaching for the Kubernetes cluster."
  echo "       Incompatible with the -s option."
}

since=""
ads_namespace=ads
search_ticket_details=false
output_directory='/tmp/ads'
gather_dir=
while getopts "hvso:n:d:" opt; do
    case $opt in
    h)
        usage
        exit 1
        ;;
    s)
        since=${OPTARG}
        ;;
    o)
        output_directory=${OPTARG}
        ;;
    v)
        search_ticket_details=true
        ;;
    n)
        ads_namespace=${OPTARG}
        ;;
    d)
        gather_dir=${OPTARG}
        ;;
    *)
        echo "Incorrect options provided"
        exit 1
        ;;
    esac
done
shift $((OPTIND-1))

echo "creating output directory ${output_directory}"
mkdir -p "${output_directory}"

display_ticket_logs() {
  ticket_line="$1"
  echo "${ticket_line}" | ./json2log
  current_correlation_id=$(jq .correlationId <<< ${ticket_line})
  current_ticket_id=$(jq '."ticket-id"' <<< ${ticket_line})
  current_ticket_id_without_dquotes=${current_ticket_id#"\""}
  current_ticket_id_without_dquotes=${current_ticket_id_without_dquotes%"\""}
  if [[ ! -z ${current_correlation_id} ]]; then
    echo "For further logs regarding ticket_id '${current_ticket_id}', search with correlationId=${current_correlation_id}"
  fi
  if [ ${search_ticket_details} ] && [ "${current_correlation_id}" == "null" ]; then
    echo "sorry for no correlation_id to find for ticket_id ${current_ticket_id}"
  fi
  if [ ${search_ticket_details} ] && [ "${current_correlation_id}" != "null" ] && [ "${current_correlation_id}" != "" ]; then
    echo "Looking deeper for details on ticket ${current_ticket_id} with this correlation_id ${current_correlation_id}"
    ticket_log_file_name="$output_directory/$current_ticket_id_without_dquotes.log"
    touch "${ticket_log_file_name}"
    if [[ -z ${gather_dir} ]] ; then
      ./get_correlation_id.sh -n "$ads_namespace" "${current_correlation_id}" > "${ticket_log_file_name}" 2>&1
    else
      ./get_correlation_id.sh -n "$ads_namespace" -d "${gather_dir}" "${current_correlation_id}" > "${ticket_log_file_name}" 2>&1
    fi
    echo "${current_ticket_id} ticket details saved in ${ticket_log_file_name}"
  fi
}

ticket_id=$1
if [[ ! -z ${ticket_id} ]]; then
  echo "Searching for a specific ticket id: ${ticket_id}."
fi

since_flag=""
if [[ ! -z ${since} && ! -z ${gather_dir} ]]; then
  echo "-s option is incompatible with the -d option"
  exit 1
fi
if [[ ! -z ${since} ]]; then
  since_flag="--since ${since}"
  echo "Searching for duration ${since}..."
fi

if [[ -z ${gather_dir} ]] ; then
  designer_pods=( $(kubectl get pod -o name | grep 'rest-api\|git-service') )
else
  shopt -s nullglob
  designer_pods=( "$gather_dir/namespaces/$ads_namespace/"@(*rest-api*|*git-service*) )
  shopt -u nullglob
fi
if [[ ${#designer_pods[@]} == 0 ]]; then
  echo "Cannot find any rest-api or git-service pods."
  exit 2
fi

for pod in "${designer_pods[@]}"; do
  if [[ -z ${ticket_id} ]]; then
    # No specific ticket-id provided, search for any we can find in logs.
    if [[ -z ${gather_dir} ]] ; then
      ticket_lines=$(kubectl -n "$ads_namespace" logs ${pod} ${since_flag} | grep "ticket-id=")
    else
      ticket_lines=$(grep -rh "ticket-id=" "$pod/container_logs/")
    fi

    while IFS= read -r ticket_line; do
      display_ticket_logs "${ticket_line}"
    done <<< "${ticket_lines}"
  else
    # Searching one line in log with a specific ticket-id.
    if [[ -z ${gather_dir} ]] ; then
      ticket_line=$(kubectl -n "$ads_namespace" logs ${pod} ${since_flag} | grep "ticket-id=${ticket_id}")
    else
      ticket_line=$(grep -rh "ticket-id=${ticket_id}" "$gather_dir/namespaces/$ads_namespace/$pod/container_logs/")
    fi

    if [[ ! -z ${ticket_line} ]]; then
      echo "Found ticket id in ${pod}"
      display_ticket_logs "${ticket_line}"
      # display all lines as we want to see the full trace
      # Once found, we know that it's not necessary to search for it in another pod logs.
      break;
    fi
  fi
done

if [[ -z ${ticket_line} && ! -z ${ticket_id} ]]; then
  echo "ticket_id ${ticket_id} not found."
  exit 3
fi

