{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- define "zato.postgresql.fullname" -}}
{{- .Values.global.postgresql.fullname | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "zato.redis.fullname" -}}
{{- .Values.global.redis.fullname | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "zato.zatoscheduler.fullname" -}}
{{- .Values.zatoscheduler.fullname | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "zato.zatobootstrap.fullname" -}}
{{- .Values.zatobootstrap.fullname | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "zato.zatowebadmin.fullname" -}}
{{- .Values.zatowebadmin.fullname | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "zato.zatoserver.fullname" -}}
{{- .Values.zatoserver.fullname | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "helm.labels" -}}
helm.sh/chart: {{ include "helm.chart" . }}
{{ include "helm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "zato.postgresql.labels" -}}
helm.sh/chart: {{ include "helm.chart" . }}
{{ include "zato.postgresql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- define "zato.redis.labels" -}}
helm.sh/chart: {{ include "helm.chart" . }}
{{ include "zato.redis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- define "zato.zatoscheduler.labels" -}}
helm.sh/chart: {{ include "helm.chart" . }}
{{ include "zato.zatoscheduler.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- define "zato.zatobootstrap.labels" -}}
helm.sh/chart: {{ include "helm.chart" . }}
{{ include "zato.zatobootstrap.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "zato.zatowebadmin.labels" -}}
helm.sh/chart: {{ include "helm.chart" . }}
{{ include "zato.zatowebadmin.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "zato.zatoserver.labels" -}}
helm.sh/chart: {{ include "helm.chart" . }}
{{ include "zato.zatoserver.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "helm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "zato.postgresql.selectorLabels" -}}
app: {{ include "zato.postgresql.fullname" . }}
app.kubernetes.io/name: {{ include "helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "zato.redis.selectorLabels" -}}
app: {{ include "zato.redis.fullname" . }}
app.kubernetes.io/name: {{ include "helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "zato.zatoscheduler.selectorLabels" -}}
app: {{ include "zato.zatoscheduler.fullname" . }}
app.kubernetes.io/name: {{ include "helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "zato.zatobootstrap.selectorLabels" -}}
app: {{ include "zato.zatobootstrap.fullname" . }}
app.kubernetes.io/name: {{ include "helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "zato.zatowebadmin.selectorLabels" -}}
app: {{ include "zato.zatowebadmin.fullname" . }}
app.kubernetes.io/name: {{ include "helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "zato.zatoserver.selectorLabels" -}}
app: {{ include "zato.zatoserver.fullname" . }}
app.kubernetes.io/name: {{ include "helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}


{{/*
Create the name of the service account to use
*/}}
{{- define "zato.serviceAccountName" -}}
{{- if .Values.global.serviceAccount.create -}}
    {{ default (include "helm.fullname" .) .Values.global.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.global.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "zato.variables" -}}
- name: LB_HOSTNAME
  value: "{{ .Values.zatoserver.fullname }}.{{ .Release.Namespace }}.svc.cluster.local"
- name: LB_PORT
  value: {{ default 80 .Values.lbPort | quote }}
- name: LB_AGENT_PORT
  value: {{ default 20151 .Values.lbAgentPort | quote }}
- name: CLUSTER_NAME
  value: {{ default "zato" .Values.clusterName | quote  }}
- name: REDIS_HOSTNAME
  value: "{{- if .Values.global.redis.enabled -}}{{ .Values.global.redis.fullname }}.{{ .Release.Namespace }}.svc.cluster.local{{- else -}}{{ required "A valid redisHostname is required if Redis is not enabled!" .Values.redisHostname }}{{- end -}}"
- name: REDIS_PORT
  value: "{{- if .Values.global.redis.enabled -}}6379{{- else -}}{{ default 6379 .Values.redisPort }}{{- end -}}"
- name: ODB_TYPE
  value: "{{- if .Values.global.postgresql.enabled -}}postgresql{{- else -}}{{ default "postgresql" .Values.odbType }}{{- end -}}"
- name: ODB_HOSTNAME
  value: "{{- if .Values.global.postgresql.enabled -}}{{ .Values.global.postgresql.fullname }}.{{ .Release.Namespace }}.svc.cluster.local{{- else -}}{{ required "A valid odbHostname is required if PostgreSQL is not enabled!" .Values.odbHostname }}{{- end -}}"
- name: ODB_PORT
  value: "{{- if .Values.global.postgresql.enabled -}}5432{{- else -}}{{ default 5432 .Values.odbPort }}{{- end -}}"
- name: ODB_NAME
  value: "{{- if .Values.global.postgresql.enabled -}}zato{{- else -}}{{ default "zato" .Values.odbName }}{{- end -}}"
- name: ODB_USERNAME
  value: "{{- if .Values.global.postgresql.enabled -}}zato{{- else -}}{{ default "zato" .Values.odbUsername }}{{- end -}}"
- name: ZATO_ENMASSE_FILE
  value: {{ default "zato" .Values.zatoEnmasseFile | quote }}
- name: "SECRET_KEY"
  valueFrom:
    secretKeyRef:
      key:  secretKey
      name: {{ .Release.Name }}-auth
- name: "JWT_SECRET_KEY"
  valueFrom:
    secretKeyRef:
      key:  jwtSecretKey
      name: {{ .Release.Name }}-auth
- name: "ZATO_WEB_ADMIN_PASSWORD"
  valueFrom:
    secretKeyRef:
      key:  zatoWebAdminPassword
      name: {{ .Release.Name }}-auth
- name: "ZATO_IDE_PUBLISHER_PASSWORD"
  valueFrom:
    secretKeyRef:
      key:  zatoIdePublisherPassword
      name: {{ .Release.Name }}-auth
- name: "ZATO_ADMIN_INVOKE_PASSWORD"
  valueFrom:
    secretKeyRef:
      key:  zatoAdminInvokePassword
      name: {{ .Release.Name }}-auth
- name: "ODB_PASSWORD"
  valueFrom:
    secretKeyRef:
      key:  odbPassword
      name: {{ .Release.Name }}-auth
{{- end -}}

{{- define "zato.zatowebadmin.livenessProbe" -}}
httpGet:
  path: /accounts/login/
  port: {{ default "web" .Values.zatowebadmin.service.name | quote }}
initialDelaySeconds: {{ default 150 .Values.zatowebadmin.livenessProbe.initialDelaySeconds }}
failureThreshold: {{ default 10 .Values.zatowebadmin.livenessProbe.failureThreshold }}
periodSeconds: {{ default 20 .Values.zatowebadmin.livenessProbe.periodSeconds }}
{{- end -}}
{{- define "zato.zatowebadmin.readinessProbe" -}}
httpGet:
  path: /accounts/login/
  port: {{ default "web" .Values.zatowebadmin.service.name | quote }}
initialDelaySeconds: {{ default 110 .Values.zatowebadmin.readinessProbe.initialDelaySeconds }}
failureThreshold: {{ default 2 .Values.zatowebadmin.readinessProbe.failureThreshold }}
periodSeconds: {{ default 5 .Values.zatowebadmin.readinessProbe.periodSeconds }}
{{- end -}}
{{- define "zato.zatowebadmin.startupProbe" -}}
httpGet:
  path: /accounts/login/
  port: {{ default "web" .Values.zatowebadmin.service.name | quote }}
initialDelaySeconds: {{ default 90 .Values.zatowebadmin.startupProbe.initialDelaySeconds }}
failureThreshold: {{ default 2 .Values.zatowebadmin.startupProbe.failureThreshold }}
periodSeconds: {{ default 30 .Values.zatowebadmin.startupProbe.periodSeconds }}
{{- end -}}

{{- define "zato.zatoserver.livenessProbe" -}}
httpGet:
  path: /zato/ping
  port: {{ default "server" .Values.zatoserver.service.name | quote }}
initialDelaySeconds: {{ default 90 .Values.zatoserver.livenessProbe.initialDelaySeconds }}
failureThreshold: {{ default 10 .Values.zatoserver.livenessProbe.failureThreshold }}
periodSeconds: {{ default 20 .Values.zatoserver.livenessProbe.periodSeconds }}
{{- end -}}
{{- define "zato.zatoserver.readinessProbe" -}}
httpGet:
  path: /zato/ping
  port: {{ default "server" .Values.zatoserver.service.name | quote }}
initialDelaySeconds: {{ default 70 .Values.zatoserver.readinessProbe.initialDelaySeconds }}
failureThreshold: {{ default 2 .Values.zatoserver.readinessProbe.failureThreshold }}
periodSeconds: {{ default 5 .Values.zatoserver.readinessProbe.periodSeconds }}
{{- end -}}
{{- define "zato.zatoserver.startupProbe" -}}
httpGet:
  path: /zato/ping
  port: {{ default "server" .Values.zatoserver.service.name | quote }}
initialDelaySeconds: {{ default 60 .Values.zatoserver.startupProbe.initialDelaySeconds }}
failureThreshold: {{ default 2 .Values.zatoserver.startupProbe.failureThreshold }}
periodSeconds: {{ default 30 .Values.zatoserver.startupProbe.periodSeconds }}
{{- end -}}

{{- define "postgresql.name" -}}
{{- if .Values.global.postgresql.enabled -}}
zato
{{- else -}}
{{ default "zato" .Values.odbName }}
{{- end -}}
{{- end -}}

{{- define "postgresql.port" -}}
{{- if .Values.global.postgresql.enabled -}}
5432
{{- else -}}
{{ default 5432 .Values.odbPort }}
{{- end -}}
{{- end -}}

{{- define "postgresql.username" -}}
{{- if .Values.global.postgresql.enabled -}}
zato
{{- else -}}
{{ default "zato" .Values.odbUsername }}
{{- end -}}
{{- end -}}

{{- define "postgresql.password" -}}
{{- if .Values.global.postgresql.enabled -}}
zato
{{- else -}}
{{ default "zato" .Values.odbPassword }}
{{- end -}}
{{- end -}}
