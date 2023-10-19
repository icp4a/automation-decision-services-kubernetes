#!/usr/bin/env bash

set -o nounset


current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${current_dir}/constants.sh
source ${current_dir}/utils.sh

function show_help() {
    echo "Usage: $0 [-h] -n <ads-namespace>"
    echo "  -n <ads-namespace>    Namespace where ADS is installed"
}

ads_namespace=""
is_openshift=false

while getopts "h?n:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    n)  ads_namespace=$OPTARG
        ;;
    esac
done

if [[ -z ${ads_namespace} ]]; then
    error "ADS namespace is mandatory."
    show_help
    exit 1
fi

function check_prereqs() {
    title "Checking prereqs ..."
    check_command kubectl

    oc_version=$(kubectl get clusterversion version -o=jsonpath={.status.desired.version} 2>/dev/null)
    if [[ ! -z ${oc_version} ]]; then
      info "openshift version ${oc_version} detected."
      is_openshift=true
    fi

    ## Check OLM
    if ${is_openshift}; then
      olm_namespace="openshift-marketplace"
    else
      olm_namespace=$(kubectl get deployment -A | grep olm-operator | awk '{print $1}')
      if [[ -z "$olm_namespace" ]]; then
        error "Cannot find OLM installation. Are you targetting a cluster where ADS is installed?"
        exit 1
      fi
      success "OLM available under namespace ${olm_namespace}."
    fi
}

function check_subscription() {
    local channel=$(kubectl get sub ibm-ads-${ads_channel} -n ${ads_namespace} -o jsonpath='{.spec.channel}')
    if [ "${channel}" = "${ads_channel}" ]; then
        info "Found ADS subscription to the expected channel."
    else
        error "Cannot find ADS subscription in namespace ${ads_namespace} or its channel is not ${ads_channel}."
    fi
}

function upgrade_catalog_sources() {
    # For now, keep pinned CS 4.0 version
    # create_catalog_source "opencloud-operators-${common_services_channel}" "IBMCS Operators ${common_services_channel}" ${cs_catalog_image} ${olm_namespace} ${is_openshift}
    # create_catalog_source cloud-native-postgresql-catalog "Cloud Native Postgresql Catalog" ${edb_catalog_image} ${olm_namespace} ${is_openshift}
    create_catalog_source "ibm-ads-operator-catalog" "ibm-ads-operator-${ads_channel}" ${ads_catalog_image} ${ads_namespace} ${is_openshift}
}

function upgrade_subscription() {
    local sub=$(kubectl get sub ibm-ads-${ads_channel} -n ${ads_namespace} -o jsonpath='{.metadata.name}')
    kubectl delete sub ${sub}
    
    local csv=$(kubectl get csv | grep ibm-ads-kn-operator.${ads_channel} | cut -d ' ' -f 1)
    kubectl delete csv ${csv}

    create_ads_subscription ${ads_channel} ${ads_namespace}
}


function upgrade_to_ifix() {
    check_prereqs
    check_subscription
    upgrade_catalog_sources
    upgrade_subscription 
}

# --- Run ---
upgrade_to_ifix
