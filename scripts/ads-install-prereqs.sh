#!/usr/bin/env bash

set -o nounset

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${current_dir}/constants.sh
source ${current_dir}/utils.sh

function show_help() {
    echo "Usage: $0 [-h] -a [-n licensing-namespace]"
    echo "  -a       Accept integration license. See https://ibm.biz/integration-licenses for more details"
    echo "  -n       Namespace where the licensing operator will be installed. Default is ibm-licensing"
}

is_openshift=false
accept_license=false
existing_cert_manager=false
existing_licensing_service=false
licensing_namespace=ibm-licensing
while getopts "h?an:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    a)
        accept_license=true
        ;;
    n)  licensing_namespace=$OPTARG
        ;;
    esac
done

if ! ${accept_license}; then
  error "License not accepted. Rerun script with -a flag set. See https://ibm.biz/integration-licenses for more details"
  exit 1
fi

function create_pre_req_catalog_sources() {
  title "Creating pre-req catalog sources ..."
  if ! ${existing_cert_manager}; then
    create_catalog_source ibm-cert-manager-catalog ibm-cert-manager-${common_services_channel} ${cert_manager_catalog_image} ${olm_namespace} ${is_openshift}
  fi
  if ! ${existing_licensing_service}; then
    create_catalog_source ibm-licensing-catalog ibm-licensing-${common_services_channel} ${licensing_catalog_image} ${olm_namespace} ${is_openshift}
  fi
}

function create_operator_groups() {
  title "Creating operator groups if needed ..."

  if ! ${existing_cert_manager}; then
    create_namespace ibm-cert-manager
    kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ibm-cert-manager
  namespace: ibm-cert-manager
spec:
  upgradeStrategy: Default
EOF
    if [[ $? -ne 0 ]]; then
        error "Error creating ibm-cert-manager operator group."
    fi
  fi

  if ! ${existing_licensing_service}; then
    create_namespace ${licensing_namespace}
    kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ibm-licensing
  namespace: ${licensing_namespace}
spec:
  targetNamespaces:
  - ${licensing_namespace}
  upgradeStrategy: Default
EOF

    if [[ $? -ne 0 ]]; then
      error "Error creating ibm-licensing operator group."
    fi
  fi

}

function create_subscriptions() {
    title "Creating subscription if needed ..."

  if ! ${existing_cert_manager}; then
    create_ibm_certificate_manager_subscription ${olm_namespace} ${common_services_channel} 
  fi

  if ! ${existing_licensing_service}; then
    create_licensing_service_subscription ${licensing_namespace} ${olm_namespace} ${common_services_channel}
  fi
}

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
      info "OLM is installed by default on openshift clusters."
    else
      olm_namespace=$(kubectl get deployment -A | grep olm-operator | awk '{print $1}')
      if [[ -z "$olm_namespace" ]]; then
        info "Cannot find OLM installation. Installing one"
        curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.25.0/install.sh -o install.sh
        chmod +x install.sh
        ./install.sh v0.23.1
        olm_install_success=$?
        rm -f install.sh
        olm_namespace="olm"
          if [[ $olm_install_success -ne 0 ]]; then
            error "Error installing OLM."
            exit 1
          fi
      fi
      success "OLM available under namespace ${olm_namespace}."
    fi
}

function check_cert_manager() {
    title "Checking if a certificate manager is already installed in the cluster ..."
    kubectl get crd | grep cert-manager
    if [[ $? -ne 0 ]] ; then
       info "No certificate manager detected, will install one."
       existing_cert_manager=false
    else
       info "A certificate manager is already installed in this cluster, ADS will use it."
       existing_cert_manager=true
    fi
}

function check_licensing_service() {
    title "Checking if licensing service is already installed in the cluster ..."

    is_sub_exist "ibm-licensing-operator-app" # this will catch the packagenames of all ibm-licensing-operator-app
    if [ $? -eq 0 ]; then
        warning "There is an ibm-licensing-operator-app Subscription already. Skipping the installation."
        existing_licensing_service=true
    else
        info "There is no ibm-licensing-operator-app Subscription installed, will install one."
        existing_licensing_service=false
    fi
}

function install() {
    check_prereqs
    check_cert_manager
    check_licensing_service
    create_pre_req_catalog_sources
    create_operator_groups
    create_subscriptions
}

# --- Run ---
install
