#!/usr/bin/env bash

set -o nounset

cs_catalog_image="icr.io/cpopen/ibm-common-service-catalog@sha256:baec9f6a7b1710b1bba7f72ccc792c17830e563a1f85b8fb7bdb57505cde378a" # IBM Cloud Foundational Services 4.0
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:4d753c6d20a2afb1db97e50ef80662c2ff64630880dd424116d79a62a86df37b" # 23.0.1-IF001
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:a06b9c054e58e089652f0e4400178c4a1b685255de9789b80fe5d5f526f9e732" # Cloud Native PostgresSQL 4.14.0+20230619 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cloud-native-postgresql/4.14.0%2B20230616.111503

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
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
  create_catalog_source opencloud-operators "IBMCS Operators" ${cs_catalog_image} ${olm_namespace} ${is_openshift}
  create_catalog_source cloud-native-postgresql-catalog "Cloud Native Postgresql Catalog" ${edb_catalog_image} ${olm_namespace} ${is_openshift}
  create_catalog_source ibm-ads-operator-catalog "ibm-ads-operator" ${ads_catalog_image} ${olm_namespace} ${is_openshift}
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

function create_subscription() {
    title "Creating subscription ..."
    kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-ads-v23.1
  namespace: ${ads_namespace}
spec:
  channel: v23.1
  installPlanApproval: Automatic
  name: ibm-ads-kn-operator
  source: ibm-ads-operator-catalog
  sourceNamespace: ${olm_namespace}
EOF
    if [[ $? -ne 0 ]]; then
        error "ADS Operator subscription could not be created."
    fi

    info "Waiting for ADS subscription to become active."

    wait_for_operator "${ads_namespace}" "ibm-ads-kn-operator"
    wait_for_operator "${ads_namespace}" "ibm-common-service-operator"
    wait_for_operator "${ads_namespace}" "operand-deployment-lifecycle-manager"
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
    create_subscription
}

# --- Run ---
install
