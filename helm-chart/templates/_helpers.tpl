{{/*
Expand the name of the chart.
*/}}
{{- define "stock-management.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "stock-management.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "stock-management.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "stock-management.labels" -}}
helm.sh/chart: {{ include "stock-management.chart" . }}
{{ include "stock-management.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "stock-management.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stock-management.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Backend labels
*/}}
{{- define "stock-management.backend.labels" -}}
{{ include "stock-management.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "stock-management.backend.selectorLabels" -}}
{{ include "stock-management.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "stock-management.frontend.labels" -}}
{{ include "stock-management.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "stock-management.frontend.selectorLabels" -}}
{{ include "stock-management.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Database labels
*/}}
{{- define "stock-management.database.labels" -}}
{{ include "stock-management.labels" . }}
app.kubernetes.io/component: database
{{- end }}

{{/*
Database selector labels
*/}}
{{- define "stock-management.database.selectorLabels" -}}
{{ include "stock-management.selectorLabels" . }}
app.kubernetes.io/component: database
{{- end }}
