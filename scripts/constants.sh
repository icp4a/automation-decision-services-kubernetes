#!/usr/bin/env bash

# shellcheck disable=SC2034  #variables are sourced in scripts
olm_minimal_version=v0.23.1
olm_version=v0.32.0

ads_channel_previous_version="v24.0,v24.1,v25.0,v25.1" 

licensing_service_channel=v4.2
licensing_service_target_version="4.2.26"
ibm_cert_manager_channel_on_cncf=v4.2
redhat_cert_manager_channel_on_ocp=stable-v1
ads_channel=v26.0
ums_channel=v1.0
common_services_version=4.19.4 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 26.0.0 (version from 24.0.0)
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 26.0.0

cs_minimal_version_for_ifix="4.18.1" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:ac0e40ab5d64d0615347280b23ae354c19421d29d2a1b8e315ed96d451d8c9fc" # IBM License Manager 4.2.26 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-licensing/4.2.26/OLM/catalog-sources.yaml
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:dba0a5eb7ef0aa7bbfa208e6349044b368d3439d0622e3f3f8afef7944105190" # IBM Certificate Manager 4.2.25 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cert-manager/4.2.25/OLM/catalog-sources.yaml
ums_catalog_image="icr.io/cpopen/ibm-usage-metering-operator-catalog@sha256:89eb9a38f557904954beb692f79f017af79b3c762bff969510ce1b509e21a6df" # IBM usage metering 1.0.9 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-usage-metering/1.0.9/OLM/catalog-sources.yaml

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:093d00305d3cd0a1c09eac1f6dbf2a734482b2cc1c4c234f5a2ee3a2bd30311c" # IBM Cloud Foundational Services 4.19.4 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.19.4/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:bcb496c21cada7ad7c107fa92d98bd5e3f7498ec17363188ef4d9ace53e2ee9e" # IBM CS IM Operator Catalog 4.18.3 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.18.3/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:f36585ad0f278b26fccf617adc39b3ce93e5dbf6bda54b72ea1063bbb226d01b" # IBM Zen Operator Catalog 6.10.8+20260929.112719.45 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.10.8%2B20260929.112719.45/OLM/catalog-sources.yaml
ibm_pg_catalog_image="icr.io/cpopen/ibm-pg-operator-catalog@sha256:70f8c8e3961809ced95394e3eee01aac759c2bc36e34612f688bd83a55c33675" # IBM PG Catalog v28.4.8 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-pg-operator/28.4.8/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:580e0889e0c87ec3cc4ed99d285bc324e91fa3dd63894aaeac0209df0abf3b4c" # 26.0.0-IF004
