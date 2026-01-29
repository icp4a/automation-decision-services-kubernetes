#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version=v23.2

licensing_service_channel=v4.2
licensing_service_target_version="4.2.8"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.8"
ads_channel=v24.0
common_services_version=4.6.19 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.2.0" # Minimal supported Common Service version before upgrading from 23.0.2
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 23.0.2

cs_minimal_version_for_ifix="4.6.2" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:7a6822eddbbdaa62555b61e529f3f620fa42c0e5472d48eeefeeaeea00f9e939" # IBM License Manager 4.2.19 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.19
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:d67b90ea57739794853674a4999beba00cd67a806174a00d397f55eebb1a76f4" # IBM Certificate Manager 4.2.19 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.19

cs_catalog_image="icr.io/cpopen/ibm-common-service-catalog@sha256:4c66b428446b91781439bb92c1cccfe9d69d621a8a4077e1106fd1e69dda8ba7" # IBM Cloud Foundational Services 4.6.19 from https://github.ibm.com/IBMPrivateCloud/cloud-pak/tree/master/repo/case/ibm-cp-common-services/4.6.19
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:dd63cba90f4145f05a9aca4e8f6fe10134d4544f598c68fad6b486ed2742f80c" # 24.0.0-IF008
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:a333a9dc5f8c81aed7201a574f784a85b68ea55d8a45af235956aac1406009e4" # Cloud Native PostgresSQL 1.25.3 (CASE 5.22.0+20251001.142254.2660) from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cloud-native-postgresql/5.22.0%2B20251001.142254.2660/OLM/catalog-sources.yaml
