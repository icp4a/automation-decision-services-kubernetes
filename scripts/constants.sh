#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version=v23.2

licensing_service_channel=v4.2
licensing_service_target_version="4.2.8"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.8"
ads_channel=v24.0
common_services_version=4.6.11 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.2.0" # Minimal supported Common Service version before upgrading from 23.0.2
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 23.0.2

cs_minimal_version_for_ifix="4.6.2" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:17980ccacb1aeae19729e7d5129ad0b69e0f18a2c30f9f1a0db1daf9ae7c2e92" # IBM License Manager 4.2.13 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.13
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:21866a45719eef50764c421c349a539262147d215ef87c8cc2174fdf2c269346" # IBM Certificate Manager 4.2.13 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.13

cs_catalog_image="icr.io/cpopen/ibm-common-service-catalog@sha256:b84df988dfbfeff7ad2128ae9f1ac8f77d0c31864b02da16cd89fb68e3d9c8ac" # IBM Cloud Foundational Services 4.6.11 from https://github.ibm.com/IBMPrivateCloud/cloud-pak/tree/master/repo/case/ibm-cp-common-services/4.6.11
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:1a6c02284bdc1b84ccd51a78750c3fabe92d8de6e191fa8b0fcdc01151ee81a9" # 24.0.0-IF006
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:3b867e7e0879ec24b5058e5db01c0a9be8d9d8d5ef2b7bb1bb7e247babb8b96d" # Cloud Native PostgresSQL 1.22.7 (CASE 4.30.0+20241023.165233.2074) from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cloud-native-postgresql/4.30.0%2B20241023.165233.2074/OLM/catalog-sources.yaml
