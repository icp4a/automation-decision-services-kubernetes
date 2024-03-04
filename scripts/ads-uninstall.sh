#!/usr/bin/env bash

set -o nounset

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${current_dir}/utils.sh

function show_help() {
    echo "Usage: $0 [-h] -n <ads-namespace>"
    echo "  -n <ads-namespace>    Namespace from where ADS will be uninstalled"
}

ads_namespace=""
is_openshift=false

while getopts "h?n:f" opt; do
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
}

function delete_ads_cr {
  title "Deleting ADS CR ..."
  kubectl -n ${ads_namespace} get ads -o name --ignore-not-found | xargs -I {} kubectl -n "${ads_namespace}" delete {} --timeout=45s
  success "Done"
}

function delete_ads_namespace {
  title "Deleting ADS namespace ..."
  ns=$(kubectl get ns ${ads_namespace} -o=jsonpath={.metadata.name} 2>/dev/null)
  if [[ -z ${ns} ]]; then
    info "Namespace ${ads_namespace} does not exist."
  else
    kubectl delete namespace ${ads_namespace} --ignore-not-found --timeout=45s
    kubectl get -n ${ads_namespace} authentications.operator.ibm.com example-authentication > /dev/null 2>&1 && kubectl patch -n "${ads_namespace}" authentications.operator.ibm.com example-authentication -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} clients zenclient-ads > /dev/null 2>&1 && kubectl patch -n "${ads_namespace}" clients zenclient-ads -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} operandbindinfos ibm-iam-bindinfo > /dev/null 2>&1 && kubectl patch -n "${ads_namespace}" operandbindinfos ibm-iam-bindinfo -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n ${ads_namespace} operandbindinfos ibm-zen-bindinfo > /dev/null 2>&1 && kubectl patch -n "${ads_namespace}" operandbindinfos ibm-zen-bindinfo -p '{"metadata":{"finalizers":null}}' --type=merge
    for zx in $(kubectl -n "${ads_namespace}" get zenextensions -o name); do
      kubectl patch -n "${ads_namespace}" ${zx} -p '{"metadata":{"finalizers":null}}' --type=merge
    done
    for co in $(kubectl -n "${ads_namespace}" get client.oidc.security.ibm.com -o name); do
      kubectl patch -n "${ads_namespace}" ${co} -p '{"metadata":{"finalizers":null}}' --type=merge
    done

  fi
  success "Done"
}


function delete_operand_requests() {
  title "Deleting operand requests ..."

  if [[ ! -z "$(kubectl get crd | grep operandrequests)" ]]; then
    for request in $(kubectl -n "${ads_namespace}" get operandrequests -o name); do
      info "Deleting ${request} ..."
      kubectl -n "${ads_namespace}" delete ${request} --ignore-not-found --timeout=60s
    done

    for request in $(kubectl -n "${ads_namespace}" get operandrequests -o name); do
      info "Force deleting ${request} ..."
      kubectl -n "${ads_namespace}" patch ${request} --type="json" -p '[{"op": "remove", "path":"/metadata/finalizers"}]'
      kubectl -n "${ads_namespace}" delete ${request} --ignore-not-found --timeout=10s
    done
  fi
  success "Done"
}

function uninstall() {
    check_prereqs
    delete_ads_cr
    delete_operand_requests
    delete_ads_namespace
}

# --- Run ---
uninstall
