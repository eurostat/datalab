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
  "adminEventsEnabled": true,
  "adminEventsDetailsEnabled": true,
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
  "requiredCredentials": [
    "password"
  ],
  "users": [
    {{- if .Values.demo.enabled -}}
    {
      "username" : "demo",
      "firstName": "demo",
      "lastName": "demo",
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
      "firstName": "{{ .firstname }}",
      "lastName": "{{ .lastname }}",
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
        "name": "ROLE_ADMIN",
        "description": "Jhipster administrator role"
      },
      {
        "name": "ROLE_USER",
        "description": "Jhipster user role"
      },
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
  "defaultGroups": [
    "/demo"
  ],
  "clients": [
    {
      "clientId": "{{ .Values.onyxia.ui.env.REACT_APP_KEYCLOAK_CLIENT_ID }}",
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
            "included.client.audience": "{{ .Values.onyxia.ui.env.REACT_APP_KEYCLOAK_CLIENT_ID }}",
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
      },
      "protocolMappers": [
        {
          "name": "roles",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-realm-role-mapper",
          "consentRequired": false,
          "config": {
            "multivalued": "true",
            "userinfo.token.claim": "true",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "roles",
            "jsonType.label": "String"
          }
        }
      ]
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
	  {{- if .Values.dminio.enabled -}}
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
    ,
    {
      "clientId": "gitlab-client",
      "rootUrl": "https://gitlab.{{ .Values.domainName }}",
      "adminUrl": "https://gitlab.{{ .Values.domainName }}",
      "surrogateAuthRequired": false,
      "enabled": true,
      "alwaysDisplayInConsole": false,
      "clientAuthenticatorType": "client-secret",
      "secret": "7537870f-8e20-4065-a262-5da556549d02",
      "redirectUris": [
        "https://gitlab.{{ .Values.domainName }}/*"
      ],
      "webOrigins": [
        "https://gitlab.{{ .Values.domainName }}"
      ],
      "notBefore": 0,
      "bearerOnly": false,
      "consentRequired": false,
      "standardFlowEnabled": true,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": true,
      "serviceAccountsEnabled": true,
      "authorizationServicesEnabled": true,
      "publicClient": false,
      "frontchannelLogout": false,
      "protocol": "openid-connect",
      "attributes": {
        "saml.assertion.signature": "false",
        "id.token.as.detached.signature": "false",
        "saml.multivalued.roles": "false",
        "saml.force.post.binding": "false",
        "saml.encrypt": "false",
        "oauth2.device.authorization.grant.enabled": "true",
        "backchannel.logout.revoke.offline.tokens": "false",
        "saml.server.signature": "false",
        "saml.server.signature.keyinfo.ext": "false",
        "use.refresh.tokens": "true",
        "exclude.session.state.from.auth.response": "false",
        "oidc.ciba.grant.enabled": "false",
        "saml.artifact.binding": "false",
        "backchannel.logout.session.required": "true",
        "client_credentials.use_refresh_token": "false",
        "saml_force_name_id_format": "false",
        "saml.client.signature": "false",
        "tls.client.certificate.bound.access.tokens": "false",
        "require.pushed.authorization.requests": "false",
        "saml.authnstatement": "false",
        "display.on.consent.screen": "false",
        "saml.onetimeuse.condition": "false"
      },
      "authenticationFlowBindingOverrides": {},
      "fullScopeAllowed": true,
      "nodeReRegistrationTimeout": -1,
      "protocolMappers": [
        {
          "id": "0ff50c82-c27a-49e5-a408-faff059ba857",
          "name": "Client Host",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usersessionmodel-note-mapper",
          "consentRequired": false,
          "config": {
            "user.session.note": "clientHost",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "clientHost",
            "jsonType.label": "String"
          }
        },
        {
          "id": "fd211a8d-8741-4d7e-b2fa-9e7940e3cb2a",
          "name": "Client ID",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usersessionmodel-note-mapper",
          "consentRequired": false,
          "config": {
            "user.session.note": "clientId",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "clientId",
            "jsonType.label": "String"
          }
        },
        {
          "id": "c564c7f8-56f2-479d-bdca-174a3e6b7d7c",
          "name": "Client IP Address",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usersessionmodel-note-mapper",
          "consentRequired": false,
          "config": {
            "user.session.note": "clientAddress",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "clientAddress",
            "jsonType.label": "String"
          }
        }
      ],
      "defaultClientScopes": [
        "web-origins",
        "roles",
        "profile",
        "email"
      ],
      "optionalClientScopes": [
        "address",
        "phone",
        "offline_access",
        "microprofile-jwt"
      ],
      "authorizationSettings": {
        "allowRemoteResourceManagement": true,
        "policyEnforcementMode": "ENFORCING",
        "resources": [
          {
            "name": "Default Resource",
            "type": "urn:gitlab-client:resources:default",
            "ownerManagedAccess": false,
            "attributes": {},
            "_id": "e5fde50d-9101-4a6e-b750-b09243496991",
            "uris": [
              "/*"
            ]
          }
        ],
        "policies": [
          {
            "id": "3a9607a3-b18f-412c-b6da-613cdf63a26e",
            "name": "Default Policy",
            "description": "A policy that grants access only for users within this realm",
            "type": "js",
            "logic": "POSITIVE",
            "decisionStrategy": "AFFIRMATIVE",
            "config": {
              "code": "// by default, grants any permission associated with this policy\n$evaluation.grant();\n"
            }
          },
          {
            "id": "8907de55-3077-44d7-b40a-11ff05f2d6ea",
            "name": "Default Permission",
            "description": "A permission that applies to the default resource type",
            "type": "resource",
            "logic": "POSITIVE",
            "decisionStrategy": "UNANIMOUS",
            "config": {
              "defaultResourceType": "urn:gitlab-client:resources:default",
              "applyPolicies": "[\"Default Policy\"]"
            }
          }
        ],
        "scopes": [],
        "decisionStrategy": "UNANIMOUS"
      }

    }
  ],
 "identityProviders": [
      {
          "alias": "eulogin_aws",
          "displayName": "Eulogin aws",
          "internalId": "193a71e0-7de3-4778-8efc-d0f32bd0c386",
          "providerId": "saml",
          "enabled": true,
          "updateProfileFirstLoginMode": "on",
          "trustEmail": false,
          "storeToken": false,
          "addReadTokenRoleOnCreate": false,
          "authenticateByDefault": false,
          "linkOnly": false,
          "firstBrokerLoginFlowAlias": "first broker login",
          "config": {
              "hideOnLoginPage": "",
              "validateSignature": "true",
              "samlXmlKeyNameTranformer": "KEY_ID",
              "signingCertificate": "MIIGTDCCBDSgAwIBAgIQf6S1b4HXSiW/sgxzIGqlIjANBgkqhkiG9w0BAQ0FADCBmTELMAkGA1UE\nBhMCQkUxETAPBgNVBAgMCEJydXNzZWxzMREwDwYDVQQHDAhCcnVzc2VsczEcMBoGA1UECgwTRXVy\nb3BlYW4gQ29tbWlzc2lvbjEOMAwGA1UECwwFRElHSVQxNjA0BgNVBAMMLUVDQVMgTW9jay1VcCBD\nZXJ0aWZpY2F0ZSBBdXRob3JpdHkgKERldiBPbmx5KTAeFw0yMDA2MDcxNjI1NDZaFw0yMzA2MDkx\nNjI1NDZaMIGWMQswCQYDVQQGEwJCRTERMA8GA1UEBwwIQnJ1c3NlbHMxHDAaBgNVBAoME0V1cm9w\nZWFuIENvbW1pc3Npb24xDjAMBgNVBAsMBURJR0lUMSwwKgYJKoZIhvcNAQkBFh15b3VyLmVjYXMu\nbW9ja3VwQGVjLmV1cm9wYS5ldTEYMBYGA1UEAwwPZWNhcy1tb2NrdXAtc3RzMIIBojANBgkqhkiG\n9w0BAQEFAAOCAY8AMIIBigKCAYEAvSS6tPnw/xGRtxvwwxfP9/dOEkjkZmeFtZ70/AGUn47pN9oT\n2uuWRjvE9XJxEVv/lSaOmGYwo70C8PuqZMrhPcipNLFittHK9VppiwQM7CW5EUPZW3aPEMMVLK2G\n7RtlR2M0qegAz9z7ieZPiIc6gH0niKxR3ZQn6nFOlX13ocpPLW8Riz051zx/bcLyN3EopC3FAICi\nTFjhlSeFBgIzC08ffIi9pmpavpK/C6MggnmTxaOLTvsXZk9LfT36skW/d0j7yaS/O6YfvXOf2XsP\nv1jsmDerMv0JvDgUO21P4W0RpdzN5bkyjPIYwfg2PgKMxgsAjUSh2ZNXHZugyKqK8/qPKmqSOhfy\nMXv8CRoSBasSRSM2h8tao1Gez9IhP6b5cwpOjvlJYcFQgWKt5SSISSVw5jpNFju4GGRxWeW4hGXI\nhwm5RsXGr2/NDgZ9IM+MpCfYWdWsGq2eBR8mISC+q7SS3J8hvBviQEz7RQaGQJgbOQOGgjgPR9Fb\nP8kN898lAgMBAAGjggEPMIIBCzAfBgNVHSMEGDAWgBRt6mwT2uzz7Nke1ZpunjOFtrqyVTAwBgNV\nHREEKTAnggZtb2NrdXCBHXlvdXIuZWNhcy5tb2NrdXBAZWMuZXVyb3BhLmV1MBEGCWCGSAGG+EIB\nAQQEAwIE8DALBgNVHQ8EBAMCBPAwHQYDVR0OBBYEFFmjQ61P3wmihukm2DhlxfW5FwWYMAkGA1Ud\nEwQCMAAwOwYDVR0lBDQwMgYIKwYBBQUHAwEGCCsGAQUFBwMCBggrBgEFBQcDAwYIKwYBBQUHAwQG\nCCsGAQUFBwMIMC8GA1UdHwQoMCYwJKAioCCGHmh0dHBzOi8vbW9ja3VwOjcwMDIvY2FzL2NhL2Ny\nbDANBgkqhkiG9w0BAQ0FAAOCAgEAZu4nV2vi2it9aGDsdR/FjBjOrar+YcmPvP4HoM7HdcgtcW8V\nLR/eH++mT8wIkm/eGeDTuZNzCkfW+u5K4vN6ku3t1PGdl6YbtNzxkI3ms8qtFAegvzIzEicsKxu4\na3/aEPLsdFEuQN21edm7BFUGwtLtuYNuYoYU/tl8tYVbEq9nEUm9Y0cC1gl1GB7buL3RVhNBUUv2\nBNy8ZECgjebxO0tPe9KA7mGXCCTC/rsee1H/bMmHiB4k621R3Y461Z3hAxmGlw2nOBINeDMP7YXA\n5qZqklqBxWPScYg2HVldGmv28hTqkUty8aWGDnUHVe7PPdSb4AoiVbYHzRDxo9sgTmhI3b3ILZCm\nXPGuwy/BT3uu4cE/qmCGQ/EM3s2xn3v3Yn783ZuT2ip19W2eZAgoKtDEbNgvxu7B0v1cdaLBgFQG\n0HyGfi6BsC/DqCleUvv7810DxWKsAYNpEIayzsPq1BaV0GBwnriylt4R/o1PiDNQPPkl0mZptSDx\nx0pVqPMzI3NSqu3RROrKX/G8UjUflgxntvewGLvgrPcrOe4lhyXUGtZFefWdVlamcNy6kn2LTrhw\n8Okg373shXS4cbHpSAW3ZCdd00arAdpQXcfVfPG79lGHFnux2zwnRoSYVP3RAUpeOvSXMLwe5jmK\n+XqKQMusinyBQ7f6PcCECD+kL10=",
              "postBindingLogout": "true",
              "nameIDPolicyFormat": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
              "postBindingResponse": "true",
              "singleLogoutServiceUrl": "https://eulogin-test.wihp.ecdp.tech.ec.europa.eu/cas/logout",
              "backchannelSupported": "",
              "signatureAlgorithm": "RSA_SHA256",
              "wantAssertionsEncrypted": "",
              "useJwksUrl": "true",
              "wantAssertionsSigned": "",
              "postBindingAuthnRequest": "true",
              "forceAuthn": "",
              "singleSignOnServiceUrl": "https://eulogin-test.wihp.ecdp.tech.ec.europa.eu/cas/login",
              "wantAuthnRequestsSigned": ""
          }
      }
  ]
}
{{- end -}}
