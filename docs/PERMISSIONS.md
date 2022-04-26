# Access Control List (Permissions and Roles)

Along all platforms integrated in this Data Lab there was some Access Control List implemented. In this document, the ACL features that were made available will be enumerated and described.

## Keycloak

While Keycloak is the central authentication management, this management UI is only accessible by admin entities. At this time, only one admin account is being configured and its credentials combination are present in the `values.yaml` file.

```yaml
kcUser: admin
kcPassword: admin
extraEnv: |
    ...
    - name: KEYCLOAK_USER
      value: {{ .Values.kcUser }}
    - name: KEYCLOAK_PASSWORD
      value: {{ .Values.kcPassword }}
```

Apart from the admin access, no other users have access to the interface.

## MinIO

MinIO only has authentication through Keycloak SSO. The permissions are the same across all users, only differing according to the groups a user is member of. So, each user has permissions to:

- create a bucket with its own username as name, and manage all objects inside it
- manage all objects inside the folder with its own username as name, inside the previously created `public-bucket`
- create a bucket with the group's name where the user is a member of, and manage all objects inside it

These permissions are all managed through the MinIO policies, which are updated by the cronjob script within the Kubernetes cluster.

## Onyxia

In Onyxia all users have exactly the same permissions, which are access to their own namespace within the Kubernetes environment, meaning they can control all Kubernetes resources in their namespace. However, there was the need to have a way of accessing all Kubernetes resources from all namespaces for a administrative management of the cluster, and there's where Kubernetes-Dashboard comes in.

## Vault

Vault has the same permissions across all users, so each user has access to only their secrets. 

## Grafana

Grafana has Keycloak's SSO for authentication, but there's also the option to login as admin. At this stage, the only difference is that the admin is able to create and save new dashboards, while a normal user is only able to consult the already existing dashboards.

```yaml
# (TODO) Place your own admin credentials here
adminUser: admin
adminPassword: strongpassword
```

It would be desireable that according to these roles, these users could consult different dashboards, meaning a normal user shouldn't have access to some of the admin dashboards, but this feature isn't implemented yet.

## Ckan

Ckan takes advantage of Keycloak's SSO for authentication, and it also reads the roles a user has in Keycloak. If a user has the role of `admin` (this role can be configured when building the Ckan docker image), then it will be promoted to admin in Keyclaok. The admin will be able to create organizations, groups and share datasets.

## Superset

Superset also takes advantage of Keycloak's SSO for authentication. Superset can be set to give specific roles to specific users' usernames. These usernames can be set from the `values.yaml` file:

```yaml
adminList: ["demo"]
alphaList: ["jondoe"]
```

With the aid of this functionality, we were able to separate Superset's user by 3 different roles:

- Admin: Can grant any role to any user, and even change the permissions within each role
- Alpha: Can create new database connections, and set the usage for reading or writing purposes
- Gamma: Can use any available database, but cannot create new database connections (default role)

## Gitlab

Gitlab uses Keycloak's SSO for authentication, and grants the same permissions to all users. Originally, there's only one admin user in Gitlab, which has access to all users, all repositories and all other resources within Gitlab. The admin user can also grant its own role to other users, which will become admins.

```bash
> kubectl get secrets
NAME                                             TYPE                                  DATA   AGE
...
datalab-gitlab-initial-root-password
...

> kubectl get secret datalab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 --decode
******
```

## Kubernetes-Dashboard

The Kubernetes-Dashboard has only one way of being accessed, and that is through the admin token. This platform is only directed to admin access because it grants permissions to all Kubernetes resources within the Kubernetes cluster. The way to obtain the credentials for admin login can be found in the [Operating](./OPERATING.md) file, in the Interactive Operations section.