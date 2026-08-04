#!/usr/bin/env bash

set -o nounset

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${current_dir}/constants.sh"
source "${current_dir}/utils.sh"

function show_help() {
    echo "Usage: $0 [-h] [-a] -n <di-namespace> [-d <domain-name>]"
    echo "  -a                    Accept license"
    echo "  -n <di-namespace>    Namespace where DI CMS will be installed"
    echo "  -d <domain-name>      Domain name where DI CMS url will be available. Mandatory unless using openshift where it is ignored."
    echo "  -x                    Do not configure the created UMS instance to push usage metrics to IBM Software Central"
}

accept_license=false
di_namespace=""
domain_name=""
is_openshift=false
push_to_swc=true

while getopts "h?an:d:x" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    a)
        accept_license=true
        ;;
    n)  di_namespace=$OPTARG
        ;;
    d)  domain_name=$OPTARG
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

function create_cs_config_map() {
    title "Creating common services config map ..."

    ns=$(kubectl get ns "${di_namespace}" -o=jsonpath='{.metadata.name}' 2>/dev/null)
    if [[ -z ${ns} ]]; then
      info "Creating namespace ${di_namespace}"
      kubectl create namespace "${di_namespace}"
    fi

    kubectl -n "${di_namespace}" delete cm ibm-cpp-config --ignore-not-found

   if ${is_openshift}; then
     if ! kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ibm-cpp-config
  namespace: ${di_namespace}
data:
  commonwebui.standalone: "true"
EOF
     then
        error "Error creating ibm-cpp-config config map in ${di_namespace} namespace."
     fi
  else
    if ! kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ibm-cpp-config
  namespace: ${di_namespace}
  labels:
    operator.ibm.com/managedByCsOperator: "true"
data:
  kubernetes_cluster_type: cncf
  commonwebui.standalone: "true"
  domain_name: ${domain_name}
EOF
    then
        error "Error creating ibm-cpp-config config map in ${di_namespace} namespace."
    fi
  fi
}

function create_ads_operator_group() {
    existing_og_name=$(kubectl get operatorgroup -n "${di_namespace}" -o name | awk -F "/" '{print $NF}')
    if [[ ! -z ${existing_og_name} ]]; then
      info "operatorgroup '${existing_og_name}' detected in namespace '${di_namespace}'."
      
      add_target_namespace_to_operator_group "${di_namespace}" "${existing_og_name}" "${di_namespace}"

    else
      title "Creating operator group ..."
      # use namespace name as operatorgroup name
      if ! kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ${di_namespace}
  namespace: ${di_namespace}
spec:
  targetNamespaces:
  - ${di_namespace}
EOF
      then
          error "Error creating operator group."
      fi
    fi
}

function check_prereqs() {
    title "Checking prereqs ..."
    check_command kubectl

    oc_version=$(kubectl get clusterversion version -o=jsonpath='{.status.desired.version}' 2>/dev/null)
    if [[ ! -z ${oc_version} ]]; then
      info "openshift version ${oc_version} detected."
      is_openshift=true
    fi

    ## Check domain name presence
    if ! ${is_openshift}; then
      if [[ -z ${domain_name} ]]; then
          error "Domain name is mandatory, use -d command line switch."
          show_help
          exit 1
      fi
    else
      if [[ ! -z ${domain_name} ]]; then
          info "Ignoring domain ${domain_name} as openshift cluster is detected."
      fi
    fi

    ## Check OLM
    if ${is_openshift}; then
      olm_namespace="openshift-marketplace"
    else
      olm_namespace=$(kubectl get deployment -A | grep olm-operator | awk '{print $1}')
      if [[ -z "$olm_namespace" ]]; then
        error "Cannot find OLM installation. Use di-install-prereqs.sh to install one."
        exit 1
      fi
      success "OLM available under namespace ${olm_namespace}."
    fi

    ## Check license service
    title "Checking if licensing service is installed in the cluster ..."

    # Check if licensing service version is the one we target
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
    title "Checking if a certificate manager is installed in the cluster ..."
    if ! kubectl get crd | grep cert-manager; then
       error "No certificate manager detected, use di-install-prereqs.sh to install one."
       exit 1
    else
      init_cert_manager_properties
      local csv_name
      csv_name=$(get_cert_manager_csv_name)
      if [[ "$csv_name" == "unknown" ]]; then
        info "Unknown certificate manager."
      else
        success "Detected certificate manager from CSV ${csv_name}."
      fi
    fi
}

function check_license() {
  if ! ${accept_license}; then
    error "You have to accept the following license after reviewing it using the -a flag."
    cat "${current_dir}/../License.txt"
    printf "\n"
    exit 1
  fi
}

function install() {
    check_license
    check_prereqs
    create_cs_config_map
    create_ads_catalog_sources "${di_namespace}"
    create_ads_operator_group
    create_ums_subscription "${ums_channel}" "${di_namespace}"
    create_ads_subscription "${ads_channel}" "${di_namespace}"
    create_ums_instance "${di_namespace}" "${push_to_swc}"
}

# --- Run ---
install
