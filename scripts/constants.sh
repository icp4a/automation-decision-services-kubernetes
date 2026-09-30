#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version=v23.2

licensing_service_channel=v4.2
licensing_service_target_version="4.2.25"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.24"
ads_channel=v24.0
common_services_version=4.19.3 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.2.0" # Minimal supported Common Service version before upgrading from 23.0.2
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 23.0.2

cs_minimal_version_for_ifix="4.6.2" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:4792e438543d715ff01a6f60b95bd1ecef7d4b3e24e27ca1be969b38e7ca2052" # IBM License Manager 4.2.25 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-licensing/4.2.25/OLM/catalog-sources.yaml
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:f9b9562ea1dac3571cc23b8b2223e2d594ae7ffe17177032e8032c058c173716" # IBM Certificate Manager 4.2.24 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cert-manager/4.2.24/OLM/catalog-sources.yaml

cs_catalog_image="icr.io/cpopen/ibm-common-service-catalog@sha256:3691595427457382ee517373962d6a6cb9a26e6a41c0ef2f576e3e5e793833a7" # IBM Cloud Foundational Services 4.19.3 from https://github.ibm.com/IBMPrivateCloud/cloud-pak/blob/master/repo/case/ibm-cp-common-services/4.19.3/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:77374759f3ce95a798f7f3aa143fdb650400eee08217ca48ab6c1237dcb9277a" # IBM Zen Operator Catalog 6.10.7+20260901.133040.21 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.10.7%2B20260901.133040.21/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:17e886626d5a6da204c09f82d8993dc303a57005abaae4aa9c80bea9344e0a6e" # 24.0.0-IF011
ibm_pg_catalog_image="icr.io/cpopen/ibm-pg-operator-catalog@sha256:a0f4e97558a9974552212766015cb87029ecd4c8be032d0ff07234ccccc3969b" # IBM PG Catalog v28.4.3 from https://github.ibm.com/ibm-pg/ibm-pg-operator/releases/tag/v28.4.3
