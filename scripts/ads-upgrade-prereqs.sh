#!/usr/bin/env bash

set -o nounset


current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${current_dir}/constants.sh"
source "${current_dir}/utils.sh"

function show_help() {
    echo "Usage: $0 [-h] [-n <licensing-namespace>]"
    echo "  -n       Namespace where the licensing operator is installed. Default is ibm-licensing"
}

licensing_namespace="ibm-licensing"
is_openshift=false
upgrade_licensing_service=false
upgrade_cert_manager=false

while getopts "h?n:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    n)  licensing_namespace=$OPTARG
        ;;
    esac
done

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

    # Check if licensing service version is one we support to upgrade or if it is already the one we target.
    local vls=$(get_licensing_service_version ${licensing_namespace})
    if [[ "$vls" == "unknown" ]]; then
      error "Cannot find licensing version in your cluster, is it installed?"
      exit 1
    elif [[ $(semver_compare ${vls} ${licensing_service_minimal_version_for_upgrade}) == "-1" ]]; then
      error "Detected licensing service version ${vls} which is not greater or equals to version ${licensing_service_minimal_version_for_upgrade}. Cannot upgrade."
      exit 1
    elif [[ $(semver_compare ${vls} ${licensing_service_target_version}) == "-1" ]]; then
      success "Licensing service v${vls} found. Will upgrade it."
      upgrade_licensing_service=true
    else
      success "Licensing service is already version ${vls}, leave it untouched."
    fi

    ## Check Certificate manager
    local vcm=$(get_cert_manager_version ${licensing_namespace}) # available in all namespaces, so also in ibm-licensing one.
    if [[ "$vcm" == "unknown" ]]; then
      upgrade_cert_manager=false
      info "IBM certificate manager is not used, it will not be upgraded."
    elif [[ $(semver_compare ${vcm} ${cert_manager_minimal_version_for_upgrade}) == "-1" ]]; then
      error "Detected IBM certificate manager version ${vcm} which is not greater or equals to version ${cert_manager_minimal_version_for_upgrade}. Cannot upgrade."
      exit 1
    elif [[ $(semver_compare ${vcm} ${cert_manager_target_version}) == "-1" ]]; then
      success "IBM certificate manager version v${vcm} found. Will upgrade it."
      upgrade_cert_manager=true
    else
      success "IBM Certificate manager is already version ${vcm}, leave it untouched."
      upgrade_cert_manager=false
    fi
}

function upgrade_prereqs_catalog_sources() {
  if ${upgrade_licensing_service}; then
    title "Creating licensing service catalog sources..."
    create_catalog_source ibm-licensing-catalog ibm-licensing-${licensing_service_channel} ${licensing_catalog_image} ${olm_namespace} ${is_openshift}
  fi
  if ${upgrade_cert_manager}; then
    title "Creating IBM certificate manager catalog sources..."
    create_catalog_source ibm-cert-manager-catalog ibm-cert-manager-${cert_manager_channel} ${cert_manager_catalog_image} ${olm_namespace} ${is_openshift}
  fi
}


function upgrade_subscription_prereqs() {
    if ${upgrade_licensing_service}; then
      title "Ugrading licensing service..."
      local sub=$(kubectl get sub ibm-licensing-operator-app -n ${licensing_namespace} -o jsonpath='{.metadata.name}')
      kubectl delete sub ${sub} -n ${licensing_namespace}

      local csv=$(kubectl get csv -n ${licensing_namespace} | grep ibm-licensing-operator | cut -d ' ' -f 1)
      kubectl delete csv ${csv} -n ${licensing_namespace}

      create_licensing_service_subscription ${licensing_namespace} ${olm_namespace} ${licensing_service_channel}
    fi

    if ${upgrade_cert_manager}; then
        title "Ugrading certificate manager..."
        local cert_manager_sub_namespace=$(kubectl get sub -A | grep ibm-cert-manager-operator | cut -d ' ' -f 1)
        sub=$(kubectl get sub ibm-cert-manager-operator -n ${cert_manager_sub_namespace} -o jsonpath='{.metadata.name}')
        kubectl delete sub ${sub} -n ${cert_manager_sub_namespace}

        csv=$(kubectl get csv -n ${cert_manager_sub_namespace} | grep ibm-cert-manager-operator | cut -d ' ' -f 1)
        kubectl delete csv ${csv} -n ${cert_manager_sub_namespace}

        create_ibm_certificate_manager_subscription ${olm_namespace} ${cert_manager_channel} 
    fi
}


function upgrade {
    check_prereqs
    upgrade_prereqs_catalog_sources
    upgrade_subscription_prereqs 
}

# --- Run ---
upgrade
