#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version=v24.0

licensing_service_channel=v4.2
licensing_service_target_version="4.2.20"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.20"
ads_channel=v24.1
common_services_version=4.17.0 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 24.0.0
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 24.0.0

cs_minimal_version_for_ifix="4.6.2" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:734017cedb6605a4aba3a2de54c0ccb8e314e7b533ec0e30a362fa315ef8e1dd" # IBM License Manager 4.2.20 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-licensing/4.2.20/OLM/catalog-sources.yaml
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:97610d00d5b46b4de8d3c98233591cc554b7211d96f3d30ed935a84f076e3b65" # IBM Certificate Manager 4.2.20 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cert-manager/4.2.20/OLM/catalog-sources.yaml


cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:993ed6ac8869fd996472867fefb1469c54b75b62f31415d4ac90e7aec96ede26" # IBM Cloud Foundational Services 4.17.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.17.0/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:3c6a75939ccdef91c27442564c388294e02704a7c4acf14e3146090734b026f4" # IBM CS IM Operator Catalog 4.16.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.16.0/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:9a02519e5ab679f0807fc5b7cfc5fc96242961bee0e1d3144012d33e925e6a99" # IBM Zen Operator Catalog 6.4.0+20260210.170932.92 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.4.0%2B20260210.170932.92/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:d60af6e9b13f3d6932fa4719c6b01793c4f2439d3aa971dff07d8b54b75414f2" # 24.0.1-IF007
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:af4ac35100a8b93b36a9cb31c9cdf40fb190a0d78d29e4d5408b0d867a100a42" # Cloud Native PostgresSQL Version 1.25.5 (CASE 5.31.0+20260129.161021.2713) from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cloud-native-postgresql/5.31.0%2B20260129.161021.2713/OLM/catalog-sources.yaml
