{{- define "hello-app.name" -}}
hello-app
{{- end }}

{{- define "hello-app.fullname" -}}
{{ .Release.Name }}-hello-app
{{- end }}
