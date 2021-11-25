{{/* vim: set filetype=mustache: */}}

{{/*
Define policies for MinIO
*/}}
{{- define "datalab.minio.stspolicy" -}}
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::${jwt:preferred_username}",
                "arn:aws:s3:::${jwt:preferred_username}/*"
            ]
        }
        {{- if .Values.projects -}}
        {{- range .Values.projects }}
        ,
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::{{ .name }}",
                "arn:aws:s3:::{{ .name }}/*"
            ],
            "Condition": {
                "StringEquals": {
                    "jwt:preferred_username": {{ .members | toJson}}
                        
                }
            }
        }
        {{- end }}    
        {{- end -}}
    ]
}
{{- end -}}

