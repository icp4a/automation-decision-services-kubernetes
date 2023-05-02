#!/bin/bash

olm_namespace="olm"
since="0s"
log_to_stdout=true
output_dir=.

while getopts "hn:s:d:l" opt; do
    case $opt in
    h)
        usage
        exit 1
        ;;
    n)
        olm_namespace=${OPTARG}
        ;;
    s)
        since=${OPTARG}
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

gather_log "Gathering details from namespace '$olm_namespace'"
gather_log ""

##########################

get_k8s_resource configmap kube-public common-service-maps

get_all_k8s_resource configmap "$olm_namespace"
get_all_k8s_resource secret "$olm_namespace"
get_all_k8s_resource pvc "$olm_namespace"

get_all_k8s_resource catalogsource "$olm_namespace"

get_all_k8s_resource pod "$olm_namespace"
get_all_pod_logs "$olm_namespace"
