# NRM LimeSurvey

OpenShift templates for LimeSurvey, used within Natural Resources Ministries and ready for deployment on [OpenShift](https://www.openshift.com/).  [LimeSurvey](https://www.limesurvey.org/) is an open-source PHP application with a relational database for persistent data.  MariaDB was initially chosen over the usual CSI Lab PostgreSQL due to LimeSurvey supporting DB backup out-of-the-box with MariaDB; but with the addition of [Backup Containers](https://github.com/BCDevOps/backup-container), we have now standardized on PostgreSQL.

## Files

* [Deployment configuration](openshift/limesurvey-postgresql.dc.json) for LimeSurvey PHP application, with PostgreSQL Database
* [Configuration](application/config/config-postgresql.php) used during initial install of LimeSurvey with a PostgreSQL Datbase.  It contains NRM-specific details such as the SMTP host and settings, and reply-to email addresses; most importantly, it integrates with the OpenShift pattern of exposing DB parameters as environmental variables in the shell.  It is automatically deployed to the running container from the application's OpenShift ConfigMap.
* DEPRECATED [Deployment configuration](openshift/deprecated.mariadb.dc.json) for MariaDB database
* DEPRECATED [Deployment configuration](openshift/deprecated.limesurvey-mariadb.dc.json) for LimeSurvey PHP application, with MariaDB Database
* DEPRECATED [Configuration](application/config/deprecated.config-mysql.php) used during initial install of LimeSurvey with a MariaDB Database.

## Build

To ensure we can build off a known version of LimeSurvey, we build images based upon the [git submodule](./LimeSurvey).

`oc -n b7cg3n-tools new-build openshift/php:7.1~https://github.com/LimeSurvey/LimeSurvey.git --name=limesurvey-app`

Tag with the correct release version, matching the major-minor tag at the source [repo](https://github.com/LimeSurvey/LimeSurvey/tags).  For example:

`oc -n b7cg3n-tools tag limesurvey-app:latest limesurvey-app:v3.15` 

NOTE: To update this LimeSurvey [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) from the [upstream repo](https://github.com/LimeSurvey/LimeSurvey):

`git submodule update --remote LimeSurvey`

## Deploy

### Database

Deploy the DB using the correct SURVEY_NAME parameter (e.g. `xyzlimesurvey`):

`oc -n b7cg3n-deploy new-app --file=./openshift/postgresql.dc.json -p SURVEY_NAME=xyzlimesurvey`

All DB deployments are based on the out-of-the-box [OpenShift Database Image](https://docs.openshift.com/container-platform/3.11/using_images/db_images/postgresql.html).

#### Reset the Database

To redeploy *just* the database, first delete the deployed objects from the last run, with the correct SURVEY_NAME, such as:

`oc -n b7cg3n-deploy delete secret/xyzlimesurvey-postgresql dc/xyzlimesurvey-postgresql svc/xyzlimesurvey-postgresql`

(PVC is left as-is, but to reset that, use `oc -n b7cg3n-deploy delete pvc/xyzlimesurvey-postgresql`)  

### Application

Deploy the Application using the survey-specific parameter (e.g. `xyzlimesurvey`):

`oc -n b7cg3n-deploy new-app --file=./openshift/limesurvey-postgresql.dc.json -p SURVEY_NAME=xyzlimesurvey -p ADMIN_EMAIL=xxx@gov.bc.ca`

NOTE: You can also override the admin username, description, and password.

#### Reset the Application

To redeploy *just* the application, first delete the deployed objects from the last run, with the correct SURVEY_NAME, such as:  
`oc -n b7cg3n-deploy delete cm/xyzlimesurvey-app-config secret/xyzlimesurvey-admin-cred dc/xyzlimesurvey-app svc/xyzlimesurvey route/xyzlimesurvey`

(PVC is left as-is, but to reset that, use `oc -n b7cg3n-deploy delete pvc/xyzlimesurvey-app-uploads`)  

## Copy over Upload folder

As OpenShift pods can be subsequently redeployed at any time, we synchronize all `/upload` folders and files onto our mounted PersistentVolume. Once a pod is running, use `oc rsync` with the correct SURVEY_NAME such as:

`oc -n b7cg3n-deploy rsync upload $(oc -n b7cg3n-deploy get pods | grep xyzlimesurvey-app- | grep -v deploy | grep Running | head -n 1 | awk '{print $1}'):/var/lib/limesurvey`

This is only when upgrading LimeSurvey (i.e. they add/modify web assets), and need only be done once per replica set(i.e. `rsh` into one pod, rsync, and then all replicas will see this change).

TODO back up as part of 'backup containers' for user uploaded files?

## Perform initial LimeSurvey installation

Run the [command line install](https://manual.limesurvey.org/Installation_using_a_command_line_interface_(CLI)) via `oc rsh`, with the correct SURVEY_NAME and credentials, such as:

```bash
oc -n b7cg3n-deploy rsh $(oc -n b7cg3n-deploy get pods | grep xyzlimesurvey-app- | grep -v deploy | grep Running | head -n 1 | awk '{print $1}')
cd application/commands/
php console.php install ${ADMIN_USER} ${ADMIN_PASSWORD} ${ADMIN_NAME} ${ADMIN_EMAIL}
```

## Log into the LimeSurvey installation
 
Once the application has finished the initial install you may log in as the admin user (created in either of the two methods above).  Use the correct SURVEY_NAME in the URL, for example https://xyzlimesurvey.pathfinder.gov.bc.ca/index.php/admin

## FAQ

1. To login the database, open the DB pod terminal (via OpenShift Console or `oc rsh`) and enter:

    `psql -U ${POSTGREQL_USER} ${POSTGRESQL_DATABASE}`

2. To reset all deployed objects (this will destroy all data and persistent volumes).  Only do this on a botched initial install or if you have the DB backed up and ready to restore into the new wiped database.

`oc -n b7cg3n-deploy delete all,secret,pvc -l app=xyzlimesurvey`

  NOTE: The ConfigMap will be left as-is, so to delete:

`oc -n b7cg3n-deploy delete cm/xyzlimesurvey-app-config`

  OR:

```bash
oc -n b7cg3n-deploy delete all,secret,pvc -l app=$S
oc -n b7cg3n-deploy delete cm/$S-app-config
```

3. To recreate `config.php` in a ConfigMap form (e.g. due to a new version of LimeSurvey or additional NRM-specific setup parameters).

    a. update [ConfigMap Source](application/config/config-postgresql.php)

    b. create a temporary ConfigMap in the OpenShift project:
    
      `oc -n b7cg3n-deploy create configmap limesurvey-tmp-config --from-file=config.php=./application/config/config-postgresql.php`

    c. let OpenShift generate the specification, with the correct Template name:
    
      `oc -n b7cg3n-deploy export configmap limesurvey-tmp-config --as-template=nrmlimesurvey-configmap -o json`

    d. copy-and-paste the ConfigMap specification, replacing the `ConfigMap->data` entry in the [Deployment Template](openshift/limesurvey-postgresql.dc.json#L115)

    e. re-deploy so that all running pods have the same configuration  

    f. Delete the temporary OpenShift secret `oc -n b7cg3n-deploy delete cm/limesurvey-tmp-config`


NOTE: The `config.php` is deployed as read-only from the OpenShift ConfigMap in the [DeploymentConfig](./openshift/limesurvey-postgresql.dc.json) file.  Any updates to this file implies that you must redeploy the application (but not necessarily the database).

If the new version of LimeSurvey has `upload` folder changes, sync these changes to [Uploads Folder](upload)

4. The LimeSurvey GUI wizard-style install is not used as we *enforce* NRM-specific `config.php`.  This file is always deployed into the running container's Configuration directory (read-only), and so LimeSurvey will not launch the wizard.  Launching the wizard without running the step above will result in a `HTTP ERROR 500` error.

5. To dynamically get the pod name of the running pods, this is helpful:

   `oc -n b7cg3n-deploy get pods | grep xyzlimesurvey-app- | grep -v deploy | grep Running | awk '{print $1}'`
  
## Using an environmental variable to deploy

For each specific survey, it may be useful to set an environment variable for the deployment, for example the `xzzlimesurvey`, which will result in a URL of `xyzsurvey.pathfinder.gov.bc.ca`. Note that you the admin password and email are required:

```bash
export S=xyz
oc -n b7cg3n-deploy new-app --file=./openshift/postgresql.dc.json -p SURVEY_NAME=$S
oc -n b7cg3n-deploy new-app --file=./openshift/limesurvey-postgresql.dc.json -p SURVEY_NAME=$S -p ADMIN_EMAIL=xx
```
Once the application pod(s) are up (verified via a list of running pods)...
`oc -n b7cg3n-deploy get pods | grep $S-app- | grep -v deploy | grep Running | awk '{print $1}'`

.. copy over the upload folder and initialize the admin credentials:

```bash
oc -n b7cg3n-deploy rsync upload $(oc -n b7cg3n-deploy get pods | grep $S-app- | grep -v deploy | grep Running | head -n 1 | awk '{print $1}'):/var/lib/limesurvey

oc -n b7cg3n-deploy rsh $(oc -n b7cg3n-deploy get pods | grep $S-app- | grep -v deploy | grep Running | head -n 1 | awk '{print $1}')
cd application/commands/ && php console.php install ${ADMIN_USER} ${ADMIN_PASSWORD} ${ADMIN_NAME} ${ADMIN_EMAIL}
exit

unset S
```

## TO DO

* test out application upgrade (e.g. LimeSurvey updates their codebase)
* check for image triggers which force a reploy (image tags.. latest -> v1)

### Done

* after-the-fact tagged and created release for [first version](https://github.com/garywong-bc/nrm-survey/releases/tag/v3.15) 
* implemented health checks for the deployments
* tested DB backup/restore and transfer
* updated `gluster-file-db` to `netapp-block-standard`
* updated `gluster-file` to `netapp-file-standard`
* check for persistent upload between re-deploys
* appropriate resource limits (multi-replica deployment supported)
