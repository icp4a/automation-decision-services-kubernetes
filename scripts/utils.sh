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
    local condition="kubectl -n ${namespace} get po --no-headers --ignore-not-found | egrep 'Running|Completed|Succeeded' | grep ^${name}"
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
    local condition="kubectl -n ${namespace} get csv --no-headers --ignore-not-found | egrep 'Succeeded' | grep ^${operator_name}"
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
    namespace: ${olm_namespace}
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
    namespace: ${olm_namespace}
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
    wait_for_pod ${olm_namespace} "${name}"
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
