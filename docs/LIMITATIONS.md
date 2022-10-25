# Known Issues & Limitations

## General Issues

Taking out the central postgres for all services and choosing to launch multiple DBs takes a lot of changes to the `values.yaml`.

## Deployment Issues
We built a single Helm chart to deploy all the components of the Data Lab at once. Specific version of each of these components have been specified in the Chart.yaml file, to ensure that all versions work well together. Hence, separate update of a specific component is not posible.

The use of `helm update` or `helm upgrade` is not possible in this context.

In a production context, we would recommend to have a separate chart for each component to ensure more flexibility.

## Dev Issues

### Onyxia

No current relevant issues, apart from a current [Pull Request]((https://github.com/InseeFrLab/helm-charts-datascience/pull/48)) not yet accepted. 

### Keycloak

The user and group management UI may not be as functional as desired when adding multiple users/groups or even when managing user group membership. This process can be easier with the aid of a script to produce a JSON file that follows the Keycloak required file structure, and then simply importing this file into the right realm will add all necessary changes. 

### MinIO

MinIO policies limits are no longer an issue. By having a script that updates policies according to Keycloak's admin events, the MinIO policies can keep up with dozens of thousands of users. After stress testing, a limit where this feature was compromised was not found. Either way, it is still **not** advised to make all actions at once, meaning the user creation and deletion, groups creation, update and deletion, plus group membership creation and deletion, should not be all done at once, but in batches. Theses batches should consist of around hundreds of actions to ensure the expected behaviour of this feature. Each batch is executed according to the `autoUpdatePolicy.schedule` value in the `values.yaml` file, which can easily be configured.

MinIO has still one known limitation on the Data Lab installation. MinIO will most times be wrongly configured with Keycloak's SSO, once it starts and stops looking for an SSO provider, before Keycloak is fully ready. This issue is difficult to manage once these processes are intrinsic to the MinIO image, so the solution of creating a new MinIO image would be arduous and time-consuming. On that account, we opted to compromise the user with another command to run while initializing the Data Lab for a simpler fix, which is to restart the MinIO deployment with the following command:

```bash
> kubectl rollout restart deploy datalab-dminio 
``` 

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
