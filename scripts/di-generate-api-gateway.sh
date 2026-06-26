#!/usr/bin/env bash

set -o nounset


current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${current_dir}/utils.sh"

function show_help() {
    echo "Usage: $0 [-h] -n <namespace> [-g gateway-name] [-s tls-secret] [-o output-file]"
    echo "  -n <namespace>        Namespace where DI CMS is installed."
    echo "  -g gateway-name       Name of the existing Gateway resource (default: traefik-gateway)."
    echo "  -s tls-secret         Name of the TLS secret for Gateway listeners (default: traefik-tls-cert)."
    echo "  -o output-file        File where the kubernetes manifests will be generated. Default is a temporary file."
    echo ""
    echo "This script generates Kubernetes Gateway API resources for Traefik with TLS termination."
    echo "It creates HTTPRoute and BackendTLSPolicy resources for all DI CMS services."
    echo "If the Gateway does not exist, it will be created with the specified TLS secret."
}

di_namespace=""
client_id=""
output_file=""
cp_console_hostname=""
domain_name=""
gateway_name="traefik-gateway"
tls_secret="traefik-tls-cert"
template_file="api_gateway_template_traefik_tls_termination.yaml"

while getopts "h?n:g:s:o:?" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    n)  di_namespace=$OPTARG
        ;;
    g)  gateway_name=$OPTARG
        ;;
    s)  tls_secret=$OPTARG
        ;;
    o)  output_file=$OPTARG
        ;;
    esac
done

if [[ -z ${di_namespace} ]]; then
    error "DI CMS namespace is mandatory."
    show_help
    exit 1
fi

function check_prereqs() {
    title "Checking prereqs ..."
    check_command kubectl

    licensing_namespace=$(kubectl get sub -A 2>/dev/null | grep ibm-licensing-operator-app | awk '{print $1}' | head -n1)
    if [[ -z ${licensing_namespace} ]]; then
        warning "Could not detect licensing namespace. Licensing service configuration will be skipped."
        licensing_namespace=""
    else
        info "Detected licensing namespace: ${licensing_namespace}"
    fi

    # Check if Gateway API CRDs are installed
    if ! kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
        error "Gateway API CRDs are not installed. Please install Gateway API CRDs first."
        exit 1
    fi
    success "Gateway API CRDs are installed"

    if ! kubectl get crd httproutes.gateway.networking.k8s.io >/dev/null 2>&1; then
        error "HTTPRoute CRD is not installed. Please install Gateway API CRDs first."
        exit 1
    fi
    success "HTTPRoute CRD is installed"

    if ! kubectl get crd backendtlspolicies.gateway.networking.k8s.io >/dev/null 2>&1; then
        error "BackendTLSPolicy CRD is not installed. Please install Gateway API CRDs first."
        exit 1
    fi
    success "BackendTLSPolicy CRD is installed"

    # Check if TLS secret exists in DI CMS namespace
    if ! kubectl get secret "${tls_secret}" -n "${di_namespace}" >/dev/null 2>&1; then
        error "TLS secret '${tls_secret}' not found in namespace ${di_namespace}."
        exit 1
    fi
    success "TLS secret '${tls_secret}' exists in namespace ${di_namespace}"

    # Check if TLS secret exists in licensing namespace and copy if needed
    if [[ -n ${licensing_namespace} && "${licensing_namespace}" != "${di_namespace}" ]]; then
        if ! kubectl get secret "${tls_secret}" -n "${licensing_namespace}" >/dev/null 2>&1; then
            info "TLS secret '${tls_secret}' not found in namespace ${licensing_namespace}. Copying from ${di_namespace}..."
            kubectl get secret "${tls_secret}" -n "${di_namespace}" -o yaml | \
                sed "s/namespace: ${di_namespace}/namespace: ${licensing_namespace}/" | \
                kubectl apply -f - >/dev/null 2>&1
            if kubectl get secret "${tls_secret}" -n "${licensing_namespace}" >/dev/null 2>&1; then
                success "TLS secret '${tls_secret}' copied to namespace ${licensing_namespace}"
            else
                error "Failed to copy TLS secret '${tls_secret}' to namespace ${licensing_namespace}"
                exit 1
            fi
        else
            success "TLS secret '${tls_secret}' exists in namespace ${licensing_namespace}"
        fi
    fi

    # Check if Gateway exists or can be created
    if kubectl get gateway "${gateway_name}" -n "${di_namespace}" >/dev/null 2>&1; then
        info "Gateway '${gateway_name}' already exists in namespace ${di_namespace}"
        warning "The generated manifest will include the Gateway definition. You may want to remove it if the Gateway is managed elsewhere."
    else
        info "Gateway '${gateway_name}' does not exist. It will be created by the generated manifest."
    fi

    # Check if licensing Gateway exists
    if [[ -n ${licensing_namespace} && "${licensing_namespace}" != "${di_namespace}" ]]; then
        if kubectl get gateway "${gateway_name}-licensing" -n "${licensing_namespace}" >/dev/null 2>&1; then
            info "Gateway '${gateway_name}-licensing' already exists in namespace ${licensing_namespace}"
            warning "The generated manifest will include the licensing Gateway definition. You may want to remove it if the Gateway is managed elsewhere."
        else
            info "Gateway '${gateway_name}-licensing' does not exist. It will be created by the generated manifest."
        fi
    fi

    cp_console_hostname=$(kubectl get cm ibmcloud-cluster-info -n "${di_namespace}" -o jsonpath='{.data.cluster_address}')
    if [[ -z ${cp_console_hostname} ]]; then
        error "Cannot find cluster_address value in ibmcloud-cluster-info config map in namespace ${di_namespace}. Check that DI CMS is installed under ${di_namespace}."
        exit 1
    fi

    domain_name=$(kubectl get cm ibm-cpp-config -n "${di_namespace}" -o jsonpath='{.data.domain_name}')
    if [[ -z ${domain_name} ]]; then
        error "Cannot find domain_name value in ibm-cpp-config config map in namespace ${di_namespace}. Check that DI CMS is installed under ${di_namespace}."
        exit 1
    fi

}

