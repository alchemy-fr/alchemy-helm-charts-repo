#!/bin/bash

set -e

NS=${NS:-"ps-test"}
RELEASE_NAME="ps-test"
CHART_DIR=charts/phrasea
VALUE_SRC=test/scaleway.yaml

kubectl config use-context scaleway-phrasea-test

case $1 in
  uninstall)
    helm uninstall ${RELEASE_NAME} || true;
    ;;
  validate)
    helm install --dry-run --debug ${RELEASE_NAME} "${CHART_DIR}" \
        -f "${VALUE_SRC}" \
        --namespace $NS
    ;;
  update | upgrade)
    echo "Updating..."
    helm upgrade ${RELEASE_NAME} "${CHART_DIR}" \
        -f "${VALUE_SRC}" \
        --namespace $NS
    ;;

  *)
    if [ ! -d "${CHART_DIR}/charts" ]; then
      (cd "${CHART_DIR}" && helm dependency update)
    fi
    kubectl create ns $NS || true
    helm uninstall ${RELEASE_NAME} --namespace $NS || true;
    kubectl -n $NS delete jobs --all
    kubectl -n $NS delete pvc elasticsearch-databox-master-elasticsearch-databox-master-0 || true
    while [ $(kubectl -n $NS get pvc | wc -l) -gt 0 ] || [ $(kubectl -n $NS get pods | wc -l) -gt 0 ]
    do
      echo "Waiting for resources to be deleted..."
      sleep 5
    done
    echo "Installing release ${RELEASE_NAME} in namespace $NS..."
    helm install ${RELEASE_NAME} "${CHART_DIR}" \
        -f "${VALUE_SRC}" \
        --namespace $NS
    ;;
esac
