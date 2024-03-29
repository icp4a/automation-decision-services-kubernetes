#!/usr/bin/env bash

function msg() {
    printf '%b\n' "$1"
}

function info() {
    msg "[INFO] ${1}"
}

function success() {
    msg "\33[32m[✔] ${1}\33[0m"
}

function warning() {
    msg "\33[33m[✗] ${1}\33[0m"
}

function error() {
    msg "\33[31m[✘] ${1}\33[0m"
}

function title() {
    msg "\33[34m# ${1}\33[0m"
}


function check_command() {
    local command=$1

    if [[ -z "$(command -v ${command} 2> /dev/null)" ]]; then
        error "${command} command not available"
    else
        success "${command} command available"
    fi
}

function check_return_code() {
    local rc=$1
    local error_message=$2

    if [ "${rc}" -ne 0 ]; then
        error "${error_message}"
    else
        return 0
    fi
}

function wait_for_condition() {
    local condition=$1
    local retries=$2
    local sleep_time=$3
    local wait_message=$4
    local success_message=$5
    local error_message=$6

    info "${wait_message}"
    while true; do
        result=$(eval "${condition}")

        if [[ ( ${retries} -eq 0 ) && ( -z "${result}" ) ]]; then
            error "${error_message}"
            exit 2
        fi

        sleep ${sleep_time}
        result=$(eval "${condition}")

        if [[ -z "${result}" ]]; then
            info "RETRYING: ${wait_message} (${retries} left)"
            retries=$(( retries - 1 ))
        else
            break
        fi
    done

    if [[ ! -z "${success_message}" ]]; then
        success "${success_message}"
    fi
}

function wait_for_configmap() {
    local namespace=$1
    local name=$2
    local condition="kubectl -n ${namespace} get cm --no-headers --ignore-not-found | grep ^${name}"
    local retries=12
    local sleep_time=10
    local total_time_mins=$(( sleep_time * retries / 60))
    local wait_message="Waiting for ConfigMap ${name} in namespace ${namespace} to be made available"
    local success_message="ConfigMap ${name} in namespace ${namespace} is available"
    local error_message="Timeout after ${total_time_mins} minutes waiting for ConfigMap ${name} in namespace ${namespace} to become available"

    wait_for_condition "${condition}" ${retries} ${sleep_time} "${wait_message}" "${success_message}" "${error_message}"
}

function wait_for_pod() {
    local namespace=$1
    local name=$2
    local condition="kubectl -n ${namespace} get po --no-headers --ignore-not-found | grep -E 'Running|Completed|Succeeded' | grep ^${name}"
    local retries=30
    local sleep_time=30
    local total_time_mins=$(( sleep_time * retries / 60))
    local wait_message="Waiting for pod ${name} in namespace ${namespace} to be running"
    local success_message="Pod ${name} in namespace ${namespace} is running"
    local error_message="Timeout after ${total_time_mins} minutes waiting for pod ${name} in namespace ${namespace} to be running"

    wait_for_condition "${condition}" ${retries} ${sleep_time} "${wait_message}" "${success_message}" "${error_message}"
}

function wait_for_operator() {
    local namespace=$1
    local operator_name=$2
    local condition="kubectl -n ${namespace} get csv --no-headers --ignore-not-found | grep -E 'Succeeded' | grep ^${operator_name}"
    local retries=50
    local sleep_time=10
    local total_time_mins=$(( sleep_time * retries / 60))
    local wait_message="Waiting for operator ${operator_name} in namespace ${namespace} to be made available"
    local success_message="Operator ${operator_name} in namespace ${namespace} is available"
    local error_message="Timeout after ${total_time_mins} minutes waiting for ${operator_name} in namespace ${namespace} to become available"

    wait_for_condition "${condition}" ${retries} ${sleep_time} "${wait_message}" "${success_message}" "${error_message}"
}

function wait_for_service_account() {
    local namespace=$1
    local name=$2
    local condition="kubectl -n ${namespace} get sa ${name} --no-headers --ignore-not-found"
    local retries=20
    local sleep_time=10
    local total_time_mins=$(( sleep_time * retries / 60))
    local wait_message="Waiting for service account ${name} to be created"
    local success_message="Service account ${name} is created"
    local error_message="Timeout after ${total_time_mins} minutes waiting for service account ${name} to be created"

    wait_for_condition "${condition}" ${retries} ${sleep_time} "${wait_message}" "${success_message}" "${error_message}"
}

function create_catalog_source() {
    local name=$1
    local displayName=$2
    local image=$3
    local olm_namespace=$4
    local is_openshift=$5

    title "Creating catalog source ${name}..."
    kubectl -n ${olm_namespace} delete catalogsource ${name} --ignore-not-found

    if ${is_openshift}; then # No grpcPodConfig
    kubectl apply -f - << EOF
  apiVersion: operators.coreos.com/v1alpha1
  kind: CatalogSource
  metadata:
    name: ${name}
    namespace: "${olm_namespace}"
    annotations:
      bedrock_catalogsource_priority: '1'
  spec:
    displayName: ${displayName}
    publisher: IBM
    sourceType: grpc
    image: ${image}
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
    name: ${name}
    namespace: "${olm_namespace}"
    annotations:
      bedrock_catalogsource_priority: '1'
  spec:
    displayName: ${displayName}
    publisher: IBM
    sourceType: grpc
    grpcPodConfig:
      securityContextConfig: restricted
    image: ${image}
    updateStrategy:
      registryPoll:
        interval: 45m
    priority: 100
EOF
    fi
    if [[ $? -ne 0 ]]; then
          error "Error creating catalog source ${name}."
    fi
    wait_for_pod "${olm_namespace}" "${name}"
}


