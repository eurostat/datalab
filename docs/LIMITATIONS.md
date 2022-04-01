# Known Issues & Limitations

## General Issues

Taking out the central postgres for all services and choosing to launch multiple DBs takes a lot of changes to the `values.yaml`.

## Dev Issues

### Onyxia

No current relevant issues, apart from a current [Pull Request]((https://github.com/InseeFrLab/helm-charts-datascience/pull/48)) not yet accepted. 

### Keycloak

The user and group management UI may not be as functional as desired when adding multiple users/groups or even when managing user group membership. This process can be easier with the aid of a script to produce a JSON file that follows the Keycloak required file structure, and then simply importing this file into the right realm will add all necessary changes. 

### MinIO

Current script for policy update. It logs the Keycloak and MinIO API by the 1500th policy. It must be transformed into a reactive script, reactive to Keycloak's events. On user deleted/added update policies of groups where user was member, including the demo group (for private bucket policy). Also, update on membership of groups changing! And on username change. (?)

### Vault

Requires initialization to be done manually (this is not so much as an issue, as it is the normal (obligatory/required) workflow of Vault).

### Prometheus

ALerts in Inactive Instances use ingress to monitor the number of accesses in a period of time. Some instances, such as PostgreSQL, do not launch an ingress, so the admin will not receive any alerts on inactivity.

### Grafana

Users are limited to reading dashboards so they can't create their own.

### Ckan

Ckanext-oauth2 only works because the init postgres script creates the necessary table, which before was being created by the extension (now isn't and we dont know why yet). This should be better researched.

### PostgreSQL (optional)

No current relevant issues.

### Redis (optional)

No current relevant issues.

### Superset

For Superset the admin must take out the "write on databases" permission out of alpha role, once this action could not be automated. 

### Gitlab

Changing username or password won't redirect the user to Keycloak's user management page. Instead it will create a new instance of the same user in Gitlab's database. This will make it so that the user can keep loggin in throught the SSO feature, or through the Gitlab's normal login page, with the newly defined username and/or password.
