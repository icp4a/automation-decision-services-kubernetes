#!/usr/bin/env bash

set -o nounset

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${current_dir}/utils.sh"

function show_help() {
    echo "Usage: $0 [-h] -n <di-namespace>"
    echo "  -n <di-namespace>    Namespace from where DI CMS will be uninstalled"
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
    *)
        show_help
        exit 1
        ;;
    esac
done

if [[ -z ${di_namespace} ]]; then
    error "DI  CMS namespace is mandatory"
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
}

function delete_ads_cr {
  title "Deleting ADS CR ..."
  kubectl -n "${di_namespace}" get ads -o name --ignore-not-found | xargs -I {} kubectl -n "${di_namespace}" delete {} --timeout=45s
  success "Done"
}

function delete_di_namespace {
  title "Deleting DI CMS namespace ..."
  ns=$(kubectl get ns "${di_namespace}" -o=jsonpath='{.metadata.name}' 2>/dev/null)
  if [[ -z ${ns} ]]; then
    info "Namespace ${di_namespace} does not exist."
  else
    kubectl delete namespace "${di_namespace}" --ignore-not-found --timeout=45s
    kubectl get -n "${di_namespace}" authentications.operator.ibm.com example-authentication > /dev/null 2>&1 && kubectl patch -n "${di_namespace}" authentications.operator.ibm.com example-authentication -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n "${di_namespace}" clients zenclient-ads > /dev/null 2>&1 && kubectl patch -n "${di_namespace}" clients zenclient-ads -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n "${di_namespace}" operandbindinfos ibm-iam-bindinfo > /dev/null 2>&1 && kubectl patch -n "${di_namespace}" operandbindinfos ibm-iam-bindinfo -p '{"metadata":{"finalizers":null}}' --type=merge
    kubectl get -n "${di_namespace}" operandbindinfos ibm-zen-bindinfo > /dev/null 2>&1 && kubectl patch -n "${di_namespace}" operandbindinfos ibm-zen-bindinfo -p '{"metadata":{"finalizers":null}}' --type=merge
    for zx in $(kubectl -n "${di_namespace}" get zenextensions -o name); do
      kubectl patch -n "${di_namespace}" "${zx}" -p '{"metadata":{"finalizers":null}}' --type=merge
    done
    for co in $(kubectl -n "${di_namespace}" get client.oidc.security.ibm.com -o name); do
      kubectl patch -n "${di_namespace}" "${co}" -p '{"metadata":{"finalizers":null}}' --type=merge
    done

  fi
  success "Done"
}


function delete_operand_requests() {
  title "Deleting operand requests ..."

  if kubectl get crd | grep -q operandrequests; then
    for request in $(kubectl -n "${di_namespace}" get operandrequests -o name); do
      info "Deleting ${request} ..."
      kubectl -n "${di_namespace}" delete "${request}" --ignore-not-found --timeout=60s
    done

    for request in $(kubectl -n "${di_namespace}" get operandrequests -o name); do
      info "Force deleting ${request} ..."
      kubectl -n "${di_namespace}" patch "${request}" --type="json" -p '[{"op": "remove", "path":"/metadata/finalizers"}]'
      kubectl -n "${di_namespace}" delete "${request}" --ignore-not-found --timeout=10s
    done
  fi
  success "Done"
}

function uninstall() {
    check_prereqs
    delete_ads_cr
    delete_operand_requests
    delete_di_namespace
}

# --- Run ---
uninstall
