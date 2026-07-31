{{/* Chart name */}}
{{- define "woc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Fully qualified app name */}}
{{- define "woc.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "woc.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels */}}
{{- define "woc.labels" -}}
app.kubernetes.io/name: {{ include "woc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/* Selector labels */}}
{{- define "woc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "woc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* ServiceAccount name */}}
{{- define "woc.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "woc.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/* Resolved Weaviate namespace: explicit value, else the release namespace */}}
{{- define "woc.weaviateNamespace" -}}
{{- default .Release.Namespace .Values.weaviate.namespace -}}
{{- end -}}
