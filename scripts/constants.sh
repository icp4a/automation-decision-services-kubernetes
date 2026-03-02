#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version="v24.0,v24.1" 

licensing_service_channel=v4.2
licensing_service_target_version="4.2.19"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.19"
ads_channel=v25.0
common_services_version=4.16.0 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 25.0.0 (version from 24.0.0)
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 25.0.0

cs_minimal_version_for_ifix="4.12.0" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:7a6822eddbbdaa62555b61e529f3f620fa42c0e5472d48eeefeeaeea00f9e939" # IBM License Manager 4.2.19 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-licensing/4.2.19/OLM/catalog-sources.yaml
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:d67b90ea57739794853674a4999beba00cd67a806174a00d397f55eebb1a76f4" # IBM Certificate Manager 4.2.19 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cert-manager/4.2.19/OLM/catalog-sources.yaml

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:f24bad596f32cc6531420c8533419d6b7bc5c65da5578ab9ca6e55180cd72ac5" # IBM Cloud Foundational Services 4.16.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.16.0/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:620c8985b5e6056082a5e0aa35a91e1de7aeb15145690a4683bd80a32b3e4fa6" # IBM CS IM Operator Catalog 4.15.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.15.0/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:78ec2c576051a5ef98da6f9da5f18a490a148e9e988877fbac386147c69f080f" # IBM Zen Operator Catalog 6.3.0+20251203.153430.336 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.3.0%2B20251203.153430.336/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:858661d937dfd29eb82c64dbd383dd6bdd184fa438e14d9aa8da69b69dd42b53" # 25.0.0-IF004
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:4b7cf401006cd4d4060a664c8313b3690916746d0df40bd96c9e592f6aba541f" # Cloud Native PostgresSQL Version 1.25.2 (CASE 5.16.0+20250722.134758.2626)