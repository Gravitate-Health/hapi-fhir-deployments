{{/*
Expand the name of the chart.
*/}}
{{- define "fhir-epi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Full release name. Avoids duplicate segment when release name already contains the chart name.
*/}}
{{- define "fhir-epi.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "fhir-epi.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "fhir-epi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Derive the internal PostgreSQL service hostname from the release name.
Used to wire hapi.externalDatabase.host when postgresql.enabled=true.
*/}}
{{- define "fhir-epi.postgresqlHost" -}}
{{- printf "%s-postgresql" .Release.Name }}
{{- end }}
