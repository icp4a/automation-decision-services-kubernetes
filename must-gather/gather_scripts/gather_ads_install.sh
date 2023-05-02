#!/bin/bash

ads_namespace="ads"
since="0s"
output_dir=.
log_to_stdout=true

while getopts "hn:s:d:l" opt; do
    case $opt in
    h)
        usage
        exit 1
        ;;
    n)
        ads_namespace=${OPTARG}
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

gather_log "Gathering details from namespace '$ads_namespace'"
gather_log ""

##########################

get_k8s_resource configmap kube-public common-service-maps

get_all_k8s_resource subscription "$ads_namespace"
get_all_k8s_resource csv "$ads_namespace"
get_all_k8s_resource installplan "$ads_namespace"
get_all_k8s_resource operandrequest "$ads_namespace"

get_all_k8s_resource configmap "$ads_namespace"
get_all_k8s_resource secret "$ads_namespace"
get_all_k8s_resource pvc "$ads_namespace"

get_all_k8s_resource ads "$ads_namespace"
get_all_k8s_resource zenservice "$ads_namespace"

get_all_k8s_resource pod "$ads_namespace"
get_all_pod_logs "$ads_namespace"

get_all_k8s_resource ingress "$ads_namespace"
