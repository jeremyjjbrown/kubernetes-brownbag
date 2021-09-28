#!/bin/bash

PROJECT_ID="${PROJECT_ID:-t-operative-325618}"
SUFFIX="${SUFFIX:-k8s-brownbag}"
GCP_ZONE="${GCP_ZONE:-us-central1-a}"

CLUSTER_NAME="cluster-${SUFFIX}"


gcloud config set project $PROJECT_ID
gcloud container clusters delete --zone "$GCP_ZONE" "$CLUSTER_NAME" | \
    echo "$CLUSTER_NAME already deleted"
