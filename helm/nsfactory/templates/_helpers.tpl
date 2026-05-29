{{/*
Standardize K8S object names (lower, trunc, trim)
*/}}
{{- define "nsfactory.K8SObjectName" -}}
{{- . | lower | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the namespace
*/}}
{{- define "nsfactory.Namespace" -}}
{{- if .Values.namespace -}}
{{- include "nsfactory.K8SObjectName" .Values.namespace -}}
{{- else -}}
{{- printf "%s-%s" .Values.owner .Values.environment | include "nsfactory.K8SObjectName" -}}
{{- end -}}
{{- end -}}


{{/*
Create the name of the resource quota
*/}}
{{- define "nsfactory.ResourceQuota" -}}
{{- printf "resourcequota-%s" (include "nsfactory.Namespace" .) -}}
{{- end -}}

{{/*
Create the name of the limit range
*/}}
{{- define "nsfactory.LimitRange" -}}
{{- printf "limitrange-%s" (include "nsfactory.Namespace" .) -}}
{{- end -}}

{{/*
Create the name of the app project
*/}}
{{- define "nsfactory.AppProject" -}}
{{- printf "%s-project" (include "nsfactory.Namespace" .) -}}
{{- end -}}

{{/*
Normalized RBAC map: maps standard ClusterRoles to the groups defined in values.rbac
*/}}
{{- define "nsfactory.RBACMap" -}}
{{- $rbac := .Values.rbac | default dict -}}
{{- $map := dict -}}
{{- if $rbac.adminGroup }}{{ $_ := set $map "admin" $rbac.adminGroup }}{{ end -}}
{{- if $rbac.viewGroup }}{{ $_ := set $map "view" $rbac.viewGroup }}{{ end -}}
{{- $map | toJson -}}
{{- end -}}