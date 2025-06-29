#!/usr/bin/env bash

set -o nounset


current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${current_dir}/utils.sh"

function show_help() {
    echo "Usage: $0 [-h] [-t] -n <namespace> [-o output-file]"
    echo "  -n <namespace>        Namespace where ADS is installed."
    echo "  -o output-file        File where the kubernetes manifests will be generated. Default is a temporary file."
    echo "  -t                    Configure ingresses to perform tls termination with certificates into ads-ingress-tls-secret secret."

}

ads_namespace=""
client_id=""
output_file=""
cp_console_hostname=""
domain_name=""
template_file="ingress_template_nginx.yaml"
tls_termination=false
while getopts "h?n:o:t?" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    n)  ads_namespace=$OPTARG
        ;;
    o)  output_file=$OPTARG
        ;;
    t)  tls_termination=true
        ;;
    esac
done

if [[ -z ${ads_namespace} ]]; then
    error "ADS namespace is mandatory."
    show_help
    exit 1
fi

if [[ "${tls_termination}" = true ]]; then
  template_file="ingress_template_nginx_tls_termination.yaml"
fi

function check_prereqs() {
    title "Checking prereqs ..."
    check_command kubectl

    licensing_namespace=$(kubectl get sub -A | grep ibm-licensing-operator-app | cut -d ' ' -f1)

    cp_console_hostname=$(kubectl get cm ibmcloud-cluster-info -n ${ads_namespace} -o jsonpath='{.data.cluster_address}')
    if [[ -z ${cp_console_hostname} ]]; then
        error "Cannot find cluster_address value in ibmcloud-cluster-info config map in namespace ${ads_namespace}. Check that ADS is installed under ${ads_namespace}."
        exit 1
    fi

    domain_name=$(kubectl get cm ibm-cpp-config -n ${ads_namespace} -o jsonpath='{.data.domain_name}')
    if [[ -z ${domain_name} ]]; then
        error "Cannot find domain_name value in ibm-cpp-config config map in namespace ${ads_namespace}. Check that ADS is installed under ${ads_namespace}."
        exit 1
    fi

}

function get_client_id() {
  client_id=$(kubectl get secret ibm-iam-bindinfo-platform-oidc-credentials -n ${ads_namespace} -o jsonpath='{.data.WLP_CLIENT_ID}' | base64 --decode)
  if [[ -z ${client_id} ]]; then
      error "Cannot retrieve client_ID from ibm-iam-bindinfo-platform-oidc-credential secret. Check the ADS CR has status ready."
      show_help
      exit 1
  fi
}

function replace() {
  if [[ -z ${output_file} ]]; then
      output_file=$(mktemp)
  fi

  info "Writing kubernetes manifests to ${output_file}"

  cp "${current_dir}/${template_file}" ${output_file}
  ${sed} -i "s/NAMESPACE/${ads_namespace}/g" ${output_file}
  ${sed} -i "s/HOST/${cp_console_hostname}/g" ${output_file}
  ${sed} -i "s/DOMAIN/${domain_name}/g" ${output_file}
  ${sed} -i "s/CLIENT_ID/${client_id}/g" ${output_file}
  ${sed} -i "s/LICENSING_NS/${licensing_namespace}/g" ${output_file}

  # add nginx.ingress.kubernetes.io/proxy-buffer-size annotations to zen ingress
  echo "" >> ${output_file}
  echo "---" >> ${output_file}

  tmp_zen_ingress=$(mktemp)

  kubectl get ingress zen-ingress -n ${ads_namespace} -o yaml | \
    # remove system properties
    kubectl patch -f - -p '{"metadata":{"creationTimestamp": null, "generation": null, "ownerReferences": null, "resourceVersion": null, "uid": null}, "status":null}' --type=merge --dry-run='client' -o yaml | \
    # add annotation
    kubectl patch -f - -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/proxy-buffer-size":"8k"}}}' --type=merge --dry-run='client' -o yaml \
      > ${tmp_zen_ingress}

    if [[ "${tls_termination}" = true ]]; then
      tmp_zen_ingress_work=$(mktemp)
      # add tls section
      # kubectl patch -f ${tmp_zen_ingress} -p='[{"op": "add", "path": "/spec", "value": {"tls": { "hosts": ["CPD_HOST"], "secretName": "cpd-ingress-tls-secret" }}}]' --type=json --dry-run='client' -o yaml | \
      kubectl patch -f ${tmp_zen_ingress} -p '{"spec": {"tls": [{"hosts": ["CPD_HOST"], "secretName": "cpd-ingress-tls-secret" }]}}' --type=merge --dry-run='client' -o yaml | \
      # add annotation
      kubectl patch -f - -p '{"metadata":{"annotations":{"cert-manager.io/issuer":"zen-tls-issuer"}}}' --type=merge --dry-run='client' -o yaml  \
        > ${tmp_zen_ingress_work}
      cat ${tmp_zen_ingress_work} > ${tmp_zen_ingress} && rm ${tmp_zen_ingress_work}
      ${sed} -i "s/CPD_HOST/ads-cpd.${domain_name}/g" ${tmp_zen_ingress}
    fi

    cat ${tmp_zen_ingress} >> ${output_file}
    rm ${tmp_zen_ingress}
}

function generate() {
    check_prereqs
    get_client_id
    replace
}

# --- Run ---
generate
