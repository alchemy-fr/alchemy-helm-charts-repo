# Phrasea Chart

### TLS

You can enable wildcard TLS:

```yaml
ingress:
  tls:
    wildcard:
      enabled: true
      #externalSecretName:
      # or
      crt: |
        ...
      key: |
        ...
```

or configure TLS for each ingress:
```yaml
uploader:
  api:
    ingress:
      tls:
      - secretName: uploader-api-tls-secret
        # Optional:
        # if not provided the hostname will be automatically set
        # with the .Values.uploader.api.hostname value
        host: api.uploader.com
  client:
    ingress:
      tls:
      - secretName: uploader-client-tls-secret
        # Optional:
        # if not provided the hostname will be automatically set
        # with the .Values.uploader.client.hostname value
        host: client.uploader.com
```

## Run migration

```bash
export MIGRATION_NAME=20230807
helm template <release-name> -f values.yaml \
  --set "configurator.executeMigration" "${MIGRATION_NAME}" \
    -s templates/job-tests.yaml | kubectl apply -f -
kubectl attach -it pod/${MIGRATION_NAME}
kubectl delete -it pod/${MIGRATION_NAME}
```
