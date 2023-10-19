#!/usr/bin/env bash

set -o nounset

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${current_dir}/constants.sh
source ${current_dir}/utils.sh

function show_help() {
    echo "Usage: $0 [-h] [-a] -n <ads-namespace> [-d <domain-name>]"
    echo "  -a                    Accept license"
    echo "  -n <ads-namespace>    Namespace where ADS will be installed"
    echo "  -d <domain-name>      Domain name where ADS url will be available. Mandatory unless using openshift where it is ignored."
}

accept_license=false
ads_namespace=""
domain_name=""
is_openshift=false

while getopts "h?an:d:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    a)
        accept_license=true
        ;;
    n)  ads_namespace=$OPTARG
        ;;
    d)  domain_name=$OPTARG
        ;;
    esac
done

if [[ -z ${ads_namespace} ]]; then
    error "ADS namespace is mandatory."
    show_help
    exit 1
fi

function create_cs_config_map() {
    title "Creating common services config map ..."

    ns=$(kubectl get ns ${ads_namespace} -o=jsonpath={.metadata.name} 2>/dev/null)
    if [[ -z ${ns} ]]; then
      info "Creating namespace ${ads_namespace}"
      kubectl create namespace ${ads_namespace}
    fi

    kubectl -n ${ads_namespace} delete cm ibm-cpp-config --ignore-not-found

   if ${is_openshift}; then
     kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ibm-cpp-config
  namespace: ${ads_namespace}
data:
  commonwebui.standalone: "true"
EOF
  else
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ibm-cpp-config
  namespace: ${ads_namespace}
data:
  kubernetes_cluster_type: cncf
  commonwebui.standalone: "true"
  domain_name: ${domain_name}
EOF
  fi
  if [[ $? -ne 0 ]]; then
        error "Error creating ibm-cpp-config config map in ${ads_namespace} namespace."
  fi
}

function create_catalog_sources() {
  title "Creating catalog sources ..."
  create_catalog_source opencloud-operators "IBMCS Operators" ${cs_catalog_image} ${ads_namespace} ${is_openshift}
  create_catalog_source cloud-native-postgresql-catalog "Cloud Native Postgresql Catalog" ${edb_catalog_image} ${ads_namespace} ${is_openshift}
  create_catalog_source ibm-ads-operator-catalog "ibm-ads-operator-${ads_channel}" ${ads_catalog_image} ${ads_namespace} ${is_openshift}
}

function create_operator_group() {
    title "Creating operator group ..."
    kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ads
  namespace: ${ads_namespace}
spec:
  targetNamespaces:
  - ${ads_namespace}
EOF

  if [[ $? -ne 0 ]]; then
        error "Error creating operator group."
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
        error "Cannot find OLM installation. Use ads-install-prereqs.sh to install one."
        exit 1
      fi
      success "OLM available under namespace ${olm_namespace}."
    fi

    ## Check license service
    title "Checking if licensing service is installed in the cluster ..."

    is_sub_exist "ibm-licensing-operator-app" # this will catch the packagenames of all ibm-licensing-operator-app
    if [ $? -eq 0 ]; then
        info "ok"
    else
        error "No licensing service detected, use ads-install-prereqs.sh to install one."
        exit 1
    fi

    ## Check certificate manager
    title "Checking if a certificate manager is installed in the cluster ..."
    kubectl get crd | grep cert-manager
    if [[ $? -ne 0 ]] ; then
       error "No certificate manager detected, use ads-install-prereqs.sh to install one."
       exit 1
    else
       info "ok"
    fi
}

function check_license() {
  if ! ${accept_license}; then
    error "You have to accept the following license after reviewing it using the -a flag."
    cat ${current_dir}/../License.txt
    printf "\n"
    exit 1
  fi
}


function install() {
    check_license
    check_prereqs
    create_cs_config_map
    create_catalog_sources
    create_operator_group
    create_ads_subscription ${ads_channel} ${ads_namespace}
}

# --- Run ---
install
