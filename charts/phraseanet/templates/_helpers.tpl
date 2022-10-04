{{/*
Sets extra Phraseanet Ingress annotations
*/}}
{{- define "phraseanet.ingressAnnotations" -}}
  {{- if .Values.ingress.annotations }}
  annotations:
    {{- $tp := typeOf .Values.ingress.annotations }}
    {{- if eq $tp "string" }}
      {{- tpl .Values.ingress.annotations . | nindent 4 }}
    {{- else }}
      {{- toYaml .Values.ingress.annotations | nindent 4 }}
    {{- end }}
  {{- end }}
{{- end -}}



{{/*
Sets extra SAML Deployment annotations
*/}}
{{- define "saml.annotations" -}}
  {{- if .Values.saml.annotations }}
      annotations:
        {{- $tp := typeOf .Values.saml.annotations }}
        {{- if eq $tp "string" }}
          {{- tpl .Values.saml.annotations . | nindent 8 }}
        {{- else }}
          {{- toYaml .Values.saml.annotations | nindent 8 }}
        {{- end }}
  {{- end }}
{{- end -}}