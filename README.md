### Table of Contents


```bash
oc -n 245e18-tools process -f openshift/limesurvey.bc.yaml | oc -n 245e18-tools apply -f -

 oc -n 245e18-tools start-build bc/limesurvey  

 oc -n 245e18-tools get networkpolicy 
 
 oc -n 245e18-tools delete is/limesurvey bc/limesurvey 
```


<!-- TOC depthTo:2 -->

- [NRM LimeSurvey](#nrm-limesurvey)
  - [Prerequisites](#prerequisites)
  - [Files](#files)
  - [Build](#build)
  - [Deploy](#deploy)
    - [Database Deployment](#database-deployment)
    - [Application Deployment](#application-deployment)
      - [Perform LimeSurvey installation](#perform-limesurvey-installation)
      - [Synchronize the Uploads folder](#synchronize-the-uploads-folder)
    - [Log into the LimeSurvey app](#log-into-the-limesurvey-app)
  - [Example Deployment](#example-deployment)
    - [Database Deployment](#database-deployment-1)
    - [Application Deployment](#application-deployment-1)
      - [Perform LimeSurvey installation](#perform-limesurvey-installation-1)
      - [Synchronize the Uploads folder](#synchronize-the-uploads-folder-1)
    - [Log into the LimeSurvey app](#log-into-the-limesurvey-app-1)
  - [Using Environmental variables to deploy](#using-environmental-variables-to-deploy)
    - [Set the environment variables](#set-the-environment-variables)
    - [Database Deployment](#database-deployment-2)
    - [App Deployment](#app-deployment)
      - [Perform LimeSurvey installation](#perform-limesurvey-installation-2)
      - [Synchronize the Uploads folder](#synchronize-the-uploads-folder-2)
    - [Log into the LimeSurvey app](#log-into-the-limesurvey-app-2)
  - [FAQ](#faq)
  - [Versioning](#versioning)
  - [[Unreleased]](#unreleased)
    - [Added](#added)
    - [Changed](#changed)
    - [Removed](#removed)

<!-- /TOC -->

# NRM LimeSurvey

OpenShift templates for LimeSurvey, used within Natural Resources Ministries and ready for deployment on [OpenShift](https://www.openshift.com/). [LimeSurvey](https://www.limesurvey.org/) is an open-source PHP application with a relational database for persistent data. .

## Prerequisites

For build:

- Administrator access to an [Openshift](https://console.apps.silver.devops.gov.bc.ca/k8s/cluster/projects) Project namespace

Once built, this image may be deployed to a separate namespace with the appropriate `system:image-puller` role.

For deployment:

- Administrator access to an [Openshift](https://console.apps.silver.devops.gov.bc.ca/k8s/cluster/projects) Project namespace
- the [oc](https://docs.openshift.com/container-platform/3.11/cli_reference/get_started_cli.html) CLI tool, installed on your local workstation
- access to this public [GitHub Repo](./)

Once deployed, any visitors to the site will require a modern browser (e.g. Edge, FF, Chrome, Opera etc.) with activated JavaScript (see official LimeSurvey [docs](https://manual.limesurvey.org/Installation_-_LimeSurvey_CE#Make_sure_you_can_use_LimeSurvey_on_your_website))

## Files

- [OpenShift LimeSurvey app template](openshift/limesurvey.dc.yaml) for LimeSurvey PHP application, with PostgreSQL Database
- [OpenShift Database service template](openshift/postgresql.dc.yaml) for a PostgreSQL Database
- [LimeSurvey Configuration](application/config/config-postgresql.php) used during initial install of LimeSurvey with a PostgreSQL Database. It contains NRM-specific details such as the SMTP host and settings, and reply-to email addresses; most importantly, it integrates with the OpenShift pattern of exposing DB parameters as environmental variables in the shell. It is automatically deployed to the running container from the application's OpenShift ConfigMap.

## Build

NOTE: PHP7.1 image is no longer available on OCP4, so we're using the legacy image from OCP3 cluster, tagged as `php:7.1`.

To ensure we can build off a known version of LimeSurvey, we build images based upon the [git submodule](./LimeSurvey).

> oc -n &lt;tools-namespace&gt; new-build &lt;tools-namespace&gt;/php:7.1~https://github.com/LimeSurvey/LimeSurvey.git#3.x-LTS --name=limesurvey-app

Tag with the correct release version, matching the major-minor tag at the source [repo](https://github.com/LimeSurvey/LimeSurvey/tags). For example:

> oc -n &lt;tools-namespace&gt; tag limesurvey-app:latest limesurvey-app:3.x-LTS

NOTE: To update this LimeSurvey [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) from the [upstream repo](https://github.com/LimeSurvey/LimeSurvey):

> git submodule update --remote LimeSurvey

## Deploy

### Database Deployment

Deploy the DB using the correct SURVEY_NAME parameter (e.g. an acronym that is prefixed to `limesurvey`):

> oc -n &lt;project&gt; new-app --file=./openshift/postgresql.dc.yaml -p SURVEY_NAME=&lt;survey&gt;limesurvey

All DB deployments are based on the out-of-the-box [OpenShift Database Image](https://docs.openshift.com/container-platform/3.11/using_images/db_images/postgresql.html).

### Application Deployment

Deploy the Application using the survey-specific parameter (e.g. `<survey>limesurvey`):

> oc -n &lt;project&gt; new-app --file=./openshift/limesurvey.dc.yaml -p SURVEY_NAME=&lt;survey&gt;limesurvey -p ADMIN_EMAIL=&lt;Email.Address&gt;@gov.bc.ca

oc -n 599f0a-dev new-app --file=./openshift/limesurvey.dc.yaml -p SURVEY_NAME=testlimesurvey -p ADMIN_EMAIL=Gary.T.Wong@gov.bc.ca

NOTE: The ADMIN_EMAIL is required, and you override the ADMIN_USER and ADMIN_NAME. The ADMIN_PASSWORD is automatically generated by the template; be sure to note the generated password (shown in the output of this command on the screen).

#### Perform LimeSurvey installation

Run the [command line install](<https://manual.limesurvey.org/Installation_using_a_command_line_interface_(CLI)>) via `oc rsh`, with the correct SURVEY_NAME and credentials:

> oc -n &lt;project&gt; rsh $(oc -n &lt;project&gt; get pods | grep &lt;survey&gt;limesurvey-app- | grep -v deploy | grep Running | head -n 1 | awk '{print $1}')

> cd application/commands/
> php console.php install ${ADMIN_USER} ${ADMIN_PASSWORD} ${ADMIN_NAME} ${ADMIN_EMAIL}

NOTE that the `${ADMIN_*}` text is exactly as written, since the app has access to these environment variables (set during the `new-app` step).

#### Synchronize the Uploads folder

As OpenShift pods can be subsequently redeployed at any time, we synchronize all `/upload` folders and files onto our mounted PersistentVolume.

This is important only if the Survey Administrator has customized the CSS or uploaded any custom web media assets.

Once a pod is running, use `oc rsync` with the correct SURVEY_NAME such as:

> oc -n &lt;project&gt; rsync upload $(oc -n &lt;project&gt; get pods | grep &lt;survey&gt;limesurvey-app- | grep -v deploy | grep Running | head -n 1 | awk '{print $1}'):/var/lib/limesurvey

<details><summary>When upgrading to a newer release</summary>

If upgrading an active survey to a newer LimeSurvey [release](https://github.com/LimeSurvey/LimeSurvey/releases), you'll need to do re-synchronize (even without customized CSS or custom web media assets). The newer release may have added or modified web assets.

This need only be done once per replica set (i.e. `rsh` into one pod, rsync, and then all replicas will see this change).

**TODO** back up as part of 'backup containers' for user uploaded files?

</details>

### Log into the LimeSurvey app

Once the application has finished the initial install you may log in as the admin user (created in either of the two methods above). Use the correct Survey acronym in the URL:
`https://<survey>limesurvey.apps.silver.devops.gov.bc.ca/index.php/admin`

## Example Deployment

As a concrete example of a survey with the acronym `acme`, deployed in the project namespace `599f0a-dev`, here are the steps:

<details><summary>Deployment Steps</summary>

### Database Deployment

> oc -n &lt;project&gt; new-app --file=./openshift/postgresql.dc.yaml -p SURVEY_NAME=acmelimesurvey

```bash
--> Deploying template "599f0a-dev/nrms-postgresql-dc" for "./openshift/postgresql.dc.yaml" to project 599f0a-dev

     * With parameters:
        * Survey Name=acmelimesurvey
        * Memory Limit=512Mi
        * PostgreSQL Connection Password=VgB0rsOFXY2sOeXo # generated
        * Database Volume Capacity=1Gi

--> Creating resources ...
    secret "acmelimesurvey-postgresql" created
    persistentvolumeclaim "acmelimesurvey-postgresql" created
    deploymentconfig.apps.openshift.io "acmelimesurvey-postgresql" created
    service "acmelimesurvey-postgresql" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/acmelimesurvey-postgresql'
    Run 'oc status' to view your app.
```

### Application Deployment

> oc -n &lt;project&gt; new-app --file=./openshift/limesurvey.dc.yaml -p SURVEY_NAME=acmelimesurvey -p ADMIN_EMAIL=Wile.E.Coyote@gov.bc.ca -p ADMIN_NAME="ACME LimeSurvey Administrator"

```bash
--> Deploying template "599f0a-dev/nrms-limesurvey-dc" for "./openshift/limesurvey.dc.yaml" to project 599f0a-dev

     * With parameters:
        * Namespace=599f0a-tools
        * Image Stream=limesurvey-app
        * Version of LimeSurvey=3.x-LTS
        * LimeSurvey Acronym=acmelimesurvey
        * Upload Folder size=1Gi
        * Administrator Account Name=admin
        * Administrator Display Name=ACME LimeSurvey Administrator
        * Administrator Passwords=e5tybj8HwNxgVr6k # generated
        * Administrator Email Address=Wile.E.Coyote@gov.bc.ca
        * CPU_LIMIT=100m
        * MEMORY_LIMIT=256Mi
        * CPU_REQUEST=50m
        * MEMORY_REQUEST=200Mi
        * REPLICA_MIN=2
        * REPLICA_MAX=5

--> Creating resources ...
    configmap "acmelimesurvey-app-config" created
    secret "acmelimesurvey-admin-cred" created
    persistentvolumeclaim "acmelimesurvey-app-uploads" created
    deploymentconfig.apps.openshift.io "acmelimesurvey-app" created
    horizontalpodautoscaler.autoscaling "acmelimesurvey" created
    service "acmelimesurvey" created
    route.route.openshift.io "acmelimesurvey" created
--> Success
    Access your application via route 'acmelimesurvey.apps.silver.devops.gov.bc.ca'
    Run 'oc status' to view your app.
```

#### Perform LimeSurvey installation

After 20 - 30 seconds, at least one pod should be up. Verify that pods are running:

> oc -n &lt;project&gt; get pods | grep acmelimesurvey-app- | grep -v deploy | grep Running | awk '{print \$1}'

```bash
acmelimesurvey-app-1-5rxkd
acmelimesurvey-app-1-jg2k2
```

Once you see running pods, remote into one of the pods:

> oc -n &lt;project&gt; rsh $(oc -n &lt;project&gt get pods | grep acmelimesurvey-app- | grep -v deploy | grep Running | head -n 1 | awk '{print \$1}')

Run the install commands in this shell:

> cd application/commands/  
> php console.php install ${ADMIN_USER} ${ADMIN_PASSWORD} ${ADMIN_NAME} ${ADMIN_EMAIL}

```bash
Connecting to database...
Using connection string pgsql:host=acmelimesurvey-postgresql;port=5432;dbname=acmelimesurvey
Creating tables...
Creating admin user...
All done!
```

Type `exit` to exit the remote shell.

#### Synchronize the Uploads folder

> oc -n &lt;project&gt; rsync upload $(oc -n &lt;project&gt; get pods | grep acmelimesurvey-app- | grep -v deploy | grep Running | head -n 1 | awk '{print \$1}'):/var/lib/limesurvey

```bash
building file list ... done
upload/
upload/readme.txt
upload/admintheme/
upload/admintheme/index.html
upload/labels/
upload/labels/index.html
upload/labels/readme.txt
upload/surveys/
upload/surveys/.htaccess
upload/themes/
upload/themes/index.html
upload/themes/survey/
upload/themes/survey/index.html
upload/themes/survey/generalfiles/
upload/themes/survey/generalfiles/index.html

sent 2314 bytes  received 238 bytes  1701.33 bytes/sec
total size is 1575  speedup is 0.62
```

Type `exit` to exit the remote shell.

### Log into the LimeSurvey app

The Administrative interface is at:
https://acmelimesurvey.apps.silver.devops.gov.bc.ca/index.php/admin/

and brings to you a screen like:
![Admin Logon](./docs/images/AdminLogin.png)

Once logged as an Admin, you'll be brought to the Welcome page:
![Welcome Page](./docs/images/WelcomePage.png)

</details>

## Using Environmental variables to deploy

As this is a template deployment, it may be easier to set environment variable for the deployment, so using the example &lt;project&gt; is `599f0a-dev` and &lt;survey&gt; is `PAWS Limesurvey`:

<details><summary>Deployment Steps</summary>

### Set the environment variables

On a workstation logged into the OpenShift Console:

```bash
export PROJECT=599f0a-dev
export SURVEY=paws
```

### Database Deployment

> oc -n ${PROJECT} new-app --file=./openshift/postgresql.dc.yaml -p SURVEY_NAME=${SURVEY}limesurvey

```bash


```

### App Deployment

> oc -n ${PROJECT} new-app --file=./openshift/limesurvey.dc.yaml -p SURVEY_NAME=${SURVEY}limesurvey -p ADMIN_EMAIL=John.Doe@gov.bc.ca -p ADMIN_NAME="IITD LimeSurvey Administrator"

```bash
--> Deploying template "599f0a-dev/nrms-limesurvey-dc" for "./openshift/limesurvey.dc.yaml" to project 599f0a-dev

     * With parameters:
        * Namespace=599f0a-tools
        * Image Stream=limesurvey-app
        * Version of LimeSurvey=3.x-LTS
        * LimeSurvey Acronym=pawslimesurvey
        * Upload Folder size=1Gi
        * Administrator Account Name=admin
        * Administrator Display Name=IITD LimeSurvey Administrator
        * Administrator Passwords=...
        * Administrator Email Address=x@gov.bc.ca
        * CPU_LIMIT=100m
        * MEMORY_LIMIT=256Mi
        * CPU_REQUEST=50m
        * MEMORY_REQUEST=200Mi
        * REPLICA_MIN=2
        * REPLICA_MAX=5

--> Creating resources ...
    configmap "pawslimesurvey-app-config" created
    secret "pawslimesurvey-admin-cred" created
    persistentvolumeclaim "pawslimesurvey-app-uploads" created
    deploymentconfig.apps.openshift.io "pawslimesurvey-app" created
    horizontalpodautoscaler.autoscaling "pawslimesurvey" created
    service "pawslimesurvey" created
    route.route.openshift.io "pawslimesurvey" created
--> Success
    Access your application via route 'pawslimesurvey.apps.silver.devops.gov.bc.ca'
    Run 'oc status' to view your app.
```

#### Perform LimeSurvey installation

After 20 to 30 seconds, at least one pod should be up. Verify that pods are running:

> oc -n ${PROJECT} get pods | grep ${SURVEY}limesurvey-app- | grep -v deploy | grep Running | awk '{print \$1}'

```bash
iitdlimesurvey-app-1-2z7tj
iitdlimesurvey-app-1-pf8q4
```

Once you see running pods, remote into one of the pods:

> oc -n ${PROJECT} rsh $(oc -n ${PROJECT} get pods | grep ${SURVEY}limesurvey-app- | grep -v deploy | grep Running | head -n 1 | awk '{print \$1}')

```bash
cd application/commands/
php console.php install ${ADMIN_USER} ${ADMIN_PASSWORD} ${ADMIN_NAME} ${ADMIN_EMAIL}
```

```bash
Connecting to database...
Using connection string pgsql:host=pawslimesurvey-postgresql;port=5432;dbname=pawslimesurvey
Creating tables...
Creating admin user...
All done!
```

Type `exit` to exit the remote shell.

#### Synchronize the Uploads folder

> oc -n ${PROJECT} rsync upload $(oc -n ${PROJECT} get pods | grep ${SURVEY}limesurvey-app- | grep -v deploy | grep Running | head -n 1 | awk '{print \$1}'):/var/lib/limesurvey

```bash
building file list ... done
upload/
upload/readme.txt
upload/admintheme/
upload/admintheme/index.html
upload/labels/
upload/labels/index.html
upload/labels/readme.txt
upload/surveys/
upload/surveys/.htaccess
upload/themes/
upload/themes/index.html
upload/themes/survey/
upload/themes/survey/index.html
upload/themes/survey/generalfiles/
upload/themes/survey/generalfiles/index.html

sent 2314 bytes  received 238 bytes  1701.33 bytes/sec
total size is 1575  speedup is 0.62
```

### Log into the LimeSurvey app

The Administrative interface is at:
https://${SURVEY}limesurvey.apps.silver.devops.gov.bc.ca/index.php/admin/

and bring to you a screen like:
![Admin Logon](./docs/images/AdminLogin.png)

Once logged as an Admin, you'll be brought to the Welcome page:
![Welcome Page](./docs/images/WelcomePage.png)

</details>

## FAQ

- to login the database, open the DB pod terminal (via OpenShift Console or `oc rsh`) and enter:

  `psql -U ${POSTGREQL_USER} ${POSTGRESQL_DATABASE}`

- to clean-up database deployments:

  `oc -n <project> delete secret/<survey>limesurvey-postgresql dc/<survey>limesurvey-postgresql svc/<survey>limesurvey-postgresql`

  NOTE: The Database Volume will be left as-is in case there is critical business data, so to delete:

  `oc -n <project> delete pvc/<survey>limesurvey-postgresql`

  or if using environment variables:

```bash
    oc -n ${PROJECT} delete secret/${SURVEY}limesurvey-postgresql dc/${SURVEY}limesurvey-postgresql svc/${SURVEY}limesurvey-postgresql
    oc -n ${PROJECT} delete pvc/${SURVEY}limesurvey-postgresql
```

- to clean-up application deployments:

  `oc -n <project> delete cm/<survey>limesurvey-app-config secret/<survey>limesurvey-admin-cred dc/<survey>limesurvey-app svc/<survey>limesurvey route/<survey>limesurvey horizontalpodautoscaler/<survey>limesurvey`

  NOTE: The Uploads Volume is left intact in case there is user-uploaded assets on it; if not (i.e. it's a brand-new survey):  
   `oc -n <project> delete pvc/<survey>limesurvey-app-uploads`

  or if using environment variables:

```bash
    oc -n ${PROJECT} delete cm/${SURVEY}limesurvey-app-config secret/${SURVEY}limesurvey-admin-cred dc/${SURVEY}limesurvey-app svc/${SURVEY}limesurvey route/${SURVEY}limesurvey horizontalpodautoscaler/${SURVEY}limesurvey
    oc -n ${PROJECT} delete pvc/${SURVEY}limesurvey-app-uploads
```

- to reset _all_ deployed objects (this will destroy all data and persistent volumes). Only do this on a botched initial install or if you have the DB backed up and ready to restore into the new wiped database.

  `oc -n <project> delete all,secret,pvc -l app=<survey>limesurvey`

  NOTE: The ConfigMap will be left as-is, so to delete:

  `oc -n <project> delete cm/<survey>limesurvey-app-config`

  or if using environment variables:

```bash
    oc -n ${PROJECT} delete all,secret,pvc -l app=${SURVEY}limesurvey
    oc -n ${PROJECT} delete cm/${SURVEY}limesurvey-app-config horizontalpodautoscaler/${SURVEY}limesurvey
```

- to recreate `config.php` in a ConfigMap form (e.g. due to a new version of LimeSurvey or additional NRM-specific setup parameters).

  a. update the [ConfigMap Source](application/config/config-postgresql.php)

  b. create a temporary ConfigMap in the OpenShift project:

  > oc -n &lt;project&gt; create configmap limesurvey-tmp-config --from-file=config.php=./application/config/config-postgresql.php

  c. let OpenShift generate the specification, as a template:

  > oc -n b&lt;project&gt; get --export configmap limesurvey-tmp-config -o yaml

  d. copy-and-paste the ConfigMap specification, replacing the `ConfigMap->data` entry in the [Deployment Template](openshift/limesurvey.dc.yaml#L66); ensure the YAML
  is indented the same amount of spaces as before

  e. re-deploy so that all running pods have the same configuration

  f. Delete the temporary OpenShift secret

  > oc -n &lt;project&gt; delete cm/limesurvey-tmp-config

  NOTE: The `config.php` is deployed as read-only from the OpenShift ConfigMap in the [DeploymentConfig](./openshift/limesurvey.dc.yaml) file. Any update to this file implies that you must manually redeploy the application (but not necessarily the database); this ConfigMap is not mounted as an `Environment From`, so is not a trigger for re-deployment.

  If the new version of LimeSurvey has `upload` folder changes, sync these changes to the [Uploads Folder](upload)

- the LimeSurvey GUI wizard-style install is not used as we _enforce_ NRM-specific `config.php`. This file is always deployed into the running container's Configuration directory (read-only), and so LimeSurvey will not launch the LimeSurvey wizard. Launching the wizard without running the step above (i.e. a deployed `config.php`)will result in a `HTTP ERROR 500` error.

- to dynamically get the pod name of the running pods, this is helpful:

  > oc -n &lt;project&gt; get pods | grep &lt;survey&gt;limesurvey-app- | grep -v deploy | grep Running | awk '{print \$1}'

- to customize the deployment with higher/lower resources, using environment variables, follow these examples:

  > oc -n ${PROJECT} new-app --file=./openshift/postgresql.dc.yaml -p SURVEY_NAME=${SURVEY}limesurvey -p MEMORY_LIMIT=768Mi -p DB_VOLUME_CAPACITY=1280Mi  
  > oc -n ${PROJECT} new-app --file=./openshift/limesurvey.dc.yaml -p SURVEY_NAME=${SURVEY}limesurvey -p ADMIN_EMAIL=John.Doe@gov.bc.ca -p ADMIN_NAME="IITD LimeSurvey Administrator" -p REPLICA_MIN=1

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## [Unreleased]

- test out application upgrade (e.g. LimeSurvey updates their codebase)
- check for image triggers which force a redeploy (image tags.. latest -> v1)
- update `composer.json` to allow `ubi/php74` or `rhel/php74` images. Using the legacy OCP3 `openshift/php:71` is required due to following `require-dev` dependencies (not met in newer Openshift V4 images):

      ```bash
      Package facebook/webdriver is abandoned, you should avoid using it. Use php-webdriver/webdriver instead.
      Package phpunit/php-token-stream is abandoned, you should avoid using it. No replacement was suggested.
      Package phpunit/phpunit-mock-objects is abandoned, you should avoid using it. No replacement was suggested.
      ```

  These should be fixed either by upstream repo, or we can fork and update the dependencies to:

      ```php
        "require-dev": {
          "fphp-webdriver/webdriver": "*",
          ...
          "phpunit/phpunit": "~7.0"
      }
      ```

  There also `psr-4` warnings to fix (either by the upstream repo, or we can fork and fix); basically folder or file naming conventions to match plugin name:

  ```bash
    Generating optimized autoload files
    Class LimeSurvey\PluginManager\QuestionBase located in ./application/libraries/PluginManager/Question/QuestionBase.php does not comply with psr-4 autoloading standard. Skipping.
    Class LimeSurvey\PluginManager\QuestionPluginAbstract located in ./application/libraries/PluginManager/Question/QuestionPluginAbstract.php does not comply with psr-4 autoloading standard. Skipping.
    Class LimeSurvey\PluginManager\QuestionPluginBase located in ./application/libraries/PluginManager/Question/QuestionPluginBase.php does not comply with psr-4 autoloading standard. Skipping.
    Class LimeSurvey\PluginManager\iQuestion located in ./application/libraries/PluginManager/Question/iQuestion.php does not comply with psr-4 autoloading standard. Skipping.
    Class LimeSurvey\PluginManager\DbStorage located in ./application/libraries/PluginManager/Storage/DbStorage.php does not comply with psr-4 autoloading standard. Skipping.
    Class LimeSurvey\PluginManager\DummyStorage located in ./application/libraries/PluginManager/Storage/DummyStorage.php does not comply with psr-4 autoloading standard. Skipping.
    Class LimeSurvey\PluginManager\iPluginStorage located in ./application/libraries/PluginManager/Storage/iPluginStorage.php does not comply with psr-4 autoloading standard. Skipping.
  ```

Alternatively, switch to [Centos PHP7.1](https://hub.docker.com/layers/centos/php-71-centos7/7.1/images/sha256-1ff68d2e3445091561a258c94c33d73655c44f90fa408a91eeb74f496268f402?context=explore) image

### Added

- after-the-fact tagged and created release for [first version](https://github.com/garywong-bc/nrm-survey/releases/tag/v3.15)
- implemented health checks for the deployments
- tested DB backup/restore and transfer
- updated `gluster-file-db` to `netapp-block-standard`
- updated `gluster-file` to `netapp-file-standard`
- check for persistent upload between re-deploys
- appropriate resource limits (multi-replica deployment supported)

### Changed

### Removed
