#!/usr/bin/env bash

ads_channel=v23.1
common_services_channel=v4.0

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:81d170807fad802496814ef35ab5877684031c178117eb3c8dc9bdeddbb269a0" # IBM License Manager 4.0.0
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:9ecbd78444208da0e2981b7a9060d2df960e09b59ac9990a959df069864085c2" # IBM Certificate Manager 4.0.0

cs_catalog_image="icr.io/cpopen/ibm-common-service-catalog@sha256:baec9f6a7b1710b1bba7f72ccc792c17830e563a1f85b8fb7bdb57505cde378a" # IBM Cloud Foundational Services 4.0
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:a06b9c054e58e089652f0e4400178c4a1b685255de9789b80fe5d5f526f9e732" # Cloud Native PostgresSQL 4.14.0+20230619 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cloud-native-postgresql/4.14.0%2B20230616.111503
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:8937eda83f290cf0af4b32e65f90ad8e5044a5377c005858030c6d12d6ce2206" # 23.0.1-IF005