function create_namespace() {
    local namespace=$1

    ns=$(kubectl get ns ${namespace} -o=jsonpath={.metadata.name} 2>/dev/null)
    if [[ -z ${ns} ]]; then
      info "Creating namespace ${namespace}"
      kubectl create namespace ${namespace}
    fi
}

function is_sub_exist() {
    local package_name=$1
    if [ $# -eq 2 ]; then
        local namespace=$2
        local name=$(kuebctl get subscription.operators.coreos.com -n ${namespace} -o yaml -o jsonpath='{.items[*].spec.name}')
    else
        local name=$(kubectl get subscription.operators.coreos.com -A -o yaml -o jsonpath='{.items[*].spec.name}')
    fi
    is_exist=$(echo "$name" | grep -w "$package_name")
}

function create_ads_subscription() {
    local channel=$1
    local namespace=$2

    title "Creating ADS subscription ..."
    kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-ads-${channel}
  namespace: "${namespace}"
spec:
  channel: ${channel}
  installPlanApproval: Automatic
  name: ibm-ads-kn-operator
  source: ibm-ads-operator-catalog
  sourceNamespace: "${namespace}"
EOF
    if [[ $? -ne 0 ]]; then
        error "ADS Operator subscription could not be created."
    fi

    info "Waiting for ADS subscription to become active."

    wait_for_operator "${namespace}" "ibm-ads-kn-operator"
    wait_for_operator "${namespace}" "ibm-common-service-operator"
    wait_for_operator "${namespace}" "operand-deployment-lifecycle-manager"
}

function create_ads_catalog_sources() {
  title "Creating catalog sources ..."
  create_catalog_source opencloud-operators "IBMCS Operators" ${cs_catalog_image} "${ads_namespace}" ${is_openshift}
  create_catalog_source cloud-native-postgresql-catalog "Cloud Native Postgresql Catalog" ${edb_catalog_image} "${ads_namespace}" ${is_openshift}
  create_catalog_source ibm-ads-operator-catalog "ibm-ads-operator-${ads_channel}" ${ads_catalog_image} "${ads_namespace}" ${is_openshift}
}

function create_licensing_service_subscription() {
  local namespace=$1
  local olm_namespace=$2
  local channel=$3

  kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-licensing-operator-app
  namespace: "${namespace}"
spec:
  channel: ${channel}
  installPlanApproval: Automatic
  name: ibm-licensing-operator-app
  source: ibm-licensing-catalog
  sourceNamespace: "${olm_namespace}"
EOF

  if [[ $? -ne 0 ]]; then
    error "Error creating ibm-licensing subscription."
  fi

  info "Waiting for ibm-licensing subscription to become active."
  wait_for_operator ${namespace} ibm-licensing-operator
}


function create_ibm_certificate_manager_subscription() {
  local olm_namespace=$1
  local channel=$2

  kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-cert-manager-operator
  namespace: ibm-cert-manager
spec:
  channel: ${channel}
  installPlanApproval: Automatic
  name: ibm-cert-manager-operator
  source: ibm-cert-manager-catalog
  sourceNamespace: "${olm_namespace}"
EOF
  if [[ $? -ne 0 ]]; then
      error "Error creating ibm-cert-manager subscription."
  fi

  info "Waiting for ibm-cert-manager subscription to become active."
  wait_for_operator ibm-cert-manager ibm-cert-manager-operator
}

function get_licensing_service_version() {
  local namespace=$1
  get_type_from_label "csv" "app.kubernetes.io/name=ibm-licensing" "{.items[0].spec.version}" "${namespace}"
}

function get_common_service_version() {
  local namespace=$1
  get_type_from_label "csv" "operators.coreos.com/ibm-common-service-operator.${namespace}" "{.items[0].spec.version}" "${namespace}"
}

function get_type_from_label() {
  local type=$1
  local label=$2
  local path=$3
  local namespace=$4
  local namespace_opt="-A"

  if [[ ! -z "$namespace" ]]; then
    namespace_opt="-n ${namespace}"
  fi

  kubectl get "${type}" ${namespace_opt} -l "${label}" -o jsonpath="${path}" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo $(kubectl get "${type}" ${namespace_opt} -l "${label}" -o jsonpath="${path}")
  else
    echo "unknown"
  fi
}

function upgrade_ads_subscription() {
    local old_channel=$1
    local new_channel=$2
    
    local sub=$(kubectl get sub ibm-ads-${old_channel} -n "${ads_namespace}" -o jsonpath='{.metadata.name}')
    kubectl delete sub ${sub} -n "${ads_namespace}"

    sub=$(kubectl get sub -n "${ads_namespace}" | grep ibm-common-service-operator | cut -d ' ' -f 1)
    kubectl delete sub ${sub} -n "${ads_namespace}"

    sub=$(kubectl get sub -n "${ads_namespace}" | grep operand-deployment-lifecycle-manager | cut -d ' ' -f 1)
    kubectl delete sub ${sub} -n "${ads_namespace}"
    
    local csv=$(kubectl get csv -n "${ads_namespace}" | grep ibm-ads-kn-operator.${old_channel} | cut -d ' ' -f 1)
    kubectl delete csv ${csv} -n "${ads_namespace}"

    csv=$(kubectl get csv -n "${ads_namespace}" | grep ibm-common-service-operator | cut -d ' ' -f 1)
    kubectl delete csv ${csv} -n "${ads_namespace}"

    csv=$(kubectl get csv -n "${ads_namespace}" | grep operand-deployment-lifecycle-manager | cut -d ' ' -f 1)
    kubectl delete csv ${csv} -n "${ads_namespace}"

    create_ads_subscription ${new_channel} "${ads_namespace}"
}
