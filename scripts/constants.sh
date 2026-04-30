#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.32.0

ads_channel_previous_version="v24.0,v24.1" 

licensing_service_channel=v4.2
licensing_service_target_version="4.2.21"
ibm_cert_manager_channel_on_cncf=v4.2
redhat_cert_manager_channel_on_ocp=stable-v1
ads_channel=v25.1
common_services_version=4.18.0 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 25.0.1 (version from 24.0.0)
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 25.0.1

cs_minimal_version_for_ifix="4.12.0" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:fbef092ea62c545c311f48c0cc6d313f37f5a660253930e92ed00bacde684f96" # IBM License Manager 4.2.21 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.21
ibm_cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:f3280ce1a45a6f7139b79bba402d137f1ac661699baf21e566f03d17d7807b59" # IBM Certificate Manager 4.2.21 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.21

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:99e9d2c387395e31d40fec96c47b1cc7d4610eb3682369ab99d0f211fbd34eca" # IBM Cloud Foundational Services 4.18.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.18.0/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:beac2f4e7369a320e4a2eebd938830af0fe8e9c68bde5b0d5427a989441e63ae" # IBM CS IM Operator Catalog 4.17.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.17.0/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:cf2a4c2f1b8bc2e03ba1d78e7650c7bbf5af9560f2c56352bdcf6b7cfc7b9bf9" # IBM Zen Operator Catalog 6.4.2+20260322.214626.9 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.4.2%2B20260322.214626.9/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:71996d7972b247e90064c080d17de7e2faff74e88b713e0bc49bafe2ec0d3ec0" # 25.0.1-IF001
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:4b7cf401006cd4d4060a664c8313b3690916746d0df40bd96c9e592f6aba541f" # Cloud Native PostgresSQL Version 1.25.2 (CASE 5.16.0+20250722.134758.2626)