function get_client_id() {
  client_id=$(kubectl get secret ibm-iam-bindinfo-platform-oidc-credentials -n "${di_namespace}" -o jsonpath='{.data.WLP_CLIENT_ID}' | base64 --decode)
  if [[ -z ${client_id} ]]; then
      error "Cannot retrieve client_ID from ibm-iam-bindinfo-platform-oidc-credential secret. Check the ADS CR has status ready."
      show_help
      exit 1
  fi
}

function check_backend_services() {
    title "Checking backend services ..."
    
    local services=("platform-auth-service" "platform-identity-provider" "platform-identity-management" "common-web-ui" "ibm-nginx-svc")
    local missing_services=()
    
    for service in "${services[@]}"; do
        if kubectl get service "${service}" -n "${di_namespace}" >/dev/null 2>&1; then
            success "Service '${service}' exists in namespace ${di_namespace}"
        else
            warning "Service '${service}' not found in namespace ${di_namespace}"
            missing_services+=("${service}")
        fi
    done
    
    if [[ ${#missing_services[@]} -gt 0 ]]; then
        warning "Some backend services are missing. HTTPRoutes for these services may fail until the services are created."
    fi
    
    # Check licensing service if licensing namespace is different
    if [[ -n ${licensing_namespace} && "${licensing_namespace}" != "${di_namespace}" ]]; then
        if kubectl get service ibm-licensing-service-instance -n "${licensing_namespace}" >/dev/null 2>&1; then
            success "Service 'ibm-licensing-service-instance' exists in namespace ${licensing_namespace}"
        else
            warning "Service 'ibm-licensing-service-instance' not found in namespace ${licensing_namespace}"
        fi
    fi
}

function create_ca_configmaps() {
  title "Creating CA certificate ConfigMaps ..."
  
  # Create ConfigMap for platform services (auth, identity, etc.)
  if kubectl get secret cs-ca-certificate-secret -n "${di_namespace}" >/dev/null 2>&1; then
    info "Extracting CA certificate from cs-ca-certificate-secret in namespace ${di_namespace}"
    kubectl get secret cs-ca-certificate-secret -n "${di_namespace}" -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/ca-${di_namespace}.crt
    
    # Delete existing ConfigMap if it exists
    kubectl delete configmap cs-ca-certificate-cm -n "${di_namespace}" --ignore-not-found
    
    # Create new ConfigMap
    kubectl create configmap cs-ca-certificate-cm -n "${di_namespace}" --from-file=ca.crt=/tmp/ca-${di_namespace}.crt
    success "Created ConfigMap cs-ca-certificate-cm in namespace ${di_namespace}"
    
    # Cleanup temp file
    rm -f /tmp/ca-${di_namespace}.crt
  else
    error "Secret cs-ca-certificate-secret not found in namespace ${di_namespace}"
    exit 1
  fi
  
  # Create ConfigMap for ibm-nginx-svc (uses different CA)
  if kubectl get secret ibm-nginx-internal-tls-ca -n "${di_namespace}" >/dev/null 2>&1; then
    info "Extracting CA certificate from ibm-nginx-internal-tls-ca in namespace ${di_namespace}"
    kubectl get secret ibm-nginx-internal-tls-ca -n "${di_namespace}" -o jsonpath='{.data.cert\.crt}' | base64 -d > /tmp/ibm-nginx-ca-${di_namespace}.crt
    
    # Delete existing ConfigMap if it exists
    kubectl delete configmap ibm-nginx-ca-cm -n "${di_namespace}" --ignore-not-found
    
    # Create new ConfigMap for ibm-nginx
    kubectl create configmap ibm-nginx-ca-cm -n "${di_namespace}" --from-file=ca.crt=/tmp/ibm-nginx-ca-${di_namespace}.crt
    success "Created ConfigMap ibm-nginx-ca-cm in namespace ${di_namespace}"
    
    # Cleanup temp file
    rm -f /tmp/ibm-nginx-ca-${di_namespace}.crt
  else
    warning "Secret ibm-nginx-internal-tls-ca not found in namespace ${di_namespace}"
    warning "BackendTLSPolicy for ibm-nginx-svc may not work correctly"
  fi
  
  # Handle licensing namespace CA certificate
  if [[ -n ${licensing_namespace} && "${licensing_namespace}" != "${di_namespace}" ]]; then
    # Check for ibm-license-service-cert-internal (licensing service uses its own cert)
    if kubectl get secret ibm-license-service-cert-internal -n "${licensing_namespace}" >/dev/null 2>&1; then
      info "Extracting CA certificate from ibm-license-service-cert-internal in namespace ${licensing_namespace}"
      
      # Try to extract ca.crt first, if not available use tls.crt (self-signed case)
      if kubectl get secret ibm-license-service-cert-internal -n "${licensing_namespace}" -o jsonpath='{.data.ca\.crt}' 2>/dev/null | base64 -d > /tmp/ca-licensing-${licensing_namespace}.crt 2>/dev/null && [ -s /tmp/ca-licensing-${licensing_namespace}.crt ]; then
        info "Using ca.crt from secret"
      else
        info "No ca.crt found, using tls.crt (self-signed certificate)"
        kubectl get secret ibm-license-service-cert-internal -n "${licensing_namespace}" -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/ca-licensing-${licensing_namespace}.crt
      fi
      
      # Delete existing ConfigMap if it exists
      kubectl delete configmap ibm-licensing-ca-cert-cm -n "${licensing_namespace}" --ignore-not-found
      
      # Create new ConfigMap with different name for licensing
      kubectl create configmap ibm-licensing-ca-cert-cm -n "${licensing_namespace}" --from-file=ca.crt=/tmp/ca-licensing-${licensing_namespace}.crt
      success "Created ConfigMap ibm-licensing-ca-cert-cm in namespace ${licensing_namespace}"
      
      # Cleanup temp file
      rm -f /tmp/ca-licensing-${licensing_namespace}.crt
    else
      warning "Secret ibm-license-service-cert-internal not found in namespace ${licensing_namespace}"
      warning "BackendTLSPolicy for licensing service may not work correctly"
    fi
  fi
}

function replace() {
  if [[ -z ${output_file} ]]; then
      output_file=$(mktemp)
  fi

  info "Writing kubernetes manifests to ${output_file}"

  cp "${current_dir}/${template_file}" "${output_file}"
  ${sed} -i "s/NAMESPACE/${di_namespace}/g" "${output_file}"
  ${sed} -i "s/HOST/${cp_console_hostname}/g" "${output_file}"
  ${sed} -i "s/DOMAIN/${domain_name}/g" "${output_file}"
  ${sed} -i "s/CLIENT_ID/${client_id}/g" "${output_file}"
  ${sed} -i "s/LICENSING_NS/${licensing_namespace}/g" "${output_file}"
  ${sed} -i "s/GATEWAY_NAME/${gateway_name}/g" "${output_file}"
  ${sed} -i "s/TLS_SECRET/${tls_secret}/g" "${output_file}"
}

function generate() {
    check_prereqs
    check_backend_services
    get_client_id
    create_ca_configmaps
    replace
    
    info ""
    info "Generated manifests written to: ${output_file}"
    info ""
    info "To apply the manifests, run:"
    info "  kubectl apply -f ${output_file}"
    info ""
    if kubectl get gateway "${gateway_name}" -n "${di_namespace}" >/dev/null 2>&1; then
        warning "Note: Gateway '${gateway_name}' already exists in namespace ${di_namespace}. You may want to remove the Gateway definition from the generated file if it's managed elsewhere."
    fi
    if [[ -n ${licensing_namespace} && "${licensing_namespace}" != "${di_namespace}" ]]; then
        if kubectl get gateway "${gateway_name}-licensing" -n "${licensing_namespace}" >/dev/null 2>&1; then
            warning "Note: Gateway '${gateway_name}-licensing' already exists in namespace ${licensing_namespace}. You may want to remove the licensing Gateway definition from the generated file if it's managed elsewhere."
        fi
    fi
}

# --- Run ---
generate

# Made with Bob
