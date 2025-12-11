#!/usr/bin/env bash

sed=${SED_CMD:-sed}

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

function create_ads_subscription() {
    local channel=$1
    local namespace=$2

    title "Creating ADS subscription ..."
    kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-ads-${channel}
  namespace: ${namespace}
spec:
  channel: ${channel}
  installPlanApproval: Automatic
  name: ibm-ads-kn-operator
  source: ibm-ads-operator-catalog
  sourceNamespace: ${namespace}
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

  # Only create common services catalog if installed version is lower than the version in catalog referenced by cs_catalog_image variable
  local vcs=$(get_common_service_version ${ads_namespace})
  if [[ "$vcs" == "unknown" || $(semver_compare ${vcs} ${common_services_version}) == "-1" ]]; then
      create_catalog_source opencloud-operators "IBMCS Operators" ${cs_catalog_image} ${ads_namespace} ${is_openshift}
      create_catalog_source cs-im-operators "IBMCS IM Operators" ${cs_im_catalog_image} ${ads_namespace} ${is_openshift}
      create_catalog_source cs-zen-operators "IBMCS Zen Operators" ${zen_catalog_image} ${ads_namespace} ${is_openshift}
  fi
  
  create_catalog_source cloud-native-postgresql-catalog "Cloud Native Postgresql Catalog" ${edb_catalog_image} ${ads_namespace} ${is_openshift}
  create_catalog_source ibm-ads-operator-catalog "ibm-ads-operator-${ads_channel}" ${ads_catalog_image} ${ads_namespace} ${is_openshift}
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
  namespace: ${namespace}
spec:
  channel: ${channel}
  installPlanApproval: Automatic
  name: ibm-licensing-operator-app
  source: ibm-licensing-catalog
  sourceNamespace: ${olm_namespace}
EOF

  if [[ $? -ne 0 ]]; then
    error "Error creating ibm-licensing subscription."
  fi

  info "Waiting for ibm-licensing subscription to become active."
  wait_for_operator ${namespace} ibm-licensing-operator
}

function init_cert_manager_properties () {
  if ${is_openshift}; then
    cert_manager_channel="${redhat_cert_manager_channel_on_ocp}"
    cert_manager_catalog_name="redhat-operators"
    cert_manager_operator_name="openshift-cert-manager-operator"
    cert_manager_operator_namespace="cert-manager-operator"
    cert_manager_csv_base_name="cert-manager-operator"
  else
    cert_manager_channel="${ibm_cert_manager_channel_on_cncf}"
    cert_manager_catalog_name="ibm-cert-manager-catalog"
    cert_manager_operator_name="ibm-cert-manager-operator"
    cert_manager_operator_namespace="ibm-cert-manager"
    cert_manager_csv_base_name="ibm-cert-manager-operator"
  fi
}

function create_certificate_manager_subscription() {
  local olm_namespace=$1

  kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cert-manager
  namespace: ${cert_manager_operator_namespace}
spec:
  channel: ${cert_manager_channel}
  installPlanApproval: Automatic
  name: ${cert_manager_operator_name}
  source: ${cert_manager_catalog_name}
  sourceNamespace: ${olm_namespace}
EOF
  if [[ $? -ne 0 ]]; then
      error "Error creating cert-manager subscription."
  fi

  info "Waiting for cert-manager subscription to become active."
  wait_for_operator ${cert_manager_operator_namespace} ${cert_manager_csv_base_name}
}

function get_licensing_service_version() {
  local namespace=$1
  get_type_from_label "csv" "app.kubernetes.io/name=ibm-licensing" "{.items[0].spec.version}" "${namespace}"
}

