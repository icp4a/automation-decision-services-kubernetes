#!/bin/bash

di_namespace="di"
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
        di_namespace=${OPTARG}
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

gather_log "Gathering details from namespace '$di_namespace'"
gather_log ""

##########################

get_all_k8s_resource catalogsource "$di_namespace"
get_all_k8s_resource subscription "$di_namespace"
get_all_k8s_resource csv "$di_namespace"
get_all_k8s_resource installplan "$di_namespace"
get_all_k8s_resource operandrequest "$di_namespace"

get_all_k8s_resource configmap "$di_namespace"
get_all_k8s_resource secret "$di_namespace"
get_all_k8s_resource pvc "$di_namespace"

get_all_k8s_resource ads "$di_namespace"
get_all_k8s_resource zenservice "$di_namespace"
get_all_k8s_resource zenextension "$di_namespace"
get_all_k8s_resource authentication.operator.ibm.com "$di_namespace"

get_all_k8s_resource cluster.postgresql.k8s.enterprisedb.io "$di_namespace"
get_all_k8s_resource cluster.pg.ibm.com "$di_namespace"

get_all_k8s_resource svc "$di_namespace"
get_all_k8s_resource endpoints "$di_namespace"
get_all_k8s_resource networkpolicy "$di_namespace"

get_all_k8s_resource deployment "$di_namespace"
get_all_k8s_resource sts "$di_namespace"
get_all_k8s_resource daemonset "$di_namespace"
get_all_k8s_resource cronjob "$di_namespace"
get_all_k8s_resource job "$di_namespace"

get_all_k8s_resource pod "$di_namespace"
get_all_pod_logs "$di_namespace"

get_all_k8s_resource ingress "$di_namespace"
get_all_k8s_resource gateway "$di_namespace"
get_all_k8s_resource GatewayClass "$di_namespace"
get_all_k8s_resource BackendTLSPolicy "$di_namespace"
get_all_k8s_resource HTTPRoute "$di_namespace"

get_all_k8s_resource pdb "$di_namespace"
get_all_k8s_resource hpa "$di_namespace"
get_all_k8s_resource resourcequota "$di_namespace"
get_all_k8s_resource event "$di_namespace"

get_all_k8s_resource certificates.cert-manager.io "$di_namespace"
get_all_k8s_resource issuers.cert-manager.io "$di_namespace"
get_all_k8s_resource challenges.acme.cert-manager.io "$di_namespace"
get_all_k8s_resource orders.acme.cert-manager.io "$di_namespace"
