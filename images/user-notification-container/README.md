# user-notification-container

Container that will handle user destined notifications. It receives a post request from an Alertmanager webhook config and, based on the `exported_namespace` label associated with the alert, it fetches the user email on Keycloak to notify him by email of the alert triggered.