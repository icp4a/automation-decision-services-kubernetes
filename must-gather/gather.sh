#!/bin/bash

set -o nounset

usage() {
  echo "${BASH_SOURCE##*/} [-h] [-a <ADS namespace>] [-o <OLM namespace>] [-s <since>] [-d <work dir>]"
  echo
  echo "This command gathers all details from an ADS installation required by"
  echo "the IBM supports to investigate support requests."
  echo "It generates a tar.gz file that can be sent to the IBM support team."
  echo "The kubectl command is required by this command.  It must be configured to allow"
  echo "access to the Kubernetes cluster."
  echo
  echo "Options:"
  echo "  -a  name of the Kubernetes namespace where ADS is installed, default is 'ads'"
  echo "  -o  name of the Kubernetes namespace where OLM is installed, default is 'olm'"
  echo "  -s  only gather pod logs newer than a relative duration like 5s, 2m, or 3h."
  echo "      Default is to gather all logs.  Accepts a value compatible with the --since option"
  echo "      of the 'kubectl logs' command."
  echo "  -d  path of an existing directory where this command can create temporary working"
  echo "      directory and the resulting tar.gz file.  Defaults to the current directory."
}

ads_namespace=ads
olm_namespace=olm
since=0s
work_dir=.

while getopts "ha:o:s:d:" opt; do
    case $opt in
    h)
        usage
        exit 1
        ;;
    a)
        ads_namespace=${OPTARG}
        ;;
    o)
        olm_namespace=${OPTARG}
        ;;
    s)
        since=${OPTARG}
        ;;
    d)
        work_dir=${OPTARG}
        ;;
    *)
        echo "Incorrect options provided"
        exit 1
        ;;
    esac
done
shift $((OPTIND-1))

output_dir_base=ads_must_gather-$(date +%Y-%m-%d-%H:%M:%S)
output_dir="$work_dir/$output_dir_base"
mkdir "$output_dir"
if [[ $? -ne 0 ]] ; then
   exit 1
fi

script_base_dir="${BASH_SOURCE%/*}"
gather_scripts="$script_base_dir/gather_scripts"

source "$gather_scripts/common.sh"

printf "Details of progress logged into $output_dir/gather_log.txt\n"

gather_log "Must-gather for ADS Standalone"
gather_log "Params:"
gather_log "  OLM namespace: '$olm_namespace'"
gather_log "  ADS namespace: '$ads_namespace'"
gather_log "  gather logs since: $since"
gather_log ""
gather_log "Start time: $(date)"

if ! $KUBECTL get ns "$ads_namespace" >/dev/null  2>&1; then
   printf "ADS namespace '$ads_namespace' doesn't exist\n"
   exit 1
fi

if ! $KUBECTL get ns "$olm_namespace" >/dev/null  2>&1; then
   printf "OLM namespace '$olm_namespace' doesn't exist\n"
   exit 1
fi

printf "Gathering cluster details..."
"$gather_scripts"/gather_cluster_details.sh -d "$output_dir" -l
printf " done.\n"

printf "Gathering resources from OLM install..."
"$gather_scripts"/gather_olm_install.sh -n "$olm_namespace" -s "$since" -d "$output_dir" -l
printf " done.\n"

printf "Gathering resources from ADS install..."
"$gather_scripts"/gather_ads_install.sh -n "$ads_namespace" -s "$since" -d "$output_dir" -l
printf " done.\n"

gather_log ""
gather_log "End time: $(date)"

tarball="$work_dir/${output_dir_base}.tgz"
printf "Generating tarball $tarball..."
tar -czf "$tarball" -C "$work_dir" "$output_dir_base"
printf " done.\n"
printf "Please send this tar file to IBM support: $tarball\n"
