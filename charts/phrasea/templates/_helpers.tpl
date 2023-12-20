{{- define "ps.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "ps" .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "ps.name" -}}
{{- .Values.nameOverride | default "ps" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "volumes.configs" }}
- name: configs
  configMap:
    name: {{ .Values.globalConfig.externalConfigmapName | default (printf "%s-configs" .Release.Name) }}
{{- end }}

{{- define "imagePullSecrets" }}
{{- if .Values.image.pullSecret.enabled }}
imagePullSecrets:
- name: {{ .Values.image.pullSecret.name }}
{{- end }}
{{- end }}

{{- define "annotation.checksum.configs" }}
checksum/configs: {{ .Values.globalConfig.content | sha256sum }}
{{- end }}

{{- define "secretRef.adminOAuthClient" }}
- secretRef:
    name: {{ .Values.params.adminOAuthClient.externalSecretName | default (printf "%s-admin-oauth-client-secret" .Release.Name) }}
{{- end }}

{{- define "secretName.rabbitmq" -}}
{{- .Values.rabbitmq.externalSecretName | default "rabbitmq-secret" -}}
{{- end }}
{{- define "secretName.postgresql" -}}
{{- .Values.postgresql.externalSecretName | default "postgresql-secret" -}}
{{- end }}

{{- define "secretRef.ingress.tls.wildcard" -}}
{{- with .Values.ingress.tls.wildcard }}
{{- if and .enabled .externalSecretName -}}
{{- .externalSecretName -}}
{{- else -}}
gateway-tls
{{- end }}
{{- end }}
{{- end }}

{{- define "envFrom.rabbitmq" }}
- configMapRef:
    name: rabbitmq-php-config
- secretRef:
    name: {{ include "secretName.rabbitmq" . }}
{{- end }}

{{- define "envFrom.postgresql" }}
- configMapRef:
    name: postgresql-php-config
- secretRef:
    name: {{ include "secretName.postgresql" . }}
{{- end }}

{{- define "secretRef.postgresql" }}
- secretRef:
    name: {{ .Values.postgresql.externalSecretName | default "api-db-secret" }}
{{- end }}

{{- define "configMapRef.phpApp" }}
- configMapRef:
    name: php-config
- configMapRef:
    name: urls-config
{{- end }}

{{- define "envRef.phpApp" }}
{{- $appName := .app }}
{{- $ctx := .ctx }}
{{- $glob := .glob }}
{{- if or (eq $appName "databox") (or (eq $appName "uploader") (eq $appName "expose")) }}
{{- $secretName := $ctx.api.config.s3Storage.externalSecretKey | default (printf "%s-s3-secret" $appName) }}
{{- $mapping := $ctx.api.config.s3Storage.externalSecretMapping }}
- name: S3_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ $mapping.accessKey }}
- name: S3_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ $mapping.secretKey }}
{{- end }}
{{- if $ctx.rabbitmq }}
- name: RABBITMQ_VHOST
  value: {{ $ctx.rabbitmq.vhost | quote }}
{{- end }}
{{- if $ctx.database }}
- name: DB_NAME
  value: {{ $ctx.database.name | quote }}
{{- end }}
{{- end }}

