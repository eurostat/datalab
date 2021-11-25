{{/* vim: set filetype=mustache: */}}

{{- define "keycloak.realm.config" -}}
{
  "realm": "datalab-demo",
  "accessTokenLifespan": 86400,
  "resetPasswordAllowed": true,
  "attributes": {
    "userProfileEnabled": "true"
  },
  "smtpServer": {{ .Values.smtpServer | nindent 2}},
  "accountTheme": "keycloak",
  "enabled": true,
  "requiredCredentials": [
    "password"
  ],
  "roles": {
    "realm": [
      {
        "name": "user",
        "description": "User privileges"
      },
      {
        "name": "admin",
        "description": "Administrator privileges"
      }
    ]
  },
  "defaultRoles": [
    "user"
  ],
  "clients": [
    {
      "clientId": "{{ .Values.onyxia.ui.env.OIDC_CLIENT_ID }}",
      "rootUrl": "https://datalab.{{ .Values.domainName }}",
      "baseUrl": "",
      "enabled": true,
      "publicClient": true,
      "redirectUris": [
        "http://datalab.{{ .Values.domainName }}/*",
        "https://datalab.{{ .Values.domainName }}/*"
      ],
      "webOrigins": [
        "*"
      ],
      "attributes": {
        "oauth2.device.authorization.grant.enabled": "true",
        "use.refresh.tokens": "true"
      },
      "protocolMappers": [
        {
          "name": "policy",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-hardcoded-claim-mapper",
          "consentRequired": false,
          "config": {
            "claim.value": "stsonly",
            "userinfo.token.claim": "true",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "policy",
            "jsonType.label": "String",
            "access.tokenResponse.claim": "false"
          }
        },
        {
          "name": "audience-minio",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-audience-mapper",
          "consentRequired": false,
          "config": {
            "included.client.audience": "minio",
            "id.token.claim": "false",
            "access.token.claim": "true"
          }
        }
      ]
    } 
	  {{- if .Values.minio.enabled -}}
	  ,
    {
      "clientId": "minio",
      "rootUrl": "https://minio-console.{{ .Values.domainName }}",
      "baseUrl": "",
      "enabled": true,
      "publicClient": true,
      "redirectUris": [
        "http://minio-console.{{ .Values.domainName }}/*",
        "https://minio-console.{{ .Values.domainName }}/*"
      ],
      "webOrigins": [
        "*"
      ],
      "attributes": {
        "oauth2.device.authorization.grant.enabled": "true",
        "use.refresh.tokens": "true"
      },
      "protocolMappers": [
        {
          "name": "groups",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-group-membership-mapper",
          "consentRequired": false,
          "config": {
            "full.path": "true",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "groups",
            "userinfo.token.claim": "true"
          }
        },
        {
          "name": "policy",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-hardcoded-claim-mapper",
          "consentRequired": false,
          "config": {
            "claim.value": "stsonly",
            "userinfo.token.claim": "true",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "policy",
            "jsonType.label": "String",
            "access.tokenResponse.claim": "true"
          }
        }
      ]
    }
    {{- end -}}
  ]
}
{{- end -}}

