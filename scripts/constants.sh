#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version=v23.2

licensing_service_channel=v4.2
licensing_service_target_version="4.2.2"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.2"
ads_channel=v24.0
common_services_version=4.6.2 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.2.0" # Minimal supported Common Service version before upgrading from 23.0.2
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 23.0.2

cs_minimal_version_for_ifix="4.6.2" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:dfdd38cac150cd354853ac88d02396a9457d22964f898d10126b4a880b4d0916" # IBM License Manager 4.2.2 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.2
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:955732299dd174524612ec8e8076237a491cedee1264e4e4be39c2a92f48bc39" # IBM Certificate Manager 4.2.2 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.2

cs_catalog_image="icr.io/cpopen/ibm-common-service-catalog@sha256:601e84bf15e92a98e2b9a6e64320a2cd4f4912533bf49407eed4aeacca8d0c00" # IBM Cloud Foundational Services 4.6.2 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-common-services/4.6.2
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:20562f48373e571bd842e19dada63322e18356720cb14cce6849cf58fdc3af7e" # 24.0.0
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:c96aa2e6bce92f2e5e4874116cf1cc1cdd60676499cd04ab1631462b8b883357" # Cloud Native PostgresSQL 4.18.0 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cloud-native-postgresql/4.18.0

