# External Images

This document will guide a user on how to build and deploy the private images that the Data Lab is dependent on.

1. Images descriptions
    - Docker Ckan
    - User Notification Sidecar
    - Keycloak Event Metrics Sidecar
2. Building & Publishing
    - Prerequisites
    - Automatic Image Building & Publishing
    - Manual Image Building & Publishing

There are a lot of other images that the Data Lab depends on, but these images are public and maintained by other entities, so they do not belong to this process.

## Images descriptions 
### Docker Ckan 

The developed image for Ckan was based on this [Dockerized Ckan repo](https://github.com/keitaroinc/docker-ckan). We only use the version `2.9` of Ckan image, so that is the only folder we saved, under the name `ckan2.9`. For this image, only a few features need to be enabled:

- CSS to hide unnecessary buttons
- Install and configure Single Sign-On (for Keycloak)
- Install and configure ACL management (for permissions)

To install the extensions needed the following lines must be added to the code:
```docker
RUN pip wheel --wheel-dir=/wheels git+https://github.com/dvrpc/ckanext-oauth2@master#egg=ckanext-oauth2
```

The extensions list must be updated accordingly, and a flag to accept request without TLS certificate must also be enabled, once inside the cluster communications do not use this certificate:
```docker
ENV CKAN__PLUGINS envvars image_view text_view recline_view oauth2
ENV OAUTHLIB_INSECURE_TRANSPORT=True
```

To install these extensions the following lines must also be added:
```docker
RUN pip install --no-index --find-links=/srv/app/ext_wheels ckanext-oauth2
```

Finally, these plugins must be configured with the following values:

```docker
# Configure plugins
RUN ckan config-tool ${APP_DIR}/production.ini "ckan.plugins = ${CKAN__PLUGINS}" && \
    # Keycloak settings
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.logout_url = /user/logged_out" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.edit_url = https://keycloak.example.test/auth/realms/datalab-demo/account" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.authorization_endpoint = https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/auth" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.token_endpoint = https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/token" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.profile_api_url = https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/userinfo" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.client_id = ckan" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.client_secret = YOUR-CLIENT-SECRET" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.scope = profile email openid" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.profile_api_user_field = preferred_username" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.profile_api_mail_field = email" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.authorization_header = Bearer" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.profile_api_fullname_field = preferred_username" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.sysadmin_group_name = admin" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.profile_api_groupmembership_field = roles"

    # Authorization settings
    ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.anon_create_dataset = false" && \
    ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.create_unowned_dataset = false" && \
    ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.create_dataset_if_not_in_organization = false" && \
    ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.user_create_groups = true" && \
    ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.user_create_organizations = false" && \
    ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.user_delete_groups = true" && \
    ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.user_delete_organizations = false" && \
    ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.create_user_via_api = false" && \
    ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.create_user_via_web = false" && \
    ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.roles_that_cascade_to_sub_groups = admin" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.auth.public_user_details = true" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.auth.public_activity_stream_detail = true" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.auth.allow_dataset_collaborators = false" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.auth.create_default_api_keys = false" && \
    
    # Set file upload option to false
    ckan config-tool ${APP_DIR}/production.ini "ckan.storage_path = None" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.max_resource_size = 0" && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.max_image_size = 0" && \
    ckan config-tool ${APP_DIR}/production.ini "ofs.impl = None" && \
    ckan config-tool ${APP_DIR}/production.ini "ofs.storage_dir = None" && \
```

The Keycloak settings are almost a default for any SSO configuration. The domain `example.test` and client secret `YOUR-CLIENT-SECRET` should be replaced by the respective values.

The Authorization settings can be left as they are for the expected behaviour of the Data Lab, but for more information the [official Ckan documentation](https://docs.ckan.org/en/2.9/maintaining/authorization.html) can be consulted.

The last few lines serve the purpose of denying any kind of file upload to Ckan, as was desired during development.

Unfortunately, these values for the Ckan image can't be set dynamically, so the Ckan image must be built with these pre-defined values, in order to work as expected in the production environment.

### User Notification Sidecar

This docker image will only launch an environment with [Alpine](https://hub.docker.com/_/alpine) and a running Python [Flask](https://flask.palletsprojects.com/en/2.1.x/) app to notify users. This script can have most default values set dynamically through environment variables, so the `dockerfile` does not need any further alterations.

### Keycloak Event Metrics Sidecar

With the same environment as the previous, this docker image will also launch an environment with [Alpine](https://hub.docker.com/_/alpine) and a running Python [Flask](https://flask.palletsprojects.com/en/2.1.x/) app to gather Keycloak metrics and make them available to Prometheus. This script can also have most default values set dynamically through environment variables, so the `dockerfile` does not need any further alterations.

## Building & Publishing

### Prerequisites

For building the three images mentioned above, one needs to have [Docker](https://www.docker.com/) installed.


### Automatic Image Building & Publishing

Inside the folder `tf/tf-docker-images/` a terraform template was created to facilitate the process of building and publishing the images described in the previous sections.
This template was design to build and publish these images either on [Docker Hub](https://hub.docker.com/) or [AWS ECR](https://aws.amazon.com/ecr/).
<br>

To deploy on AWS ensure you have the authentication taken care of in the [AWS CLI (Command Line Interface)](https://aws.amazon.com/cli/) with the right credentials, and inside the `tf/tf-docker-images/` folder create a file called `dev.tfvars` in which you will place the variable configurations as requested in `varsDocker.tf`. For example:

```
AWS_REGION = "eu-central-1"
DOCKER_HOST = "tcp://localhost:2375
DOCKER_USERNAME = "example-name"  
DOCKER_PASSWORD =  "example-pasword"
DOCKER_IMAGES_LIST = ["user-notification-container","keycloak-metrics-sidecar","ckan2.9"]
USE_ECR = true
PATH_TO_DATALAB_VALUES = "../../charts/datalab/values.yaml"
```

In order to choose which of the two Image Registry Platforms to use, there is the variable `USE_ECR`.
<br>

If set to `true`, then the images will be published to [AWS ECR](https://aws.amazon.com/ecr/) and there is no need to set the following variables: `[DOCKER_USERNAME, DOCKER_PASWORD]`. No further configurations must be done to conclude this process. 
<br>

Otherwise, if set to `false`, [Docker Hub](https://hub.docker.com/) will be used.
In this cenario the following steps must be taken:
1. Have an account on Docker Hub;
2. Create one repository for each one of the three images, with the following names respectively - ["user-notification-container","keycloak-metrics-sidecar","ckan2.9"];
3. Set the variables `[DOCKER_USERNAME, DOCKER_PASWORD]` with your Docker Hub credentials;
<br>

Finally, after having all the configurations completed, and [Terraform Plan](https://www.terraform.io/cli/commands/plan) reviewed, this deployment follows the same steps as above, which means a bucket or file structure to save the [Terraform State](https://www.terraform.io/language/state) should already be in place, so that the following commands run successfully:

```
terraform init -backend-config="bucket=************" -backend-config="key=************" -backend-config="region=************"

terraform apply -var-file="dev.tfvars"
```
<br>

When applying the Terraform file, the three images that are set by default on the Datalab's `values.yaml`, are changed to the ones published in these last steps.

### Manual Image Building & Publishing

If, for instance, a user doesn't plan on using Docker or ECR, and wants to build and publish these images manually, this is also a viable option.

Thr prerequisites remain, where Docker must be installed. Having this prerequisite met, the user should build each image separately. Inside each of the folder found under the `images` folder, the following command must be ran:

```bash
docker build -t <image-name> .
```

After this, each image should be identifiable through the output of the `docker images` command. Then, only publishing the images is left. This process can be completed with the following commands, where the `<image_repo_link>` should point towards the image registry meant to be used:

```bash
docker tag <image_ID> <image_repo_link>:<image_tag>
docker push <image_repo_link>:<image_tag>
```

