{{/*
Create the name of the namespace
*/}}
{{- define "nsfactory.Namespace" -}}
{{- if .Values.namespace -}}
{{- .Values.namespace | lower | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Values.owner .Values.environment | lower | trunc 63 | trimSuffix "-" -}}
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
Normalized RBAC map: maps standard ClusterRoles to the groups defined in values.rbac
*/}}
{{- define "nsfactory.RBACMap" -}}
{{- $rbac := .Values.rbac | default dict -}}
{{- $map := dict -}}
{{- if $rbac.adminGroup }}{{ $_ := set $map "admin" $rbac.adminGroup }}{{ end -}}
{{- if $rbac.viewGroup }}{{ $_ := set $map "view" $rbac.viewGroup }}{{ end -}}
{{- $map | toJson -}}
{{- end -}}