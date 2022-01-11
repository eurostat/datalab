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
  "users": [
    {{- if .Values.demo.enabled -}}
    {
      "username" : "demo",
      "enabled": true,
      "credentials" : [
        { 
          "type" : "password",
          "value" : "demo"
        }
      ],
      "realmRoles": [ "default-roles-datalab-demo" ]
    }
    {{- range .Values.demo.users }}
    ,{
      "username" : "{{ .name }}",
      "enabled": true,
      "email": "{{ .name }}@example-demo.test",
      "credentials" : [
        { 
          "type" : "password",
          "value" : "{{ .password }}"
        }
      ],
      "realmRoles": [ "default-roles-datalab-demo" ],
      "groups": {{ .groups | toJson}}
    }
    {{- end }}    
    {{- end -}}
  ],
  "groups": [
    {{- if .Values.demo.enabled -}}
    {
      "name": "demo",
      "path": "/demo"
    }
    {{- range .Values.demo.projects }}
    ,{
      "name": "{{ .name }}",
      "path": "/{{ .name }}"
    }
    {{- end }}    
    {{- end -}}
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
          "name": "groups",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-group-membership-mapper",
          "consentRequired": false,
          "config": {
            "full.path": "false",
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
        },
        {
          "name": "audience-vault-onyxia-client",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-audience-mapper",
          "consentRequired": false,
          "config": {
            "included.client.audience": "{{ .Values.onyxia.ui.env.OIDC_CLIENT_ID }}",
            "id.token.claim": "false",
            "access.token.claim": "true"
          }
        }
      ]
    },
    {
      "clientId": "ckan",
      "rootUrl": "https://ckan.clouddatalab.eu/",
      "adminUrl": "https://ckan.clouddatalab.eu/",
      "surrogateAuthRequired": false,
      "enabled": true,
      "alwaysDisplayInConsole": false,
      "clientAuthenticatorType": "client-secret",
      "secret": "{{ .Values.ckan.clientsecret }}",
      "redirectUris": [
        "https://ckan.clouddatalab.eu/*"
      ],
      "webOrigins": [
        "https://ckan.clouddatalab.eu"
      ],
      "notBefore": 0,
      "bearerOnly": false,
      "consentRequired": false,
      "standardFlowEnabled": true,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": true,
      "serviceAccountsEnabled": false,
      "publicClient": false,
      "frontchannelLogout": false,
      "protocol": "openid-connect",
      "attributes": {
        "oauth2.device.authorization.grant.enabled": "true"
      }
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
            "full.path": "false",
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
	  {{- if .Values.grafana.enabled -}}
	  ,
    {
      "clientId": "grafana",
      "rootUrl": "https://grafana.{{ .Values.domainName }}",
      "baseUrl": "",
      "enabled": true,
      "publicClient": true,
      "redirectUris": [
        "https://grafana.{{ .Values.domainName }}/*"
      ],
      "webOrigins": [
        "*"
      ],
      "attributes": {
        "oauth2.device.authorization.grant.enabled": "true",
        "use.refresh.tokens": "true"
      }
    }
    {{- end -}}
  ]
}
{{- end -}}

