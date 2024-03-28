#!/usr/bin/env bash

set -o nounset


current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${current_dir}/constants.sh"
source "${current_dir}/utils.sh"

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

    # Check licensing service version
    local vls=$(get_licensing_service_version "")
    if [[ "$vls" != "${licensing_service_target_version}" ]]; then
        if [[ "$vls" == "unknown" ]]; then
            error "Cannot find licensing version in your cluster, is it installed?"
            exit 1
        else
            error "Detected licensing service version ${vls} which is not ${licensing_service_target_version}, please upgrade first pre-requisites with ads-upgrade-prereqs.sh script."
            exit 1
        fi
    else
        success "Detected licensing service version ${vls}."
    fi

    ## Check certificate manager
    local cert_manager_csv=$(kubectl get csv -n ${ads_namespace} | grep ibm-cert-manager-operator | cut -d ' ' -f1)
    if [[ -z ${cert_manager_csv} ]]; then
        info "Not using IBM cert manager."
    else
        vcm=${cert_manager_csv: -5}
        if [[ "$vcm" == "${cert_manager_target_version}" ]]; then
            success "Detected IBM certificate manager v${cert_manager_target_version}."
        else
            error "Detected IBM certificate manager version ${vcm} wich is not ${cert_manager_target_version}. Please upgrade first pre-requisites with ads-upgrade-prereqs.sh script."
            exit 1
        fi
    fi

    # Check Common services version
    local vcs=$(get_common_service_version ${ads_namespace})
    local truncated_vcs=${vcs:0:3}
    if [[ "${truncated_vcs}" != "4.4" && "${truncated_vcs}" != "4.2"  ]]; then
        if [[ "$vcs" == "unknown" ]]; then
            error "Cannot find common services version in namespace ${ads_namespace}, is ADS installed in this namespace?"
            exit 1
        else
            error "Detected common services version ${vcs} in namespace ${ads_namespace} which is neither 4.2 nor 4.4, are you upgrading from a 23.0.2 version?"
            exit 1
        fi
    else
        success "Detected common services version ${vcs}."
    fi
}

function check_subscription() {
    local channel=$(kubectl get sub ibm-ads-${ads_channel} -n ${ads_namespace} -o jsonpath='{.spec.channel}')
    if [ "${channel}" = "${ads_channel}" ]; then
        info "Found ADS subscription to the expected channel."
    else
        error "Cannot find ADS subscription in namespace ${ads_namespace} or its channel is not ${ads_channel}. Are you upgrading for an ifix with same ADS major version?"
        exit 1
    fi
}

function upgrade_to_ifix() {
    check_prereqs
    check_subscription
    create_ads_catalog_sources
    upgrade_ads_subscription ${ads_channel} ${ads_channel}  # Keep same channel
}

# --- Run ---
upgrade_to_ifix