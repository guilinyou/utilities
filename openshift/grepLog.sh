#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 -c <cluster_name> [-p <project_name> | -d <deployment_list> | -o <pod_list>] -g <grep_pattern>"
  exit 1
}

# Parsing command line arguments
while getopts ":c:p:d:o:g:" opt; do
  case $opt in
    c) CLUSTER_NAME="$OPTARG" ;;
    p) PROJECT_NAME="$OPTARG" ;;
    d) DEPLOYMENT_LIST="$OPTARG" ;;
    o) POD_LIST="$OPTARG" ;;
    g) GREP_PATTERN="$OPTARG" ;;
    *) usage ;;
  esac
done

# Check if the necessary arguments are provided
if [[ -z "$CLUSTER_NAME" || -z "$GREP_PATTERN" || ( -z "$PROJECT_NAME" && -z "$DEPLOYMENT_LIST" && -z "$POD_LIST" ) ]]; then
  usage
fi

# Fetching pod names based on provided input
if [[ ! -z "$PROJECT_NAME" ]]; then
  POD_NAMES=$(oc get pods -n "$PROJECT_NAME" -o jsonpath='{.items[*].metadata.name}')
elif [[ ! -z "$DEPLOYMENT_LIST" ]]; then
  IFS=',' read -r -a deployments <<< "$DEPLOYMENT_LIST"
  POD_NAMES=""
  for deployment in "${deployments[@]}"; do
    deployment_pods=$(oc get pods -l app="$deployment" -o jsonpath='{.items[*].metadata.name}')
    POD_NAMES="$POD_NAMES $deployment_pods"
  done
elif [[ ! -z "$POD_LIST" ]]; then
  IFS=',' read -r -a pods <<< "$POD_LIST"
  POD_NAMES="${pods[@]}"
fi

# Loop through the pod names and fetch logs
for pod in $POD_NAMES; do
  LOGS=$(oc logs "$pod")
  MATCHES=$(echo "$LOGS" | grep "$GREP_PATTERN")
  if [[ ! -z "$MATCHES" ]]; then
    echo "Cluster: $CLUSTER_NAME"
    echo "Pod: $pod"
    echo "$MATCHES"
  fi
done
