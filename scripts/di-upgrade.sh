#!/usr/bin/env bash

set -o nounset


current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${current_dir}/constants.sh"
source "${current_dir}/utils.sh"

function show_help() {
    echo "Usage: $0 [-h] -n <di-namespace>"
    echo "  -n <di-namespace>    Namespace where DI CMS is installed"
    echo "  -x                    Do not configure the created UMS instance to push usage metrics to IBM Software Central"
}

di_namespace=""
is_openshift=false
channel_found=""
push_to_swc=true

while getopts "h?n:x" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    n)  di_namespace=$OPTARG
        ;;
    x) push_to_swc=false
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
        error "Cannot find OLM installation. Are you targetting a cluster where DI CMS is installed?"
        exit 1
      fi
      success "OLM available under namespace ${olm_namespace}."
    fi

    # Check licensing service version
    local vls
    vls=$(get_licensing_service_version "")
    if [[ "$vls" == "unknown" ]]; then
        error "Cannot find licensing version in your cluster. Please use di-install-prereqs.sh script to install it."
        exit 1
    elif [[ $(semver_compare "${vls}" "${licensing_service_target_version}") == "-1" ]]; then
        error "Detected licensing service version ${vls} which is not ${licensing_service_target_version}. Please upgrade pre-requisites with di-upgrade-prereqs.sh script."
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
    elif [[ $(semver_compare "${vcs}" "${cs_minimal_version_for_upgrade}") == "-1" ]]; then
        error "Detected common services version ${vcs} in namespace ${di_namespace} which is not greater or equals to version ${cs_minimal_version_for_upgrade}, are you upgrading from ${ads_channel_previous_version} version(s)?"
        exit 1
    elif [[ $(semver_compare "${vcs}" "${cs_maximal_version_for_upgrade}") != "-1" ]]; then
        error "Detected common services version ${vcs} in namespace ${di_namespace} which is not lower to version ${cs_maximal_version_for_upgrade}, are you upgrading from ${ads_channel_previous_version} version(s)?"
        exit 1
    else
        success "Detected common services version ${vcs}."
    fi
}

function check_subscription() {
  local list=()
  IFS=',' read -ra list <<< "${ads_channel_previous_version}"
  local sub_found=false

  for item in "${list[@]}"; do
    local channel
    channel=$(kubectl get sub "ibm-ads-${item}" -n "${di_namespace}" -o jsonpath='{.spec.channel}' 2>/dev/null)
    if [ "${channel}" = "${item}" ]; then
      sub_found=true
      channel_found=${channel}
      break
    fi
  done

  if [[ "$sub_found" != "true" ]]; then
    error "Cannot find ADS subscription in namespace ${di_namespace} with an expected version. Are you upgrading from ${ads_channel_previous_version} version?"
    exit 1
  fi 
}


function upgrade {
    check_prereqs
    check_subscription "${ads_channel_previous_version}"
    upgrade_cs_config_map "${di_namespace}"
    create_ads_catalog_sources "$di_namespace"
    upgrade_ads_subscription "${di_namespace}" "${channel_found}" "${ads_channel}"
    create_ums_subscription "${ums_channel}" "${di_namespace}"
    create_ums_instance "${di_namespace}" "${push_to_swc}"
}

# --- Run ---
upgrade