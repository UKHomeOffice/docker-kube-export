# Docker Image: Kube Export

[![Build Status](https://drone.acp.homeoffice.gov.uk/api/badges/UKHomeOffice/docker-kube-export/status.svg)](https://drone.acp.homeoffice.gov.uk/UKHomeOffice/docker-kube-export)

Exports all kube resources from a cluster and pushes up to an S3 bucket

## Configurable options

The following environment variables can be passed in to configure kube export backups for your environment:

| ENVIRONMENT VARIABLE | DESCRIPTION | REQUIRED | DEFAULT VALUE |
|----------------------|-------------|----------|---------------|
| BACKUP_PATH | Set the directory to copy the kube-export backup to | N | `/tmp` |
| KUBE_SERVER | API endpoint for the Kubernetes Cluster | N | `${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}` |
| KUBE_TOKEN | Access Token to interact with the API | N | `$(</var/run/secrets/kubernetes.io/serviceaccount/token)` |
| S3_AWS_ENDPOINT | Custom S3 endpoint URL | N | NULL |
| S3_CA_BUNDLE | The CA bundle for the S3 endpoint | N | NULL |
| S3_KMS_ID | A KMS ID to use for encrypting the backups in S3 | N | NULL |
| S3_NO_SSL_VERIFY | Skip TLS verify for the S3 endpoint | N | `false` |
| S3_PATH | Provide the S3 bucket path to copy the backup to, e.g. `s3://my-bucket`<br>If unset, the backup is left in `BACKUP_PATH` | N | NULL |

We use the [KD](https://github.com/UKHomeOffice/kd#configuration) release image to perform the kube export task, so any environment variables supported by this binary can be passed in.
