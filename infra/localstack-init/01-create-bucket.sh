#!/bin/sh
# Tanda 6, Item 5 — crea el bucket de desarrollo apenas LocalStack queda listo.
# Es el "homónimo" local del bucket real de AWS: mismo nombre (planify-dev por
# default), mismo cliente S3 del backend, distinto endpoint únicamente.
set -e

BUCKET="${AWS_S3_BUCKET:-planify-dev}"

awslocal s3 mb "s3://${BUCKET}" 2>/dev/null || echo "Bucket ${BUCKET} ya existía."