function get_cert_manager_csv_name() {
  local namespace=${cert_manager_operator_namespace}

  local path="{.spec.version}"

  local csv_name=$(kubectl get csv -n ${namespace} | grep "cert-manager-operator" | cut -d ' ' -f1)
  
  if [[ -z ${csv_name} ]]; then
      echo "unknown"
  else
    echo "${csv_name}"
  fi
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

    local sub=$(kubectl get sub ibm-ads-${old_channel} -n ${ads_namespace} -o jsonpath='{.metadata.name}')
    kubectl delete sub ${sub} -n ${ads_namespace}

    sub=$(kubectl get sub -n ${ads_namespace} | grep ibm-common-service-operator | cut -d ' ' -f 1)
    kubectl delete sub ${sub} -n ${ads_namespace}

    sub=$(kubectl get sub -n ${ads_namespace} | grep ibm-im-operator | cut -d ' ' -f 1)
    # Subscription name depends of common service version
    if [[ ! -z ${sub} ]]; then
      kubectl delete sub ${sub} -n ${ads_namespace}
    fi
    
    sub=$(kubectl get sub -n ${ads_namespace} | grep ibm-iam-operator | cut -d ' ' -f 1)
    # Subscription name depends of common service version
    if [[ ! -z ${sub} ]]; then
      kubectl delete sub ${sub} -n ${ads_namespace}
    fi

    sub=$(kubectl get sub -n ${ads_namespace} | grep ibm-idp-config-ui-operator | cut -d ' ' -f 1)
    # Subscription name depends of common service version
    if [[ ! -z ${sub} ]]; then
      kubectl delete sub ${sub} -n ${ads_namespace}
    fi

    sub=$(kubectl get sub -n ${ads_namespace} | grep ibm-commonui-operator-app | cut -d ' ' -f 1)
     # Subscription name depends of common service version
    if [[ ! -z ${sub} ]]; then
      kubectl delete sub ${sub} -n ${ads_namespace}
    fi

    sub=$(kubectl get sub -n ${ads_namespace} | grep ibm-platformui-operator | cut -d ' ' -f 1)
    # Subscription name depends of common service version
    if [[ ! -z ${sub} ]]; then
      kubectl delete sub ${sub} -n ${ads_namespace}
    fi

    sub=$(kubectl get sub -n ${ads_namespace} | grep ibm-zen-operator | cut -d ' ' -f 1)
    # Subscription name depends of common service version
    if [[ ! -z ${sub} ]]; then
      kubectl delete sub ${sub} -n ${ads_namespace}
    fi

    sub=$(kubectl get sub -n ${ads_namespace} | grep operand-deployment-lifecycle-manager | cut -d ' ' -f 1)
    kubectl delete sub ${sub} -n ${ads_namespace}
    
    local csv=$(kubectl get csv -n ${ads_namespace} | grep ibm-ads-kn-operator.${old_channel} | cut -d ' ' -f 1)
    kubectl delete csv ${csv} -n ${ads_namespace}

    csv=$(kubectl get csv -n ${ads_namespace} | grep ibm-common-service-operator | cut -d ' ' -f 1)
    kubectl delete csv ${csv} -n ${ads_namespace}

    csv=$(kubectl get csv -n ${ads_namespace} | grep ibm-commonui-operator | cut -d ' ' -f 1)
    kubectl delete csv ${csv} -n ${ads_namespace}

    csv=$(kubectl get csv -n ${ads_namespace} | grep ibm-iam-operator | cut -d ' ' -f 1)
    kubectl delete csv ${csv} -n ${ads_namespace}

    csv=$(kubectl get csv -n ${ads_namespace} | grep ibm-zen-operator | cut -d ' ' -f 1)
    kubectl delete csv ${csv} -n ${ads_namespace}

    csv=$(kubectl get csv -n ${ads_namespace} | grep operand-deployment-lifecycle-manager | cut -d ' ' -f 1)
    kubectl delete csv ${csv} -n ${ads_namespace}

    if ! ${is_openshift}; then
        # Remove workaround for for fixed bug in zen ingress generation by zen operator on CNCF platform
        # https://github.ibm.com/IBMPrivateCloud/roadmap/issues/66569
        kubectl delete cm "zen-ingress-nginx-template-fixed" --ignore-not-found
    fi

    create_ads_subscription ${new_channel} ${ads_namespace}
}

function semver_compare() {
    version1=$1
    version2=$2

    if [[ "${version1}" == "${version2}" ]]; then
        echo "0"
        return
    fi

    version1_major=$(printf %s "$version1" | cut -d'.' -f 1)
    version1_minor=$(printf %s "$version1" | cut -d'.' -f 2)
    version1_patch=$(printf %s "$version1" | cut -d'.' -f 3)

    version2_major=$(printf %s "$version2" | cut -d'.' -f 1)
    version2_minor=$(printf %s "$version2" | cut -d'.' -f 2)
    version2_patch=$(printf %s "$version2" | cut -d'.' -f 3)

    res=$(compare_number "$version1_major" "$version2_major")
    if [[ "${res}" != "0" ]]; then
        echo "${res}"
        return
    fi

    res=$(compare_number "$version1_minor" "$version2_minor")
    if [[ "${res}" != "0" ]]; then
        echo "${res}"
        return
    fi

    echo $(compare_number "$version1_patch" "$version2_patch")
}

function compare_number() {
    number1=$1
    number2=$2

    if [[ "${number1}" -gt "${number2}" ]]; then
        echo "1"
        return
    elif [[ "${number1}" -lt "${number2}" ]]; then
        echo "-1"
        return
    fi
    echo "0"
}

function add_target_namespace_to_operator_group() {
    local namespace=$1
    local operator_group_name=$2
    local operator_group_namespace=$3

    # extract target namespaces and convert the json array to a bash array
    target_namespaces=($(echo $(kubectl get operatorgroup -n ${operator_group_namespace} ${operator_group_name} -o jsonpath='{.spec.targetNamespaces}') | tr -d '[]" ' | ${sed} 's/,/ /g'))

    # check if already contains the namespace
    for i in "${target_namespaces[@]}"
    do
      if [[ $i == ${namespace} ]]; then
        value_found=true
        break
      fi
    done
    if [[ -z ${value_found+x} ]]; then
      title "Updating operator group ..."
      kubectl patch operatorgroup -n ${operator_group_namespace} ${operator_group_name} -p "[{'op':'add','path':'/spec/targetNamespaces/-','value': ${namespace}}]" --type=json

      if [[ $? -ne 0 ]]; then
        error "Error updating operator group."
      fi
    else
      info "target namespaces of the operator group already contain the namespace ${namespace}"
    fi
}
