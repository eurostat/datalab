{{/* vim: set filetype=mustache: */}}

{{/*

*/}}
{{- define "datalab.superset.securitymanager" -}}
from flask_appbuilder.security.manager import AUTH_OID
from superset.security import SupersetSecurityManager
from flask_oidc import OpenIDConnect
from flask_appbuilder.security.views import AuthOIDView
from flask_login import login_user
from urllib.parse import quote
from flask_appbuilder.views import ModelView, SimpleFormView, expose
from flask import request, redirect
import logging

class OIDCSecurityManager(SupersetSecurityManager):

    def __init__(self, appbuilder):
        super(OIDCSecurityManager, self).__init__(appbuilder)
        if self.auth_type == AUTH_OID:
            self.oid = OpenIDConnect(self.appbuilder.get_app)
        self.authoidview = AuthOIDCView

class AuthOIDCView(AuthOIDView):

    @expose('/login/', methods=['GET', 'POST'])
    def login(self, flag=True):
        sm = self.appbuilder.sm
        oidc = sm.oid

        @self.appbuilder.sm.oid.require_login
        def handle_login():
            user = sm.auth_user_oid(oidc.user_getfield('email'))

            if user is None:
                info = oidc.user_getinfo(['preferred_username', 'given_name', 'family_name', 'email'])
                preferred_username = info.get('preferred_username')
                given_name = info.get('given_name')
                family_name = info.get('family_name')
                email = info.get('email')
                
                if not given_name:
                    given_name = email.split('@')[0]
                if not family_name:
                    family_name = email.split('@')[0]

                user = sm.add_user(preferred_username, given_name, family_name, email, sm.find_role('Admin'))

            login_user(user, remember=False, force=True)            
            return redirect(self.appbuilder.get_url_for_index.replace('http://', 'https://'))

        return handle_login()

    @expose('/logout/', methods=['GET', 'POST'])
    def logout(self):
        oidc = self.appbuilder.sm.oid

        oidc.logout()
        super(AuthOIDCView, self).logout()
        redirect_url = request.url_root.strip('/') + self.appbuilder.get_url_for_login

        return redirect(
            oidc.client_secrets.get('issuer') + '/protocol/openid-connect/logout?redirect_uri=' + quote(redirect_url))
{{- end -}}

{{- define "datalab.superset.enableoauth" -}}
from custom_sso_security_manager import  OIDCSecurityManager
from flask_appbuilder.security.manager import AUTH_OID, AUTH_REMOTE_USER, AUTH_DB, AUTH_LDAP, AUTH_OAUTH
import os
'''
---------------------------KEYCLOACK ----------------------------
'''
AUTH_TYPE = AUTH_OID
SECRET_KEY = {{ .Values.flasksecret | quote }}
OIDC_CLIENT_SECRETS = '/mnt/secret/client_secret.json'
OIDC_ID_TOKEN_COOKIE_SECURE = False
OIDC_REQUIRE_VERIFIED_EMAIL = False
OIDC_OPENID_REALM = 'datalab-demo'
OIDC_INTROSPECTION_AUTH_METHOD = 'client_secret_post'
CUSTOM_SECURITY_MANAGER = OIDCSecurityManager
AUTH_USER_REGISTRATION = True
AUTH_USER_REGISTRATION_ROLE = 'Gamma'
'''
--------------------------------------------------------------
'''
{{- end -}}
