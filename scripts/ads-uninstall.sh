#!/usr/bin/env bash

set -o nounset

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${current_dir}/utils.sh

function show_help() {
    echo "Usage: $0 [-h] -n <ads-namespace>"
    echo "  -n <ads-namespace>    Namespace from where ADS will be uninstalled"
    echo "  -f                    force flag to also delete common service config map and catalog sources"
}

ads_namespace=""
force_delete=false
is_openshift=false

while getopts "h?n:f" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    n)  ads_namespace=$OPTARG
        ;;
    f)  force_delete=true
        ;;
    esac
done

if [[ -z ${ads_namespace} ]]; then
    error "ADS namespace is mandatory"
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
        error "Cannot find OLM installation."
        exit 1
      fi
      success "OLM available under namespace ${olm_namespace}."
    fi
}

function delete_ads_cr {
  title "Deleting ADS CR ..."
  kubectl -n ${ads_namespace} get ads -o name --ignore-not-found | xargs -I {} kubectl -n ${ads_namespace} delete {} --timeout=45s
  success "Done"
}

function delete_ads_namespace {
  title "Deleting ADS namespace ..."
  ns=$(kubectl get ns ${ads_namespace} -o=jsonpath={.metadata.name} 2>/dev/null)
  if [[ -z ${ns} ]]; then
    info "Namespace ${ads_namespace} does not exist."
  else
    kubectl delete namespace ${ads_namespace} --ignore-not-found --timeout=45s
    kubectl get -n ${ads_namespace} authentications example-authentication > /dev/null 2>&1 && kubectl patch -n ${ads_namespace} authentications example-authentication -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} clients zenclient-ads > /dev/null 2>&1 && kubectl patch -n ${ads_namespace} clients zenclient-ads -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} namespacescopes common-service > /dev/null 2>&1 && kubectl patch -n ${ads_namespace} namespacescopes common-service -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} namespacescopes nss-odlm-scope > /dev/null 2>&1 && kubectl patch -n ${ads_namespace} namespacescopes nss-odlm-scope -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} nginxingresses default > /dev/null 2>&1 && kubectl patch -n ${ads_namespace} nginxingresses default -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} oidcclientwatchers example-oidcclientwatcher > /dev/null 2>&1 && kubectl patch -n ${ads_namespace} oidcclientwatchers example-oidcclientwatcher -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} operandbindinfos ibm-iam-bindinfo > /dev/null 2>&1 && kubectl patch -n ${ads_namespace} operandbindinfos ibm-iam-bindinfo -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} operandbindinfos management-ingress > /dev/null 2>&1 && kubectl patch -n ${ads_namespace} operandbindinfos management-ingress -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} platformapis platform-api > /dev/null 2>&1 && kubectl patch -n ${ads_namespace} platformapis platform-api -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} policycontrollers policycontroller-deployment > /dev/null 2>&1 && kubectl patch -n ${ads_namespace} policycontrollers policycontroller-deployment -p '{"metadata":{"finalizers":null}}' --type=merge
  fi
  success "Done"
}

function delete_cs_config_map() {
  title "Deleting Common Services config maps ..."
  kubectl delete cm -n kube-public common-service-maps --ignore-not-found --timeout=10s
  success "Done"
}

function delete_catalog_source() {
  title "Deleting Catalog sources ..."
  kubectl -n ${olm_namespace} delete catalogsource opencloud-operators --ignore-not-found --timeout=10s
  kubectl -n ${olm_namespace} delete catalogsource ibm-ads-operator-catalog --ignore-not-found --timeout=10s
  success "Done"
}

function delete_operand_requests() {
  title "Deleting operand requests ..."

  if [[ ! -z "$(kubectl get crd | grep operandrequests)" ]]; then
    for request in $(kubectl -n ${ads_namespace} get operandrequests -o name); do
      info "Deleting ${request} ..."
      kubectl -n ${ads_namespace} delete ${request} --ignore-not-found --timeout=60s
    done

    for request in $(kubectl -n ${ads_namespace} get operandrequests -o name); do
      info "Force deleting ${request} ..."
      kubectl -n ${ads_namespace} patch ${request} --type="json" -p '[{"op": "remove", "path":"/metadata/finalizers"}]'
      kubectl -n ${ads_namespace} delete ${request} --ignore-not-found --timeout=10s
    done
  fi
  success "Done"
}

function uninstall() {
    check_prereqs
    delete_ads_cr
    delete_operand_requests
    delete_ads_namespace
    if ${force_delete}; then
      delete_cs_config_map
      delete_catalog_source
    fi
}

# --- Run ---
uninstall