{{- define "app.volumes" }}
{{- $appName := .app -}}
{{- $ctx := .ctx -}}
{{- $glob := .glob -}}
{{- if .glob.Values._internal.volumes }}
{{- if hasKey $glob.Values._internal.volumes $appName }}
{{- with (index $glob.Values._internal.volumes $appName) }}
{{- range $key, $value := . }}
- name: {{ $key }}
{{- if $ctx.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ $ctx.persistence.existingClaim | default (printf "%s-%s" $value.name (include "ps.fullname" $glob)) }}
{{- else }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.volumesMounts" }}
{{- $appName := .app }}
{{- $ctx := .ctx }}
{{- $glob := .glob }}
{{- if .glob.Values._internal.volumes }}
{{- if hasKey .glob.Values._internal.volumes $appName }}
{{- with (index .glob.Values._internal.volumes $appName) }}
{{- range $key, $value := . }}
- name: {{ $key }}
  mountPath: {{ $value.mountPath }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.s3Storage.configMap" }}
{{- $ctx := .ctx }}
{{- $glob := .glob }}
S3_ENDPOINT: {{ tpl $ctx.s3Storage.endpoint $glob | quote }}
S3_REGION: {{ $ctx.s3Storage.region | default "eu-central-1" | quote }}
S3_USE_PATH_STYLE_ENDPOINT: {{ ternary "true" "false" (or $ctx.s3Storage.usePathSyleEndpoint $glob.Values.minio.enabled) | quote }}
S3_BUCKET_NAME: {{ $ctx.s3Storage.bucketName | quote }}
S3_PATH_PREFIX: {{ $ctx.s3Storage.pathPrefix | quote }}
{{- end }}

{{- define "app.cloudFront.configMap" }}
{{- $ctx := .ctx }}
{{- $glob := .glob }}
{{- if $ctx.cloudFront.url }}
CLOUD_FRONT_URL: {{ tpl $ctx.cloudFront.url $glob | quote }}
CLOUD_FRONT_REGION: {{ $ctx.cloudFront.region | default "eu-central-1" | quote }}
CLOUD_FRONT_PRIVATE_KEY: {{ $ctx.cloudFront.privateKey | quote }}
CLOUD_FRONT_KEY_PAIR_ID: {{ $ctx.cloudFront.keyPairId | quote }}
CLOUD_FRONT_TTL: {{ $ctx.cloudFront.ttl | quote }}
{{- end }}
{{- end }}

{{- define "app.client.configMap" }}
{{- $ctx := .ctx }}
{{- $glob := .glob }}
DEV_MODE: "0"
CLIENT_ID: {{ $ctx.client.oauthClient.id | quote }}
{{- if $glob.Values.keycloak.autoConnectIdP }}
AUTO_CONNECT_IDP: {{ $glob.Values.keycloak.autoConnectIdP | quote }}
{{- end }}
{{- if $glob.Values.sentry.enabled }}
SENTRY_DSN: {{ required "Missing sentry.clientDsn" $glob.Values.sentry.clientDsn | quote }}
SENTRY_ENVIRONMENT: {{ required "Missing sentry.environment" $glob.Values.sentry.environment | quote }}
{{- end }}
{{- if $ctx.matomo.enabled }}
MATOMO_URL: {{ required "Missing .matomo.baseUrl" $ctx.matomo.baseUrl | quote }}
MATOMO_SITE_ID: {{ required "Missing .matomo.siteId" $ctx.matomo.siteId | quote }}
{{- end }}
{{- end }}

{{- define "ingress.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
networking.k8s.io/v1
{{- else -}}
networking.k8s.io/v1beta1
{{- end -}}
{{- end -}}

{{- define "ingress.rule_path" }}
{{- if ._.Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" }}
- backend:
    service:
      name: {{ .name }}
      port:
        number: {{ .port }}
  path: /
  pathType: Prefix
{{- else }}
- backend:
    serviceName: {{ .name }}
    servicePort: {{ .port }}
  path: {{ .path | default "/" }}
{{- end }}
{{- end }}

{{- define "configurator.containerSpecs" -}}
name: configurator
image: {{ .Values.repository.baseurl }}/ps-configurator:{{ .Values.repository.tag }}
{{- if not (eq "latest" .Values.repository.tag) }}
imagePullPolicy: Always
{{- end }}
terminationMessagePolicy: FallbackToLogsOnError
volumeMounts:
- name: configs
  mountPath: /configs
env:
- name: MAIL_FROM
  value: {{ .Values.mailer.from | quote }}
- name: MAILER_DSN
  value: {{ required "Missing .mailer.dsn value" .Values.mailer.dsn | quote }}
- name: AUTH_DB_NAME
  value: {{ .Values.auth.database.name | quote }}
{{- range .Values._internal.services }}
{{- $appName := . }}
{{- with (index $.Values $appName) }}
- name: {{ upper $appName }}_DB_NAME
  value: {{ .database.name | quote }}
- name: {{ upper $appName }}_ADMIN_CLIENT_ID
  value: {{ .adminOAuthClient.id | quote }}
- name: {{ upper $appName }}_ADMIN_CLIENT_SECRET
  value: {{ .adminOAuthClient.secret | quote }}
{{- end }}
{{- end }}
{{- range .Values._internal.clients }}
{{- $appName := . }}
{{- with (index $.Values $appName) }}
- name: {{ upper $appName }}_CLIENT_ID
  value: {{ .client.oauthClient.id | quote }}
{{- end }}
{{- end }}
envFrom:
- secretRef:
    name: keycloak
{{- include "configMapRef.phpApp" $ }}
{{- include "envFrom.rabbitmq" $ }}
{{- include "envFrom.postgresql" $ }}
{{- end }}
