#!/usr/bin/env bash

usage() {
  echo "$0 [-h] [-s duration] [-o <output-directory>] [-n <ads_namespace>] [-d <must_gather_dir] [<incident-id>]"
  echo
  echo "Searches for incident IDs in ADS Runtime pods.  If <incident-id> is not given, search for all the ticket ids in the time frame."
  echo "By default it works on a remote cluster, provided that the kubectl command is configured to access this cluster."
  echo "If the -d option is provided, it works on logs gathered by the gather.sh command."
  echo
  echo "Options:"
  echo "  -s   option is equivalent to --since option in kubectl logs command i.e taking a duration controlling the amount of logs to scan."
  echo "  -o   is used to write the log file for a given incident-id. Default value is /tmp/ads and file name will always follow this pattern <incident-id>.log"
  echo "  -n   name of the Kubernetes namespace where ADS is installled; defaults to 'ads'."
  echo "  -d   path of the folder where the tar.gz file has been uncompressed; the command will search in"
  echo "       these files instead of reaching for the Kubernetes cluster."
  echo "       Incompatible with the -s option."
}

since=""
output_directory='/tmp/ads'
ads_namespace=ads
gather_dir=
while getopts "hso:n:d:" opt; do
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

display_incident_logs() {
  incident_line="$1"
  echo ${incident_line} | ./json2log
  if [ "${incident_line}" != "null" ] && [ "${incident_line}" != "" ]; then
    current_correlation_id=$(echo ${incident_line} | grep -o 'incidentId=[^, }]*' | sed 's/^.*=//' )
    # Remove trailing ] character
    current_correlation_id=${current_correlation_id::${#current_correlation_id}-1}
    log_file_name="$output_directory/$current_correlation_id.log"
    touch "${log_file_name}"
    echo ${incident_line} | ./json2log > "${log_file_name}" 2>&1
    echo "${current_correlation_id} correlationId details saved in ${log_file_name}"
  fi
}

incident_id=$1
if [[ ! -z ${incident_id} ]]; then
  echo "Searching for a specific incident id: ${incident_id}."
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
  runtime_service_pods=( $(kubectl get pod -o name | grep runtime-service) )
else
  shopt -s nullglob
  runtime_service_pods=( "$gather_dir/namespaces/$ads_namespace/"*runtime-service* )
  shopt -u nullglob
fi
if [[ ${#runtime_service_pods[@]} == 0 ]]; then
  echo "Cannot find runtime-service pods."
  exit 2
fi

for pod in "${runtime_service_pods[@]}"; do
  if [[ -z ${incident_id} ]]; then
    # No specific incident-id provided, search for any we can find in logs.
    if [[ -z ${gather_dir} ]] ; then
      incident_lines=$(kubectl -n "$ads_namespace" logs ${pod} ${since_flag} | grep "incidentId=")
    else
      incident_lines=$(grep -rh "incidentId==" "$pod/container_logs/")
    fi

    while IFS= read -r incident_line; do
      display_incident_logs "${incident_line}"
    done <<< "${incident_lines}"
  else
    # Searching one line in log with a specific incident-id.
    incident_line=$(kubectl logs ${pod} ${since_flag} | grep "incidentId=${incident_id}")
    if [[ -z ${gather_dir} ]] ; then
      incident_line=$(kubectl -n "$ads_namespace" logs ${pod} ${since_flag} | grep "incidentId=${incident_id}")
    else
      incident_line=$(grep -rh "incidentId=${incident_id}" "$gather_dir/namespaces/$ads_namespace/$pod/container_logs/")
    fi

    if [[ ! -z ${incident_line} ]]; then
      echo "Found incident id in ${pod}"
      display_incident_logs "${incident_line}"
      # display all lines as we want to see the full trace
      # Once found, we know that it's not necessary to search for it in another pod logs.
      break;
    fi
  fi
done

if [[ -z ${incident_line} && ! -z ${incident_id} ]]; then
  echo "incident_id ${incident_id} not found."
  exit 3
fi

