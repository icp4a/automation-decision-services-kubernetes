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
    if [[ "$vls" == "unknown" ]]; then
        error "Cannot find licensing version in your cluster. Please use ads-install-prereqs.sh script to install it."
        exit 1
    elif [[ $(semver_compare ${vls} ${licensing_service_target_version}) == "-1" ]]; then
        error "Detected licensing service version ${vls} which is not ${licensing_service_target_version}. Please upgrade pre-requisites with ads-upgrade-prereqs.sh script."
        exit 1
    else
       success "Licensing service v${vls} found."
    fi

    ## Check certificate manager
    local vcm=$(get_cert_manager_version ${ads_namespace})
    if [[ "$vcm" == "unknown" ]]; then
        info "Not using IBM cert manager."
    elif [[ $(semver_compare ${vcm} ${cert_manager_target_version}) == "-1" ]]; then
        error "Detected IBM certificate manager version ${vcm} which is not greater or equals to version ${cert_manager_target_version}. Please upgrade pre-requisites with ads-upgrade-prereqs.sh script."
        exit 1
    else
        success "IBM certificate manager ${vcm} found."
    fi

    # Check Common services version
    local vcs=$(get_common_service_version ${ads_namespace})
    if [[ "$vcs" == "unknown" ]]; then
        error "Cannot find common services version in namespace ${ads_namespace}, is ADS installed in this namespace?"
        exit 1
    elif [[ $(semver_compare ${vcs} ${cs_minimal_version_for_upgrade}) == "-1" ]]; then
        error "Detected common services version ${vcs} in namespace ${ads_namespace} which is not greater or equals to version ${cs_minimal_version_for_upgrade}, are you upgrading from a ${ads_channel_previous_version} version?"
        exit 1
    elif [[ $(semver_compare ${vcs} ${cs_maximal_version_for_upgrade}) != "-1" ]]; then
        error "Detected common services version ${vcs} in namespace ${ads_namespace} which is not lower to version ${cs_maximal_version_for_upgrade}, are you upgrading from a ${ads_channel_previous_version} version?"
        exit 1
    else
        success "Detected common services version ${vcs}."
    fi
}

function check_subscription() {
    local channel=$(kubectl get sub ibm-ads-${ads_channel_previous_version} -n ${ads_namespace} -o jsonpath='{.spec.channel}')
    if [ "${channel}" = "${ads_channel_previous_version}" ]; then
        info "Found ADS subscription to the expected channel."
    else
        error "Cannot find ADS subscription in namespace ${ads_namespace} or its channel is not ${ads_channel_previous_version}. Are you upgrading from a ${ads_channel_previous_version} version?"
        exit 1
    fi
}


function upgrade {
    check_prereqs
    check_subscription
    create_ads_catalog_sources
    upgrade_ads_subscription ${ads_channel_previous_version} ${ads_channel}
}

# --- Run ---
upgrade
