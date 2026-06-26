#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version=v24.0

licensing_service_channel=v4.2
licensing_service_target_version="4.2.21"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.21"
ads_channel=v24.1
common_services_version=4.18.0 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 24.0.0
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 24.0.0

cs_minimal_version_for_ifix="4.6.2" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:fbef092ea62c545c311f48c0cc6d313f37f5a660253930e92ed00bacde684f96" # IBM License Manager 4.2.21 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.21
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:f3280ce1a45a6f7139b79bba402d137f1ac661699baf21e566f03d17d7807b59" # IBM Certificate Manager 4.2.21 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.21

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:99e9d2c387395e31d40fec96c47b1cc7d4610eb3682369ab99d0f211fbd34eca" # IBM Cloud Foundational Services 4.18.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.18.0/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:beac2f4e7369a320e4a2eebd938830af0fe8e9c68bde5b0d5427a989441e63ae" # IBM CS IM Operator Catalog 4.17.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.17.0/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:cf2a4c2f1b8bc2e03ba1d78e7650c7bbf5af9560f2c56352bdcf6b7cfc7b9bf9" # IBM Zen Operator Catalog 6.4.2+20260322.214626.9 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.4.2%2B20260322.214626.9/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:0469afc413d07b58d77701a17b0180f7dd89e752d749fc53c31dce91301bfe69" # 24.0.1-IF008

edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:af4ac35100a8b93b36a9cb31c9cdf40fb190a0d78d29e4d5408b0d867a100a42" # Cloud Native PostgresSQL Version 1.25.5 (CASE 5.31.0+20260129.161021.2713) from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cloud-native-postgresql/5.31.0%2B20260129.161021.2713/OLM/catalog-sources.yaml
