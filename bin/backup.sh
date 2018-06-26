#!/usr/bin/env bash

set -o errexit
set -o pipefail

[[ ${DEBUG} == 'true' ]] && set -x

KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)
DATESTAMP=`date +%Y%m%d_%H%M`
BACKUP_PATH=${BACKUP_PATH:-/tmp}
BACKUP_FILE=${BACKUP_PATH}/kube_resources.yaml
BACKUP_TAR=${BACKUP_PATH}/kube_resources_${DATESTAMP}.tar.gz

KUBECTL_CMD=${KUBECTL_CMD:-"kubectl --insecure-skip-tls-verify=true --token ${KUBE_TOKEN} --server https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}"}

function error_exit() {
  echo "ERROR: ${1}"
  exit 1
}

function info() {
  echo "INFO: ${1}"
}

function move_s3() {
  local destpath=${S3_PATH}${BACKUP_TAR#${BACKUP_PATH}}
  local s3cli_args=""
  # Noop when no backup
  [[ -z ${S3_PATH} ]] && \
    return 0

  # Check destination before uploading
  if [[ -f ${BACKUP_TAR} ]] ; then
    info "Uploading backed up file to s3"
    if [[ ${CA_BUNDLE} ]] ; then
      s3cli_args+=" --ca-bundle ${CA_BUNDLE}"
    elif [[ ${NO_SSL_VERIFY} ]]; then
      s3cli_args+=" --no-verify-ssl"
    fi
    if [[ -n ${AWS_ENDPOINT} ]] ; then
      s3cli_args+=" --endpoint-url ${AWS_ENDPOINT}"
    fi
    if [[ -n ${KMS_ID} ]] ; then
      s3cli_args+=" --sse aws:kms --sse-kms-key-id ${KMS_ID}"
    fi
      aws s3 mv ${s3cli_args} ${BACKUP_TAR} ${destpath}
  else
    error_exit "Backed up file does not exist"
    exit 1
  fi
}

function tar_backup() {
  (
    cd ${BACKUP_PATH}
    tar -cvzf ${BACKUP_TAR} ${BACKUP_FILE}
    rm -fr ${BACKUP_FILE}
  )
  info "Backed up to: ${BACKUP_FILE}"
}

# Creates a backup of the current cluster
function clusterbackup() {

  info "Start Cluster Backup"
  ${KUBECTL_CMD} get all,secret,configmap --export=true --all-namespaces=true -o yaml > ${BACKUP_FILE}
  tar_backup
  move_s3
}

clusterbackup
