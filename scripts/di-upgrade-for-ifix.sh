#!/usr/bin/env bash

set -o nounset


current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${current_dir}/constants.sh"
source "${current_dir}/utils.sh"

function show_help() {
    echo "Usage: $0 [-h] -n <di-namespace>"
    echo "  -n <di-namespace>    Namespace where DI CMS is installed"
}

di_namespace=""
is_openshift=false

while getopts "h?n:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    n)  di_namespace=$OPTARG
        ;;
    esac
done

if [[ -z ${di_namespace} ]]; then
    error "DI CMS namespace is mandatory."
    show_help
    exit 1
fi

function check_prereqs() {
    title "Checking prereqs ..."
    check_command kubectl

    oc_version=$(kubectl get clusterversion version -o=jsonpath='{.status.desired.version}' 2>/dev/null)
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

    # Check if licensing service version is the one we target
    local vls
    vls=$(get_licensing_service_version "")
    if [[ "$vls" == "unknown" ]]; then
        error "Cannot find licensing version in your cluster. Please use ads-install-prereqs.sh script to install it."
        exit 1
    elif [[ $(semver_compare "${vls}" "${licensing_service_target_version}") == "-1" ]]; then
        error "Detected licensing service version ${vls} which is not ${licensing_service_target_version}. Please upgrade pre-requisites with ads-upgrade-prereqs.sh script."
        exit 1
    else
       success "Licensing service v${vls} found."
    fi

    ## Check certificate manager
    init_cert_manager_properties
    local csv_name
    csv_name=$(get_cert_manager_csv_name)
    if [[ "$csv_name" == "unknown" ]]; then
      info "Unknown certificate manager."
    else
      success "Detected certificate manager from CSV ${csv_name}."
    fi

    # Check Common services version
    local vcs
    vcs=$(get_common_service_version "${di_namespace}")
    if [[ "$vcs" == "unknown" ]]; then
        error "Cannot find common services version in namespace ${di_namespace}, is DI CMS installed in this namespace?"
        exit 1
    elif [[ $(semver_compare "${vcs}" "${cs_minimal_version_for_ifix}") == "-1" ]]; then
        error "Detected common services version ${vcs} in namespace ${di_namespace} which is not greater or equals to version ${cs_minimal_version_for_ifix}, are you upgrading from a 24.0.0 version?"
        exit 1
    elif [[ $(semver_compare "${vcs}" "${cs_maximal_version_for_ifix}") != "-1" ]]; then
        error "Detected common services version ${vcs} in namespace ${di_namespace} which is not lower to version ${cs_maximal_version_for_ifix}, are you upgrading from a 24.0.0 version?"
        exit 1
    else
        success "Detected common services version ${vcs}."
    fi
}

function check_subscription() {
    local channel
    channel=$(kubectl get sub ibm-ads-"${ads_channel}" -n "${di_namespace}" -o jsonpath='{.spec.channel}')
    if [ "${channel}" = "${ads_channel}" ]; then
        info "Found ADS subscription to the expected channel."
    else
        error "Cannot find ADS subscription in namespace ${di_namespace} or its channel is not ${ads_channel}. Are you upgrading for an ifix of the same DI CMS version?"
        exit 1
    fi
}

function upgrade_to_ifix() {
    check_prereqs
    check_subscription
    create_ads_catalog_sources "${di_namespace}"
    create_ums_subscription "${ums_channel}" "${di_namespace}"
    upgrade_ads_subscription "${di_namespace}" "${ads_channel}" "${ads_channel}" # keep same channel
}

# --- Run ---
upgrade_to_ifix