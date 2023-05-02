#!/usr/bin/env bash

usage() {
  echo "$0 [<dependencies-namespace>]"
  echo "  If <dependencies-namespace> is given, the script will looks for dependencies pod in the provided namespace"
}

custom_namespace=""
if [[ ! -z $1 ]]; then
  custom_namespace="--namespace=$1"
fi

current_project=$(kubectl config view --minify -o jsonpath='{..namespace}')
echo "Searching for ADS common issues in current project: $current_project"


total_steps=5
current_step=1
issues_found=0
problems_summary=""

echo "$current_step / $total_steps Looking for ADS pods that looks not healthy"

not_healthy_pods=$(kubectl get pods --field-selector=status.phase!=Running | grep ads | grep -v Completed)
if [[ ! -z ${not_healthy_pods} ]]; then
  echo "Please investigate for issues in following pods"
  echo "${not_healthy_pods}"
  issues_found=$((issues_found+1))
  problems_summary="$problems_summary"$'\n'"Not healthy pods:"$'\n'"$not_healthy_pods"
  if [[ "$not_healthy_pods" == *"ContainerStatusUnknown"* ]]; then
    echo "ContainerStatusUnknown is a status that might be related to evicted pods. Pods eviction is related to resources limits on pods, depending on selected ADS profile size. Please see documentation if you need to customize default limits"
    problems_summary="$problems_summary"$'\n'"NB:"$"ContainerStatusUnknown is a status that might be related to evicted pods. Pods eviction is related to resources limits on pods, depending on selected ADS profile size. Please see documentation if you need to customize default limits"
  fi
else
  echo "pods are ok"
fi
current_step=$((current_step+1))

echo "$current_step / $total_steps Looking for ADS pods (label app.kubernetes.io/component: ads) that restarted once or more"
restarted_pods=$(kubectl get pods --selector=app.kubernetes.io/component=ads | awk '{if(NR>1)print}' | awk '{if($4>=1)print$1 " restarted "$4" time(s)"}')
if [[ ! -z ${restarted_pods} ]]; then
  echo "Those pods are restarting, please investigate as this is not expected"
  echo "${restarted_pods}"
  problems_summary="$problems_summary "$'\n'"Restarted pods: "$'\n'"$restarted_pods"
  issues_found=$((issues_found+1))
else
  echo "no unexpected restart found"
fi
current_step=$((current_step+1))

echo "$current_step / $total_steps Looking for problematic IOPS values - ROKS case"
gold_class_issues=$(kubectl get PersistentVolumeClaims | grep mongo | grep ads | grep gold | awk '{if(substr($4, 1, length($4)-2)<30)print$1 " size "$4" is too small for "$6" storage class. 30Gi is a minimum to not face Mongo issues with this storage class (300 IOPS is the minimum)"}')
silver_class_issues=$(kubectl get PersistentVolumeClaims | grep mongo | grep ads | grep silver | awk '{if(substr($4, 1, length($4)-2)<75)print$1 " size "$4" is too small for "$6" storage class. 75Gi is a minimum to not face Mongo issues with this storage class (300 IOPS is the minimum)"}')
bronze_class_issues=$(kubectl get PersistentVolumeClaims | grep mongo | grep ads | grep bronze | awk '{if(substr($4, 1, length($4)-2)<150)print$1 " size "$4" is too small for "$6" storage class. 150Gi is a minimum to not face Mongo issues with this storage class (300 IOPS is the minimum)"}')
if [[ ! -z ${gold_class_issues} ]]; then
  echo "You may face issues with Embedded Mongo service as the following persistent volume claims are not following recommandations"
  echo "${gold_class_issues}"
  problems_summary="$problems_summary"$'\n'"ROKS storage class - not enough IOPS:"$'\n'"$gold_class_issues"
  issues_found=$((issues_found+1))
fi
if [[ ! -z ${silver_class_issues} ]]; then
  echo "You may face issues with Embedded Mongo service as the following persistent volume claims are not following recommandations"
  echo "${silver_class_issues}"
  problems_summary="$problems_summary"$'\n'"ROKS storage class - not enough IOPS:"$'\n'"$silver_class_issues"
  issues_found=$((issues_found+1))
fi
if [[ ! -z ${bronze_class_issues} ]]; then
  echo "You may face issues with Embedded Mongo service and services using it (rest api, runtime, credentials service, etc) as the following persistent volume claims are not following recommandations"
  echo "${bronze_class_issues}"
  problems_summary="$problems_summary"$'\n'"ROKS storage class - not enough IOPS:"$'\n'"$bronze_class_issues"
  issues_found=$((issues_found+1))
fi
current_step=$((current_step+1))

echo "$current_step / $total_steps Verify other Common Services Foundation components pods"
not_healthy_dep_pods=$(kubectl get pods $custom_namespace --field-selector=status.phase!=Running | grep 'zen\|ibm-nginx' | grep -v Completed)
if [[ ! -z ${not_healthy_dep_pods} ]]; then
  echo "Please investigate for issues in following pods as this may affect ADS availability or stability"
  echo "${not_healthy_dep_pods}"
  problems_summary="$problems_summary"$'\n'"Non ADS pods that may impact ADS availability or stability:"$'\n'"$not_healthy_dep_pods"
  issues_found=$((issues_found+1))
else
    echo "pods are ok"
fi

current_step=$((current_step+1))
echo "$current_step / $total_steps Verify cluster nodes"
# Verify cluster nodes
node_status=$(for i in $(kubectl get node | grep -v NAME | awk {'print $2'} | sort -u); do echo "$i";done)
echo -e ""Nodes Status"                   :$node_status"


echo "Summary of found issues (if any):"
if [[ "$issues_found" -gt "0" ]]; then
  echo ""
  echo ""
  echo "$issues_found problem(s) found, please investigate identified problems:"
  echo ""
  echo "$problems_summary"
  echo ""
else
  echo "No known issue found"
fi
