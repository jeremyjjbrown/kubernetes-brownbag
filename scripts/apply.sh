#!/bin/bash -x


PROJECT_ID="${PROJECT_ID:-sandbox-304501}"
SUFFIX="${SUFFIX:-k8s-brownbag}"
GCP_ZONE="${GCP_ZONE:-us-central1-a}"

MACHINE_TYPE="${MACHINE_TYPE:-n1-standard-2}"
NODES="${NODES:-2}"
CLUSTER_NAME="cluster-${SUFFIX}"

gcloud config set project $PROJECT_ID

gcloud container clusters describe --zone "$GCP_ZONE" "$CLUSTER_NAME" | \
    gcloud container clusters create \
        --shielded-secure-boot \
        --enable-shielded-nodes \
        --machine-type "$MACHINE_TYPE" \
        --num-nodes "$NODES" \
        --zone "$GCP_ZONE" \
        --cluster-version latest \
        "$CLUSTER_NAME"

gcloud container clusters get-credentials --zone "$GCP_ZONE" $CLUSTER_NAME
