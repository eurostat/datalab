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
  "eventsEnabled": true,
  "eventsListeners": [
    "metrics-listener",
    "jboss-logging"
  ],
  "enabledEventTypes": [
    "UPDATE_CONSENT_ERROR",
    "SEND_RESET_PASSWORD",
    "GRANT_CONSENT",
    "VERIFY_PROFILE_ERROR",
    "UPDATE_TOTP",
    "REMOVE_TOTP",
    "REVOKE_GRANT",
    "LOGIN_ERROR",
    "CLIENT_LOGIN",
    "RESET_PASSWORD_ERROR",
    "IMPERSONATE_ERROR",
    "CODE_TO_TOKEN_ERROR",
    "CUSTOM_REQUIRED_ACTION",
    "OAUTH2_DEVICE_CODE_TO_TOKEN_ERROR",
    "RESTART_AUTHENTICATION",
    "UPDATE_PROFILE_ERROR",
    "IMPERSONATE",
    "LOGIN",
    "UPDATE_PASSWORD_ERROR",
    "OAUTH2_DEVICE_VERIFY_USER_CODE",
    "CLIENT_INITIATED_ACCOUNT_LINKING",
    "TOKEN_EXCHANGE",
    "REGISTER",
    "LOGOUT",
    "AUTHREQID_TO_TOKEN",
    "DELETE_ACCOUNT_ERROR",
    "CLIENT_REGISTER",
    "IDENTITY_PROVIDER_LINK_ACCOUNT",
    "UPDATE_PASSWORD",
    "DELETE_ACCOUNT",
    "FEDERATED_IDENTITY_LINK_ERROR",
    "CLIENT_DELETE",
    "IDENTITY_PROVIDER_FIRST_LOGIN",
    "VERIFY_EMAIL",
    "CLIENT_DELETE_ERROR",
    "CLIENT_LOGIN_ERROR",
    "RESTART_AUTHENTICATION_ERROR",
    "REMOVE_FEDERATED_IDENTITY_ERROR",
    "EXECUTE_ACTIONS",
    "TOKEN_EXCHANGE_ERROR",
    "PERMISSION_TOKEN",
    "SEND_IDENTITY_PROVIDER_LINK_ERROR",
    "EXECUTE_ACTION_TOKEN_ERROR",
    "SEND_VERIFY_EMAIL",
    "OAUTH2_DEVICE_AUTH",
    "EXECUTE_ACTIONS_ERROR",
    "REMOVE_FEDERATED_IDENTITY",
    "OAUTH2_DEVICE_CODE_TO_TOKEN",
    "IDENTITY_PROVIDER_POST_LOGIN",
    "IDENTITY_PROVIDER_LINK_ACCOUNT_ERROR",
    "UPDATE_EMAIL",
    "OAUTH2_DEVICE_VERIFY_USER_CODE_ERROR",
    "REGISTER_ERROR",
    "REVOKE_GRANT_ERROR",
    "LOGOUT_ERROR",
    "UPDATE_EMAIL_ERROR",
    "EXECUTE_ACTION_TOKEN",
    "CLIENT_UPDATE_ERROR",
    "UPDATE_PROFILE",
    "AUTHREQID_TO_TOKEN_ERROR",
    "FEDERATED_IDENTITY_LINK",
    "CLIENT_REGISTER_ERROR",
    "SEND_VERIFY_EMAIL_ERROR",
    "SEND_IDENTITY_PROVIDER_LINK",
    "RESET_PASSWORD",
    "CLIENT_INITIATED_ACCOUNT_LINKING_ERROR",
    "OAUTH2_DEVICE_AUTH_ERROR",
    "UPDATE_CONSENT",
    "REMOVE_TOTP_ERROR",
    "VERIFY_EMAIL_ERROR",
    "SEND_RESET_PASSWORD_ERROR",
    "CLIENT_UPDATE",
    "IDENTITY_PROVIDER_POST_LOGIN_ERROR",
    "CUSTOM_REQUIRED_ACTION_ERROR",
    "UPDATE_TOTP_ERROR",
    "CODE_TO_TOKEN",
    "VERIFY_PROFILE",
    "GRANT_CONSENT_ERROR",
    "IDENTITY_PROVIDER_FIRST_LOGIN_ERROR"
  ],
  "adminEventsEnabled": false,
  "adminEventsDetailsEnabled": false,
  "requiredCredentials": [
    "password"
  ],
  "users": [
    {{- if .Values.demo.enabled -}}
    {
      "username" : "demo",
      "enabled": true,
      "email": "demo@example-demo.test",
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
      "rootUrl": "https://ckan.{{ .Values.domainName }}/",
      "adminUrl": "https://ckan.{{ .Values.domainName }}/",
      "surrogateAuthRequired": false,
      "enabled": true,
      "alwaysDisplayInConsole": false,
      "clientAuthenticatorType": "client-secret",
      "secret": "{{ .Values.ckan.clientsecret }}",
      "redirectUris": [
        "https://ckan.{{ .Values.domainName }}/*"
      ],
      "webOrigins": [
        "https://ckan.{{ .Values.domainName }}"
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
    },
    {
      "clientId": "apache-superset",
      "rootUrl": "https://apache-superset.{{ .Values.domainName }}/",
      "adminUrl": "https://apache-superset.{{ .Values.domainName }}/",
      "surrogateAuthRequired": false,
      "enabled": true,
      "alwaysDisplayInConsole": false,
      "clientAuthenticatorType": "client-secret",
      "secret": "{{ .Values.superset.clientsecret }}",
      "redirectUris": [
        "https://apache-superset.{{ .Values.domainName }}/*"
      ],
      "webOrigins": [
        "http://apache-superset.{{ .Values.domainName }}",
        "https://apache-superset.{{ .Values.domainName }}"
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
