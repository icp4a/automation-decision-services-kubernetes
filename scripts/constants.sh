#!/usr/bin/env bash

# shellcheck disable=SC2034  #variables are sourced in scripts
olm_minimal_version=v0.23.1
olm_version=v0.32.0

ads_channel_previous_version="v24.0,v24.1,v25.0,v25.1" 

licensing_service_channel=v4.2
licensing_service_target_version="4.2.22"
ibm_cert_manager_channel_on_cncf=v4.2
redhat_cert_manager_channel_on_ocp=stable-v1
ads_channel=v26.0
ums_channel=v1.0
common_services_version=4.18.1 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 26.0.0 (version from 24.0.0)
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 26.0.0

cs_minimal_version_for_ifix="4.18.1" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:dc50f5d6e34b63d05e486bec83064a702fe60dd7ecaa0a827a154c4bf3a426d1" # IBM License Manager 4.2.23 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-licensing/4.2.23/OLM/catalog-sources.yaml
ibm_cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:cdfefe057e75b30c50b1cf9f8c2a71a07b498d09bb5b74c454d3a0a7c11aa989" # IBM Certificate Manager 4.2.22 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cert-manager/4.2.22/OLM/catalog-sources.yaml
ums_catalog_image="icr.io/cpopen/ibm-usage-metering-operator-catalog@sha256:b80738a02914c0eb08af87a7bc63226bf2b65de7add92156cc8d14673707b4dc" # IBM usage metering 1.0.6 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-usage-metering/1.0.6/OLM/catalog-sources.yaml

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:f76c75ccb46689bdfd7ad30169593c96895aba5458962681aaa3cef74fb7a324" # IBM Cloud Foundational Services 4.18.1 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.18.1/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:845eb294d21e6af580f70424f7c57886194cd5644bb1d57e31d8be6818b4fc2c" # IBM CS IM Operator Catalog 4.17.1 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.17.1/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:60e24dbd2d14ba44dc5dd24b4e295e6072dbd7d5278011342e011b5de2650c44" # IBM Zen Operator Catalog 6.4.7+20260608.081833.10 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.4.7%2B20260608.081833.10/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:579c447ca5e7dfe4469ff48904c14704c71c8d9699072d8736595c7231ac938c" # 26.0.0
