#!/usr/bin/env bash

# shellcheck disable=SC2034  #variables are sourced in scripts
olm_minimal_version=v0.23.1
olm_version=v0.32.0

ads_channel_previous_version="v24.0,v24.1,v25.0,v25.1" 

licensing_service_channel=v4.2
licensing_service_target_version="4.2.25"
ibm_cert_manager_channel_on_cncf=v4.2
redhat_cert_manager_channel_on_ocp=stable-v1
ads_channel=v26.0
ums_channel=v1.0
common_services_version=4.19.3 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 26.0.0 (version from 24.0.0)
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 26.0.0

cs_minimal_version_for_ifix="4.18.1" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:4792e438543d715ff01a6f60b95bd1ecef7d4b3e24e27ca1be969b38e7ca2052" # IBM License Manager 4.2.25 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-licensing/4.2.25/OLM/catalog-sources.yaml
ibm_cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:f9b9562ea1dac3571cc23b8b2223e2d594ae7ffe17177032e8032c058c173716" # IBM Certificate Manager 4.2.24 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cert-manager/4.2.24/OLM/catalog-sources.yaml
ums_catalog_image="icr.io/cpopen/ibm-usage-metering-operator-catalog@sha256:1f8c98bec85b84972b941fb042409a2ee4cb10c08d9772bb4dad5fdad6ac497a" # IBM usage metering 1.0.8 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-usage-metering/1.0.8/OLM/catalog-sources.yaml

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:8ec932814004deaa28ee8c32440b2baa58b21aa7f2989b33659a95aa19c877a6" # IBM Cloud Foundational Services 4.19.3 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.19.3/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:38f8b86f2adb55e5c620cd6f4be9fbe5644314fb36627efdd1e517c78bd000e2" # IBM CS IM Operator Catalog 4.18.2 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.18.2/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:77374759f3ce95a798f7f3aa143fdb650400eee08217ca48ab6c1237dcb9277a" # IBM Zen Operator Catalog 6.10.7+20260901.133040.21 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.10.7%2B20260901.133040.21/OLM/catalog-sources.yaml
ibm_pg_catalog_image="icr.io/cpopen/ibm-pg-operator-catalog@sha256:18438a0894751d9c225347a762ddc7994a055176a8a3983fea03960caa4fd02f" # IBM PG Catalog v28.4.5 from https://github.ibm.com/ibm-pg/ibm-pg-operator/releases/tag/v28.4.5
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:d881e3baf1a63f059e9247d040c082222773390c7357d88059148dd725638771" # 26.0.0-IF003
