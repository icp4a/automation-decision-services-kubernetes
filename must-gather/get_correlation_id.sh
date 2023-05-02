#!/usr/bin/env bash
shopt -s extglob

usage() {
  echo "$0 [-h] [-s duration] [-n <ads_namespace>] [-d <must_gather_dir] <correlationId>"
  echo
  echo "Searches for an ADS correlation ID in logs of ADS pods."
  echo "By default it works on a remote cluster, provided that the kubectl command is configured to access this cluster."
  echo "If the -d option is provided, it works on logs gathered by the gather.sh command."
  echo
  echo "Options:"
  echo "  -s   is equivalent to --since option in kubectl logs command i.e taking a duration controlling the amount of logs to scan."
  echo "       Incompatible with the -d option."
  echo "  -n   name of the Kubernetes namespace where ADS is installled; defaults to 'ads'."
  echo "  -d   path of the folder where the tar.gz file has been uncompressed; the command will search in"
  echo "       these files instead of reaching for the Kubernetes cluster."
  echo "       Incompatible with the -s option."
  echo "  Mandatory <correlationId>"
}

display_log_line() {
  ticket_line="$1"
  echo "${ticket_line}" | ./json2log
}

ads_namespace=ads
since=""
gather_dir=
while getopts "hs:n:d:" opt; do
    case $opt in
    h)
        usage
        exit 1
        ;;
    s)
        since=${OPTARG}
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

correlationId=$1
if [[ ! -z ${correlationId} ]]; then
  echo "Searching for a specific correlationId: ${correlationId}."
else
  echo "Missing <correlationId> parameter"
  exit 1
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
  designer_pods=( $(kubectl -n "$ads_namespace" get pod -o name | grep 'rest-api\|embedded-build-service\|parsing-service\|run-service\|credentials-service\|git-service') )
else
  shopt -s nullglob
  designer_pods=( "$gather_dir/namespaces/$ads_namespace/"@(*rest-api*|*embedded-build-service*|*parsing-service*|*run-service*|*credentials-service*|*git-service*) )
  shopt -u nullglob
fi
if [[ ${#designer_pods[@]} == 0 ]]; then
  echo "Cannot find ADS Designer pods."
  exit 2
fi


something_found=""
for pod in "${designer_pods[@]}"; do
  echo "Searching in pod ${pod}"
  # Searching one line in log with a specific correlationId.
  if [[ -z ${gather_dir} ]] ; then
    ticket_line=$(kubectl -n "$ads_namespace" logs ${pod} ${since_flag} | grep "${correlationId}")
  else
    ticket_line=$(grep -rh "${correlationId}" "$pod/container_logs/")
  fi
  something_found=something_found+$ticket_line
  if [[ ! -z ${ticket_line} ]]; then
    echo "Found correlation id in ${pod}"
    display_log_line "${ticket_line}"
  else
    echo "nothing found in this pod"
  fi
done

if [[ -z ${something_found} && ! -z ${correlationId} ]]; then
  echo "correlation id '${correlationId}' not found."
  exit 3
fi

