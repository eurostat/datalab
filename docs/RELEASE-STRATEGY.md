# Release Strategy

This document will describe how to proceed in order to release new versions of the chart as the chart (source code) is updated. There will be two ways described below, one done manually and another one automated with the help of Github workflows. Furthermore, a reliable and useful method to produce a `changelog` document will also be described. 

1. Manual
2. Github Workflows
3. Changelog

## Manual

To update and release the chart manually, the procedure is quite simple. After having all alterations and updates done to the chart (source code), it is only needed to update the chart version in the file `chart.yaml`, inside the `datalab` directory. Now, the chart is ready to be released and for this  any kind of public bucket can be used. [Here](https://helm.sh/docs/topics/chart_repository/) is a list of buckets that can be used, and how to implement the chart repository according to the original helm documentation.

The most common way to proceed, would be to make use of [`chart-releaser`](https://github.com/helm/chart-releaser), to automatically compress the chart and index all charts and/or chart versions in a `index.yaml` file for the organization of the used bucket.

## Github Workflows

To make all these steps automated, we will show the example using Github Workflows. This process can also be consulted [here](https://helm.sh/docs/howto/chart_releaser_action/), in the original helm documentation.

First, we would need to have a new empty branch created, and associate the Github Pages setting to this branch. After, in the main (master) branch, the workflow should be added.

```yml
name: Release Charts

on:
  push:
    branches:
      - main

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Configure Git
        run: |
          git config user.name "$GITHUB_ACTOR"
          git config user.email "$GITHUB_ACTOR@users.noreply.github.com"
      - name: Run chart-releaser
        uses: helm/chart-releaser-action@v1.1.0
        env:
          CR_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
```

> The above configuration uses @helm/chart-releaser-action to turn your GitHub project into a self-hosted Helm chart repo. It does this - during every push to main - by checking each chart in your project, and whenever there's a new chart version, creates a corresponding GitHub release named for the chart version, adds Helm chart artifacts to the release, and creates or updates an index.yaml file with metadata about those releases, which is then hosted on GitHub pages.

## Changelog

The `Changelog` file will store records of all version of a chart, and what were the updates made in each one. Once this chart uses so many external open source charts, one of the main records to keep track of would be which versions of these external charts are being used.

| Chart           | Version       | Source        |
| ----------------|---------------|---------------|
| Keycloak        | 15.1.0        | https://codecentric.github.io/helm-charts |
| MinIO           | 10.1.12       | https://charts.bitnami.com/bitnami        |
| Onyxia          | 2.0.0         | https://inseefrlab.github.io/helm-charts  |
| Vault           | 0.18.0        | https://helm.releases.hashicorp.com       |
| Prometheus      | 15.0.1        | https://prometheus-community.github.io/helm-charts  |
| Grafana         | 6.17.10       | https://grafana.github.io/helm-charts     |
| PostgreSQL      | 10.13.8       | https://charts.bitnami.com/bitnami        |
| Ckan            | 1.0.1         | https://keitaro-charts.storage.googleapis.com  |
| Apache-Superset | 2.0.0         | https://apache.github.io/superset         |
| Redis           | 16.1.0        | https://charts.bitnami.com/bitnami        |
| Gitlab          | 5.7.0         | https://charts.gitlab.io                  |
| Kubernetes-Dashboard | 2.5.0        | https://kubernetes.github.io/dashboard  |

Each new version published, should also have a `Changelog` for the new features and what is needed to be updated in previous configurations of the `values.yaml` file. The following example will illustrate this: 


>New features:
>
>...
>- All users will now be able to share information between each other, through a public bucket in MinIO.
>    - To take advantage of this feature, to the `defaultBuckets` variable fro MinIO, the `public-bucket` bucket should be added.
>
>...

