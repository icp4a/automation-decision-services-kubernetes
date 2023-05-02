#!/bin/bash

ads_namespace="ads"
output_dir=.
log_to_stdout=true

while getopts "n:d:l" opt; do
    case $opt in
    n)
        ads_namespace=${OPTARG}
        ;;
    d)
        output_dir=${OPTARG}
        ;;
    l)
        log_to_stdout=
        ;;
    *)
        echo "Incorrect options provided"
        exit 1
        ;;
    esac
done
shift $((OPTIND-1))

source "${BASH_SOURCE%/*}/common.sh"

rest_api_pods=( $("$KUBECTL" -n "$ads_namespace" get pods -l app.kubernetes.io/name=ads-rest-api 2>/dev/null | awk -F " " '$3 == "Running" {print $1}') )

if [[ ${#rest_api_pods[@]} -eq 0 ]] ; then
   gather_log "Failed to identify a running ADS rest-api pod."
else
   rest_api_pod=${rest_api_pods[0]}
   versionfile="$output_dir/ads_versions.txt"
   gather_log "Extracting ADS component versions from pod $rest_api_pod into file ${versionfile#$output_dir/}."

   "$KUBECTL" exec -n "$ads_namespace" "$rest_api_pod" -c rest-api \
      -- curl --silent --connect-timeout 5 --retry 5 --retry-delay 1 --retry-connrefused -k https://localhost:9443/ads/rest-api/about > "$versionfile"
fi
