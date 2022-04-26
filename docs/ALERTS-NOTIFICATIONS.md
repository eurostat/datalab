# Alerts and Notifications
Notifications are managed through the [Prometheus Altermanager](https://github.com/prometheus/alertmanager). As we'll see bellow, to configure its behaviour it is necessary to fill in the [values.yaml](../charts/datalab/values.yaml) on the `prometheus.alertmanagerFiles.alertmanager.yml` values before installing the Datalab or it can also be configured after the installation in the Configmap `<release-name>-prometheus-alertmanager`. **NOTE** that an SMTP server configuration is **REQUIRED** if any kind of email notification is desired. For more details on it, checkout the [Chart README](../charts/datalab/README.md) in the Prometheus section.

<br>

## Alerts

Notifications come from alerts, that are triggered through Prometheus alert rules.
These alerts are created in the file [prometheus-rules-cm.yaml](../charts/datalab/templates/prometheus-rules-cm.yaml) that creates the `prometheus-alerts ` configmap, and can be changed in this file before the deployment. 
<br>
Alternatively they can be changed after the deployment by running the following command:
`kubectl edit cm/prometheus-alerts`.

<br>

## Thresholds

These alerts are related to user's consumption and activity and each alert's threshold can be defined in the file [values.yaml](../charts/datalab/values.yaml), as specified in the [Chart README](../charts/datalab/README.md). 
<br>
There, in the section `alertThresholds`, as in the bellow code snippet, one can change the time period of each alert, to a desire value, in different units such as second(s), minutes(m), hours(h) or days(d).

```
alertThresholds:
  inactivityPeriod: 15d
  CpuRequestQuota: 0.5
  MemRequestQuota: 4
  CpuLimitsQuota: 30
  MemLimitsQuota: 64
  inactivityPeriodTypeDB: 30d
  inactivityPeriodTypeNormal: 15d
  inactivityPeriodAllInstances: 60d
```

Moreover, by executing the command `kubectl edit cm/prometheus-alerts`, it is also possible to change these values, after the deployment has been done.
<br>
For more information on the meaning of each alert's threshold, go over the correspondent section in the [Chart README](../charts/datalab/README.md).

</br>

## Accessing Prometheus

When the Datalab is up and running, alerts can be seen working by accessing the Prometheus UI.
For that, in the AWS CLI one should run the following command:
`kubectl port-forward svc/<release-name>-dprometheus-server 8080:80`

If the response is `Forwarding from 127.0.0.1:8080 -> 9090`, then just open the browser and browse `localhost:8080`.
<br>In the section “Alerts”, there's the list of all alerts as well as detailed information of each one, such as the query expression, name, annotations and state – inactive, pending or firing.


</br>

## Setting the notification’s email

The email address that will receive the notifications can be set in the [values.yaml](../charts/datalab/values.yaml) file, in the `prometheus.alertmanagerFiles.alertmanager.yml` section. In this section set the desired receiver email in the `receivers.email_configs.to` field:

```
receivers:
    - name: default-receiver
      email_configs:
        - to: email@example.test
```

However if one wants to change the receiver’s email after deployment, just run the following command and edit the same field directly on the file that opens up:
`kubectl edit cm/<release-name>-dprometheus-alertmanager`	

</br>

User-bound notifications can also be configured using an image similar to the one presented in [user-notification-container](../images/user-notification-container/). The objective of this container is to pick-up the [Prometheus webhook](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config) that has to be configured in the `alertmanager.yml` and, based on the namespace in which the rule was triggered, fetch the user email and send a notification to them. For more information on how to deploy this feature refer to the [DEPLOYMENT](./DEPLOYMENT.md) document and the [Chart README](../charts/datalab/README.md).
