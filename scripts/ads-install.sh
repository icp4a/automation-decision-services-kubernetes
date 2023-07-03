#!/usr/bin/env bash

set -o nounset

cs_catalog_image="icr.io/cpopen/ibm-common-service-catalog@sha256:cc3491ee7b448c3c8db43242d13e9d5d13a37ad9e67d166744d9b162887ed7e7"
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:6c010a6a0a8c4784c28dfb8415b1a5f400ea5e56f2bd6d89aa686aedccb92bd4"

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${current_dir}/utils.sh

function show_help() {
    echo "Usage: $0 [-h] [-a] -n <ads-namespace> [-d <domain-name>] [-f|-i]"
    echo "  -a                    Accept license"
    echo "  -n <ads-namespace>    Namespace where ADS will be installed"
    echo "  -d <domain-name>      Domain name where ADS url will be available. Mandatory unless using openshift."
    echo "  -f                    Force common-service-maps override if it already exists."
    echo "  -i                    Ignore common-service-maps. Mutually exclusive with -f option"
}

accept_license=false
ads_namespace=""
domain_name=""
force_cm=false
ignore_cm=false
is_openshift=false

while getopts "h?an:d:fi" opt; do
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
    f)  force_cm=true
        ;;
    i)  ignore_cm=true
        ;;
    esac
done

if [[ -z ${ads_namespace} ]]; then
    error "ADS namespace is mandatory."
    show_help
    exit 1
fi

if ${force_cm} && ${ignore_cm}; then
    error "-f and -i are mutually exclusive."
    show_help
    exit 1
fi

function apply_cs_cm() {
   kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
 name: common-service-maps
 namespace: kube-public
data:
 common-service-maps.yaml: |
   controlNamespace: cs-control
   namespaceMapping:
   - requested-from-namespace:
     - ${ads_namespace}
     map-to-common-service-namespace: ${ads_namespace}
EOF
  if [[ $? -ne 0 ]]; then
        error "Error creating common-service-maps config map in kube-public namespace."
  fi

}

function create_cs_config_maps() {
    title "Creating common services config maps ..."

    csm=$(kubectl -n kube-public get cm common-service-maps -o=jsonpath={.metadata.name} 2>/dev/null)
    if [[ ! -z ${csm} ]]; then # config map exists
      if ${force_cm}; then
        info "overriding common-service-maps"
        apply_cs_cm
      elif ${ignore_cm}; then
        info "ignoring common-service-maps"
      else
        error "common-service-maps already exists in kube-public namespace: it's not a fresh install, please review the documentation troubleshooting section."
        exit 1
      fi
    else # config map does not exist
      apply_cs_cm # create it
    fi

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


function create_catalog_source() {
  title "Creating catalog source ..."
  kubectl -n olm delete catalogsource opencloud-operators --ignore-not-found

  # IBM Cloud Foundational Services 3.23.1
  if ${is_openshift}; then # No grpcPodConfig
  kubectl apply -f - << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: opencloud-operators
  namespace: ${olm_namespace}
  annotations:
    bedrock_catalogsource_priority: '1'
spec:
  displayName: IBMCS Operators
  publisher: IBM
  sourceType: grpc
  image: ${cs_catalog_image}
  updateStrategy:
    registryPoll:
      interval: 45m
  priority: 100
EOF
  else
  # Adding grpcPodConfig
  kubectl apply -f - << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: opencloud-operators
  namespace: ${olm_namespace}
  annotations:
    bedrock_catalogsource_priority: '1'
spec:
  displayName: IBMCS Operators
  publisher: IBM
  sourceType: grpc
  grpcPodConfig:
    securityContextConfig: restricted
  image: ${cs_catalog_image}
  updateStrategy:
    registryPoll:
      interval: 45m
  priority: 100
EOF
  fi
  if [[ $? -ne 0 ]]; then
        error "Error creating common services catalog source."
  fi

  wait_for_pod ${olm_namespace} "opencloud-operators."

  # ADS nightly build
  if ${is_openshift}; then # No grpcPodConfig
  kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-ads-operator-catalog
  namespace: ${olm_namespace}
spec:
  displayName: ibm-ads-operator
  image: ${ads_catalog_image}
  publisher: IBM
  sourceType: grpc
  updateStrategy:
    registryPoll:
      interval: 45m
EOF
  else
  kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-ads-operator-catalog
  namespace: ${olm_namespace}
spec:
  displayName: ibm-ads-operator
  image: ${ads_catalog_image}
  publisher: IBM
  sourceType: grpc
  grpcPodConfig:
    securityContextConfig: restricted
  updateStrategy:
    registryPoll:
      interval: 45m
EOF
  fi
  if [[ $? -ne 0 ]]; then
        error "Error creating ADS catalog source."
  fi

  wait_for_pod ${olm_namespace} "ibm-ads-operator-catalog"
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
  name: ibm-ads-v22.2
  namespace: ${ads_namespace}
spec:
  channel: v22.2
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
        error "Cannot find OLM installation."
        exit 1
      fi
      success "OLM available under namespace ${olm_namespace}."
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
    create_cs_config_maps
    create_catalog_source
    create_operator_group
    create_subscription
}

# --- Run ---
install
