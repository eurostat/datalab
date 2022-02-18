# Operating

To Operate the current version of the Data Lab it is necessary to have a good understanding of Kubernetes, Helm, and the Charts installed (i.e., MinIO, Vault, Prometheus, Grafana, Ckan, Apache Superset, and GitLab). This document looks to explain some nuances of the Data Lab, without going into deep explanation about concepts that are meant to be already understood.

## :warning: Disclaimer :warning:
The documentation is still in development and may be subject to future changes.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Platform State](#platform-state)
3. [User Groups](#user-groups)
4. [Monitoring](#monitoring)
5. [Corrective Actions](#corrective-actions)

## Prerequisites

Depending on where your Kubernetes cluster is deployed, it is necessary to have a way of autentication with the Kubernetes API with an elevated permissions role (i.e., cluster administrator). With that given, the main tools used for operating should be: 
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- Grafana (deployed with the Data Lab)

## Platform state

After the Data Lab installation as guided in the [deployment document](./DEPLOYMENT.md), there should be at least one Chart in the Kubernetes cluster. With the previously installed tools, running a `helm ls` in the installation namespace should produce a similar log:
```bash
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
datalab                 default         1               xxxx-xx-xx xx:xx:xx.xxxxxxx +0000 UTC   deployed        datalab-0.4.0           0.1.0  
``` 

If the status is not `deployed`, some trouble shooting is offered:
- The Helm Chart install timed out with the flag `--wait`, make sure to [increase the timeout](https://helm.sh/docs/intro/using_helm/#helpful-options-for-installupgraderollback) to allow the completion of the Vault operation first with the flag `--timeout`.
- Ensure to activate the Vault pod with the `vault operator init` for the pod to be considered ready.
- PostgreSQL dependency conflict. Ensure to not overlap postgreSQL installations that come from the Charts sub-dependencies (i.e., Keycloak, Ckan and Apache Superset).

After successful installation, take into consideration an important `cronjob` that runs (`kubectl get cj`): 
```bash
NAME                       SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
policy-update-cronjob      * */12 * * *   False     0        xx              xx
```

This job will ensure that the groups given in Keycloak will be properly translated to policies, the schedule should be set with the volatility of the project changing in mind, but if needed, can be triggered manually:
```bash
kubectl create job --from=cronjob/policy-update-cronjob <job-name>
```
Note that, if your group management is not done in Keycloak however, it is necessary to update the policies on MinIO through other methods, refer to the section below for a more detailed explanation.

<br>

With `kubectl` it is possible to get the current state of the platform. For example, with a full deployment of the Data Lab, the command `kubectl get pods` in the namespace where there it is deployed should produce a result similar to this:
```bash
NAME                                               READY   STATUS      RESTARTS   AGE  
ckan-<random-str>                                  1/1     Running     1          xx
ckan-email-notifications-<random-str>              0/1     Completed   0          xx
ckan-email-notifications-<random-str>              0/1     Completed   0          xx
ckan-email-notifications-<random-str>              0/1     Completed   0          xx
<release>-grafana-<random-str>                     2/2     Running     0          xx
<release>-keycloak-0                               2/2     Running     0          xx
<release>-kube-state-metrics-<random-str>          1/1     Running     0          xx
<release>-minio-<random-str>                       1/1     Running     0          xx
<release>-onyxia-api-<random-str>                  1/1     Running     0          xx
<release>-onyxia-ui-<random-str>                   1/1     Running     0          xx
<release>-prometheus-alertmanager-<random-str>     2/2     Running     0          xx
<release>-prometheus-node-exporter-<random-str>    1/1     Running     0          xx
<release>-prometheus-node-exporter-<random-str>    1/1     Running     0          xx
<release>-prometheus-node-exporter-<random-str>    1/1     Running     0          xx
<release>-prometheus-pushgateway-<random-str>      1/1     Running     0          xx
<release>-prometheus-server-<random-str>           2/2     Running     0          xx
<release>-redis-master-0                           1/1     Running     0          xx
<release>-superset-<random-str>                    1/1     Running     0          xx
<release>-superset-worker-<random-str>             1/1     Running     0          xx
<release>-user-notification-<random-str>           1/1     Running     0          xx
<release>-vault-0                                  1/1     Running     0          xx
<release>-vault-agent-injector-<random-str>        1/1     Running     0          xx
<release>-zookeeper-0                              1/1     Running     0          xx
datapusher-<random-str>                            1/1     Running     0          xx
policy-update-cronjob-<random-str>                 0/1     Completed   0          xx
postgres-0                                         1/1     Running     0          xx
psql-init-<random-str>                             0/1     Completed   0          xx
redis-master-0                                     1/1     Running     0          xx
solr-0                                             1/1     Running     0          xx
solr-init-<random-str>                             0/1     Completed   0          xx
superset-init-db-<random-str>                      0/1     Completed   0          xx
``` 

## User Groups


Users can be grouped into projects, where service instances are shared (e.g., an ubuntu or a jupyter). The form to transmit that grouping to Onyxia is through the `groups` claim in the `jwt` token. However, to ensure the same kind of sharing is also enabled in closely coupled services (i.e., MinIO and Vault), it is necessary to update their policies.

### MinIO

[MinIO STS](https://docs.min.io/docs/minio-sts-quickstart-guide.html) policies are the basis of this dynamic resource sharing. Note that you have to ensure the name of the policy you have in place is given as a claim in the `jwt`, which per default should be the `policy` claim.

To update policies on MinIO has a cronjob that can be triggered manually if needed to automatically syncronise policies with the groups existent in Keycloak. However, if another identity provider is used, the steps to update the policies manually on MinIO are the following:

1. Create a policy with your own groups, taking into account you need to keep the base policy with the `jwt:preferred_username`, and that the bucket prefix for groups must match the one you have in the `regions.json` definition in the Onyxia installation (default is `projet-`):
```json
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
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::projet-<group-name>",
                "arn:aws:s3:::projet-<group-name>/*"
            ],
            "Condition": {
                "StringEquals": {
                    "jwt:preferred_username": ["<member-one>", "<member-two>", "<etc>"]
                        
                }
            }
        }
    ]
}
```
2. Copy your policy into the MinIO pod and apply it as an admin, ensuring that the policy name is the same present in your `jwt` tokens (e.g., `policy` claim has hardcoded value `stsonly`), and given the pod id:
```bash
kubectl cp <policy-document>.json <release-name>-minio-<random-generated-string>:/tmp/<policy-document>.json
kubectl exec -it <release-name>-minio-<random-generated-string> -- /bin/sh
# within the pod
mc admin policy add local stsonly /tmp/policy.json
mc admin service restart local
```

### Vault

To update the policies on Vault a [helper script](../charts/datalab/helpers/vault-groups-config.sh) is present on the Chart, where policies, groups and group aliases are set-up in order to apply the group policies for token creation. The script is also presented here with the note that it is needed to set a `VAULT_ADDR`, `VAULT_TOKEN` and a list of groups to add:
```bash
# To associate groups with the jwt provider use the API to:
# 1. Create a policy for the group
# 2. Create a group
# 3. Associate alias that matches group in token
# (pre-defined in the role cration) Use the groups_claim from the token in the role

# With VAULT_TOKEN and VAULT_ADDR in environment variables given when calling this script or:
# export VAULT_TOKEN = <root-token>
# export VAULT_ADDR = vault.example.test

# (pre-step, jwt acessor) 2.
JWT_ACESSOR=$(curl --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/sys/auth | jq -r '.["jwt/"].accessor')

# Given a list of existing group ids (written the same way as in Keycloak)
# ************ IMPORTANT TODO ************
declare -a GROUP_LIST=("<your>" "<group>" "<list>")
# ************ IMPORTANT TODO ************

for GROUP in "${GROUP_LIST[@]}"
do

# 1. 
tee payload-pol.json <<EOF 
{
    "policy": "path \"onyxia-kv/projet-$GROUP/*\" {\n capabilities = [\"create\",\"update\",\"read\",\"delete\",\"list\"]\n}\n\n path \"onyxia-kv/data/projet-$GROUP/*\" {\n capabilities = [\"create\",\"update\",\"read\"]\n}\n\n path \"onyxia-kv/metadata/projet-$GROUP/*\" {\n capabilities = [\"delete\", \"list\", \"read\"]\n }"
}
EOF

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request PUT \
   --data @payload-pol.json \
   $VAULT_ADDR/v1/sys/policies/acl/$GROUP

rm payload-pol.json


# 2.
tee payload-grp.json <<EOF
{
  "name": "$GROUP",
  "policies": ["$GROUP"],
  "type": "external",
  "metadata": {
    "origin": "onyxia"
  }
}
EOF

GROUP_ID=$(curl --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-grp.json \
    $VAULT_ADDR/v1/identity/group | jq -r ".data.id")

rm payload-grp.json


# 3.
tee payload-grp-alias.json <<EOF
{
  "canonical_id": "$GROUP_ID",
  "mount_accessor": "$JWT_ACESSOR",
  "name": "$GROUP"
}
EOF

curl --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-grp-alias.json \
    $VAULT_ADDR/v1/identity/group-alias 

rm payload-grp-alias.json

done

```

## Monitoring

The monitoring stack of the Data Lab, Prometheus and Grafana, allow both users and platform administrators to monitor the platform usage. It is also possible for the platform administrators, through a Grafana admin access, to create new dashboards based on the available Prometheus metrics, or, if needed, to add new [metric exporters](https://prometheus.io/docs/instrumenting/writing_exporters/) to monitor other parts of the platform.

### Metrics

The existing dashboards use metrics collected through:
- [Node exporter metrics](https://github.com/prometheus/node_exporter)
- [Kube state metrics](https://github.com/kubernetes/kube-state-metrics)
- [MinIO metrics](https://docs.min.io/minio/baremetal/monitoring/metrics-alerts/minio-metrics-and-alerts.html)
- [Keycloak metrics](https://github.com/aerogear/keycloak-metrics-spi)
- [Custom Keycloak metrics sidecar](../images/keycloak-metrics-sidecar/)

Note that to have the full functionality of the pre-configured dashboards, it is necessary to build and add the [Custom Keycloak metrics sidecar](../images/keycloak-metrics-sidecar/), similar to the example image. It is also possible to configure new [metric exporters](https://prometheus.io/docs/instrumenting/writing_exporters/) as long as you flag to Prometheus, e.g., with annotations, a place to scrap them.


### Dashboards
Users have two pre-set dashboards meant for self-monitoring, that will allow them to understand the scope of their resource consumption and do corrective measures on their own environment. The dashboards are built through Configmaps, [user-service-dashboard](../charts/datalab/templates/grafana-user-service-dashboard-cm.yaml) and [user-s3-storage-dashboard](../charts/datalab/templates/grafana-user-s3-storage-dashboard-cm.yaml), and are for Kubernetes resources (CPU, Memory and Network) and MinIO storage respectively. They can be accessed in static dashboard links through your chosen domain name that should also be in the `regions` definition of your Onyxia dependency, `https://grafana.<your-domain-domain>/d/kYYgRWBMz/users-services?orgId=1` and `https://grafana.<your-domain-domain>/d/PhCwEJkMz/user-s3-storage?orgId=1`. As a platform administrator, if the desire is to change the metrics users can see as Viewers, the Configmap themselves have to be changed.

Other dashboards to monitor the platform are also available and reachable for the platform administrator, namely, the [admin-dashboard](../charts/datalab/templates/grafana-admin-dashboard-cm.yaml), to give an overview over resource consumption, and the [inactivity-dashboard](../charts/datalab/templates/grafana-inactivity-dashboard-cm.yaml), to give a notion of user activity to the administrator. The second dashboard is dependent on activity metrics generated by the Keycloak metrics side car, that can be built in accordance to the given example in [/images/keycloak-metrics-sidecar/](../images/keycloak-metrics-sidecar/) and configured in the `values.yaml` of the Chart.

New dashboards to provide a better monitoring experience can also be created either through Configmaps, as part of the infrastructure, or manually with administrator rights in the Grafana interface.

### Notifications
Notifications are managed through the [Prometheus Altermanager](https://github.com/prometheus/alertmanager), so, to configure its behaviour it is necessary to fill in the `values.yaml` on the `prometheus.alertmanagerFiles.alertmanager.yml` value. The behaviour can also be configured after installation in the Configmap `<release-name>-prometheus-alertmanager`, with special attention that an SMTP server configuration is **REQUIRED** if any kind of email notification is desired.

Notifications come from alerts, that are triggered through [Prometheus alert rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/), which can be configured pre-deployment on the [prometheus-rules](../charts/datalab/templates/prometheus-rules-cm.yaml) Configmap, or after installation in the `prometheus-alerts` Configmap. A number of consumption and activity alerts are already pre-configured, and their thresholds can be defined in the `values.yaml`, as specified in the [Chart README](../charts/datalab/README.md). Note that the latter needs activiy metrics generated by the Keycloak metrics side car.

User-bound notifications can also be configured using an image similar to the one presented in [/images/user-notification-container/](../images/user-notification-container/). The objective of this container is to pick-up the [Prometheus webhook](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config) that has to be configured in the `alertmanager.yml` and, based on the namespace in which the rule was triggered, fetch the user email and send a notification to them. For more information on how to deploy this feature refer to the [DEPLOYMENT](./DEPLOYMENT.md) document and the [Chart README](../charts/datalab/README.md).


## Corrective Actions

As a platform administrator with elevated capabilities on the Kubernetes API, it is possible to do corrective actions depending on the monitoring status. Presented here are methods and suggestions that are up to the platform administrator criteria to decide their adoption.

When a user is over-consuming or leaving inactive resources, they should be notified (either automatically or by the platform administrator), and if no actions are taken within decided time periods the platform administrator can take action. Since services are created for users through Chart installations, the easiest way to disable a service is to uninstall it, for example:
```bash
# based on `helm ls -n user-<username>` find the `<service-id>` that triggered the alarm
helm delete <service-id> -n user-<username>
```

However, overcomsumption rules are triggered by a sum of resources, so further investigation to know which services are more resource-heavy or less important to have them running is due when this kind of rules are fired. For example:
```bash
# based on a user pod-id  from kubectl get pods -n user-<username>
kubectl describe pod <pod-id> -n user-<username>
```
The `Requests` and `Limits` section in the output can indicate how many resources are asked to be allocated to that pod, more info on the official Kubernetes documentation for [Requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).
