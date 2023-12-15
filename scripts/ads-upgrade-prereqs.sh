#!/usr/bin/env bash

set -o nounset


current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${current_dir}/constants.sh
source ${current_dir}/utils.sh

function show_help() {
    echo "Usage: $0 [-h] [-n <licensing-namespace>]"
    echo "  -n       Namespace where the licensing operator is installed. Default is ibm-licensing"
}

licensing_namespace="ibm-licensing"
is_openshift=false
is_ibm_cert_manager=false

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

    ## Check Licensing service
    local licensing_csv=$(kubectl get csv -n ${licensing_namespace} ibm-licensing-operator.${common_services_previous_version})
    if [[ -z ${licensing_csv} ]]; then
      error "Cannot find a licensing service insallation in ${licensing_namespace}."
      exit 1
    fi
    success "Licensing service version ${common_services_previous_version} found in ${licensing_namespace}."

    ## Check Certificate manager
    local cert_manager_csv=$(kubectl get csv -n ${licensing_namespace} ibm-cert-manager-operator.${common_services_previous_version}) # available in all namespaces, so also in ibm-licensing one.
    if [[ -z ${cert_manager_csv} ]]; then
      is_ibm_cert_manager=false
      info "IBM certificate manager is not used, it will not be upgraded."
    else
      is_ibm_cert_manager=true
      success "IBM certificate manager version ${common_services_previous_version} found."
    fi
}

function check_subscription() {
    local channel=$(kubectl get sub ibm-licensing-operator-app -n ${licensing_namespace} -o jsonpath='{.spec.channel}')
    if [ "${channel}" = "${common_services_previous_version:0:4}" ]; then
        info "Found licensing service subscription to the expected channel."
    else
        error "Cannot find licensing service subscription in namespace ${licensing_namespace} or its channel is not ${common_services_previous_version:0:4}. Are you upgrading from previous version?"
        exit 1
    fi

    if ${is_ibm_cert_manager}; then
        local cert_manager_sub_namespace=$(kubectl get sub -A | grep ibm-cert-manager-operator | cut -d " " -f1)
        channel=$(kubectl get sub ibm-cert-manager-operator -n ${cert_manager_sub_namespace} -o jsonpath='{.spec.channel}')
        if [ "${channel}" = "${common_services_previous_version:0:4}" ]; then
            info "Found IBM certificate manager subscription to the expected channel."
        else
            error "Cannot find IBM certificate manager subscription in namespace ${cert_manager_sub_namespace} or its channel is not ${common_services_previous_version:0:4}. Are you upgrading from previous version?"
            exit 1
        fi
    fi
}

function upgrade_pre_req_catalog_sources() {
  title "Creating pre-req catalog sources ..."
  create_catalog_source ibm-licensing-catalog ibm-licensing-${common_services_channel} ${licensing_catalog_image} ${olm_namespace} ${is_openshift}
  if ${is_ibm_cert_manager}; then
    create_catalog_source ibm-cert-manager-catalog ibm-cert-manager-${common_services_channel} ${cert_manager_catalog_image} ${olm_namespace} ${is_openshift}
  fi
}


function upgrade_subscription() {
    local sub=$(kubectl get sub ibm-licensing-operator-app -n ${licensing_namespace} -o jsonpath='{.metadata.name}')
    kubectl delete sub ${sub} -n ${licensing_namespace}

    local csv=$(kubectl get csv -n ${licensing_namespace} | grep ibm-licensing-operator.${common_services_previous_version} | cut -d ' ' -f 1)
    kubectl delete csv ${csv} -n ${licensing_namespace}

    create_licensing_service_subscription ${licensing_namespace} ${olm_namespace} ${common_services_channel}

    if ${is_ibm_cert_manager}; then
        local cert_manager_sub_namespace=$(kubectl get sub -A | grep ibm-cert-manager-operator | cut -d " " -f1)
        sub=$(kubectl get sub ibm-cert-manager-operator -n ${cert_manager_sub_namespace} -o jsonpath='{.metadata.name}')
        kubectl delete sub ${sub} -n ${cert_manager_sub_namespace}

        csv=$(kubectl get csv -n ${cert_manager_sub_namespace} | grep ibm-cert-manager-operator.${common_services_previous_version} | cut -d ' ' -f 1)
        kubectl delete csv ${csv} -n ${cert_manager_sub_namespace}

        create_ibm_certificate_manager_subscription ${olm_namespace} ${common_services_channel} 
    fi
}


function upgrade {
    check_prereqs
    check_subscription
    upgrade_pre_req_catalog_sources
    upgrade_subscription 
}

# --- Run ---
upgrade
