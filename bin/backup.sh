#!/usr/bin/env bash

set -o errexit
set -o pipefail

[[ ${DEBUG} == 'true' ]] && set -x

export NC='\e[0m'
export GREEN='\e[0;32m'
export YELLOW='\e[0;33m'
export RED='\e[0;31m'

log()     { (2>/dev/null echo -e "$@${NC}"); }
info()    { log "${GREEN}[INFO] $@"; }
warning() { log "${YELLOW}[WARNING] $@"; }
error()   { log "${RED}[ERROR] $@"; }

KUBE_SERVER=${KUBE_SERVER:-https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}}
KUBE_TOKEN=${KUBE_TOKEN:-$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)}

DATESTAMP=`date +%Y%m%d_%H%M`
BACKUP_PATH="${BACKUP_PATH:-"/tmp"}"
BACKUP_KUBE_PATH="${BACKUP_PATH}/kube-resources" # temporary backup path for kube resources
BACKUP_TAR="${BACKUP_PATH}/kube_resources_${DATESTAMP}.tar.gz"

function move_s3() {
  # No-op when no backup
  if [[ -z ${S3_PATH} ]]; then
    warning "No 'S3_PATH' has been defined, backup is located in ${BACKUP_TAR}"
    exit 0
  fi

  local destpath=${S3_PATH}${BACKUP_TAR#${BACKUP_PATH}}
  local s3cli_args=""

  # Check destination before uploading
  if [[ -f ${BACKUP_TAR} ]]; then
    info "Uploading backed up file to S3"
    if [[ -n ${S3_CA_BUNDLE} ]]; then
      s3cli_args+=" --ca-bundle ${S3_CA_BUNDLE}"
    elif [[ ${S3_NO_SSL_VERIFY} == true ]]; then
      s3cli_args+=" --no-verify-ssl"
    fi
    if [[ -n ${S3_AWS_ENDPOINT} ]]; then
      s3cli_args+=" --endpoint-url ${S3_AWS_ENDPOINT}"
    fi
    if [[ -n ${S3_KMS_ID} ]]; then
      s3cli_args+=" --sse aws:kms --sse-kms-key-id ${S3_KMS_ID}"
    fi
    aws s3 mv ${s3cli_args} ${BACKUP_TAR} ${destpath}
  else
    error "Backed up file does not exist"
    exit 1
  fi
}

function tar_backup() {
  info "Backing up to tar file..."
  (
    cd "${BACKUP_PATH}"
    tar -cvzf "${BACKUP_TAR}" -C "${BACKUP_KUBE_PATH}" .
    rm -fr "${BACKUP_KUBE_PATH}"
  )
  info "Backed up to: ${BACKUP_TAR}"
}

# Creates a backup of the current cluster
function clusterbackup() {
  mkdir -p "${BACKUP_KUBE_PATH}"

  info "Starting Cluster Backup"

  # backup each namespace's resources
  for namespace in $(kd run get ns -o json | yq e '.items[].metadata.name' -); do
    info "Starting export for ${namespace} namespace..."
    # get yaml of resources without unneeded fields
    kd run -n "${namespace}" get all,secret,configmap -o yaml | yq e \
      'del(
        .items[].metadata.creationTimestamp,
        .items[].metadata.generation,
        .items[].metadata.managedFields,
        .items[].metadata.namespace,
        .items[].metadata.resourceVersion,
        .items[].metadata.uid,
        .items[].status
      )' - > "${BACKUP_KUBE_PATH}/${namespace}_kube_resources.yml" &
  done

  log "Waiting for all exports to complete..."
  wait

  info "Export complete"

  tar_backup
  move_s3
}

clusterbackup
