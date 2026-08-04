#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version="v24.0,v24.1" 

licensing_service_channel=v4.2
licensing_service_target_version="4.2.21"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.21"
ads_channel=v25.0
common_services_version=4.19.2 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 25.0.0 (version from 24.0.0)
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 25.0.0

cs_minimal_version_for_ifix="4.12.0" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:8e2bee469a186599167283316e29f9e6e4f413b7bc7cdebcd3828ecf8f81b956" # IBM License Manager 4.2.24 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-licensing/4.2.24/OLM/catalog-sources.yaml
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:c704e8c7418cd6df1e766bd8aea2975d0e7c988509c28456bf37ca5b62c18ac8" # IBM Certificate Manager 4.2.23 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cert-manager/4.2.23/OLM/catalog-sources.yaml

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:56405e6eceab8851a1ef4e123283102c60ec4a0cf7e3760eb4737bd9f1552d2c" # IBM Cloud Foundational Services 4.19.2 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.19.2/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:cc6014641c67668e77d7a512ae02a0f2521f78ba406f86c17f340f13ea8c836a" # IBM CS IM Operator Catalog 4.18.1 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.18.1/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:1bcfdf65019d322a2d137f72bf216e80f98abfc80f8338b575d43fabf5bdebb9" # IBM Zen Operator Catalog 6.10.3+20260713.120632.33 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.10.3%2B20260713.120632.33/OLM/catalog-sources.yaml
ibm_pg_catalog_image="icr.io/cpopen/ibm-pg-operator-catalog@sha256:de4e217d062bbf110a98a5024b5e263e36673aab7262ed65423e1a6ee8304eb9" # IBM PG Catalog v28.4.0 from https://github.ibm.com/ibm-pg/ibm-pg-operator/releases/tag/v28.4.0
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:c1b13710d40ddd636fb4a93d6f1df7907cdcfd92ad5e00b0983ed851d1a9a667" # 25.0.0-IF006
