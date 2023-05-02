#!/bin/bash

log_to_stdout=true
output_dir=.

while getopts "d:l" opt; do
    case $opt in
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

cluster_outdir="$output_dir/cluster"
mkdir -p  "$cluster_outdir"

"$KUBECTL" version -o yaml > "$cluster_outdir/version" 2>>"$outfile"

gather_log "Fetching node description."
"$KUBECTL" get nodes -o wide >"$cluster_outdir/nodes.txt" 2>>"$outfile"

gather_log "Listing namespaces."
"$KUBECTL" get ns >"$cluster_outdir/namespaces.txt" 2>>"$outfile"

gather_log "Listing storage classes."
"$KUBECTL" get storageclass -o yaml >"$cluster_outdir/storageclasses.yaml" 2>>"$outfile"
