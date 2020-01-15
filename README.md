# NRM LimeSurvey

OpenShift templates for LimeSurvey, used within Natural Resources Ministries and ready for deployment on [OpenShift](https://www.openshift.com/).  [LimeSurvey](https://www.limesurvey.org/) is an open-source PHP application with a relational database for persistent data.  MariaDB was chosen over the usual CSI Lab PostgreSQL due to LimeSurvey supporting DB backup out-of-the-box with MariaDB, but not PostgreSQL.

## Files

* [Deployment configuration](openshift/mariadb.dc.json) for MariaDB database
* [Deployment configuration](openshift/limesurvey-mariadb.dc.json) for LimeSurvey PHP application, with MariaDB Database
* [Deployment configuration](openshift/limesurvey-postgresql.dc.json) for LimeSurvey PHP application, with PostgreSQL Database
* [Configuration](application/config/config-mysql.php) used during initial install of LimeSurvey with a MariaDB Database.  It contains NRM-specific details such as the SMTP host and settings, and reply-to email addresses; most importantly, it integrates with the OpenShift pattern of exposing DB parameters as environmental variables in the shell.  It is automatically deployed to the running container from the application's OpenShift ConfigMap.
* [Configuration](application/config/config-postgresql.php) used during initial install of LimeSurvey with a PostgreSQL Datbase.  It contains NRM-specific details such as the SMTP host and settings, and reply-to email addresses; most importantly, it integrates with the OpenShift pattern of exposing DB parameters as environmental variables in the shell.  It is automatically deployed to the running container from the application's OpenShift ConfigMap.

## Build

To ensure we can build off a known version of LimeSurvey, we build images based upon the [git submodule](./LimeSurvey).  
`oc -n b7cg3n-tools new-build openshift/php:7.1~https://github.com/LimeSurvey/LimeSurvey.git --name=limesurvey-app`

Tag with the correct release version, matching the major-minor tag at the source [repo](https://github.com/LimeSurvey/LimeSurvey/tags).  For example:

`oc -n b7cg3n-tools tag limesurvey-app:latest limesurvey-app:v3.15` 

NOTE: To update this LimeSurvey [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) from the [upstream repo](https://github.com/LimeSurvey/LimeSurvey):   
`git submodule update --remote LimeSurvey`

## Deploy

### Database

Deploy the DB using the correct SURVEY_NAME parameter (e.g. `xyz`):  
`oc -n b7cg3n-deploy new-app --file=./openshift/mariadb.dc.json -p SURVEY_NAME=xyz`

All DB deployments are based on the out-of-the-box [OpenShift Database Image](https://docs.openshift.com/container-platform/3.11/using_images/db_images/mariadb.html).

#### Reset the Database

To redeploy *just* the database, first delete the deployed objects from the last run, with the correct SURVEY_NAME, such as:  
`oc -n b7cg3n-deploy delete secret/xyz-mariadb dc/xyz-mariadb svc/xyz-mariadb`

(`pvc/xyz-mariadb` will be left as-is)  

### Application

Deploy the Application using the survey-specific parameter (e.g. `xyz`):  
`oc -n b7cg3n-deploy new-app --file=./openshift/limesurvey-mariadb.dc.json -p SURVEY_NAME=xyz`

#### Reset the Application

To redeploy *just* the application, first delete the deployed objects from the last run, with the correct SURVEY_NAME, such as:  
`oc -n b7cg3n-deploy delete cm/xyz-app-config dc/xyz-app svc/xyz route/xyz`

(`pvc/xyz-app-uploads` will be left as-is)  

## Copy over Upload folder

As OpenShift pods can get redeployed at any time, we copy all `/upload` folders and files onto our mounted PersistentVolume. Use `oc rsync` with the correct SURVEY_NAME such as:  
`oc -n b7cg3n-deploy rsync upload $(oc -n b7cg3n-deploy get pods | grep xyz-app- | grep -v deploy | grep Running | awk '{print $1}'):/var/lib/limesurvey`

## Perform initial LimeSurvey installation

Run the [command line install](https://manual.limesurvey.org/Installation_using_a_command_line_interface_(CLI)) via `oc rsh`, with the correct SURVEY_NAME and credentials, such as:
```
oc -n b7cg3n-deploy rsh $(oc -n b7cg3n-deploy get pods | grep xyz-app- | grep -v deploy | grep Running | awk '{print $1}')
cd application/commands/
php console.php install admin <password> Administrator <>@gov.bc.ca
```

## Log into the LimeSurvey installation
 
Once the application has finished the initial install you may log in as the admin user (created in either of the two methods above).  Use the correct SURVEY_NAME in the URL, for example:   
[https://xyz-survey.pathfinder.gov.bc.ca/index.php/admin]

## FAQ

1. To login the database, open the DB pod terminal (via OpenShift Console or `oc rsh`) and enter:
  `MYSQL_PWD="$MYSQL_PASSWORD" mysql -h 127.0.0.1 -u $MYSQL_USER -D $MYSQL_DATABASE`

2. To reset all deployed objects (this will destroy all data and persistent volumes).  Only do this on a botched initial install or if you have the DB backed up and ready to restore into the new wiped database.  
  `oc -n b7cg3n-deploy delete all,secret,pvc -l app=xyz`

  NOTE: The ConfigMap will be left as-is, so to delete:
  `oc -n b7cg3n-deploy delete cm/xyz-app-config`

  OR:  
    `oc -n b7cg3n-deploy delete all,secret,pvc -l app=$S`  
  and  
    `oc -n b7cg3n-deploy delete cm/$S-app-config`


3. To recreate `config.php` in a ConfigMap form (e.g. due to a new version of LimeSurvey or additional NRM-specific setup parameters).  
    a. update [./application/config/config-mysql.php] or   [./application/config/config-postgresql.php]
    b. create the ConfigMap, with the correct SURVEY_NAME, such as:  
    `oc -n b7cg3n-deploy create configmap xyz-app-config --from-file=config.php=./application/config/config-mysql.php`  
    or
    `oc -n b7cg3n-deploy create configmap xyz-app-config --from-file=config.php=./application/config/config-postgresql.php`      
    c. let OpenShift generate the specification, with the correct SURVEY_NAME, such as:  
    `oc -n b7cg3n-deploy export configmap xyz-app-config --as-template=nrm-survey-configmap -o json`  
    d. copy-and-paste the ConfigMap specification, updating the entry in [./openshift/limesurvey-mysql.dc.json] or [./openshift/limesurvey-postgresql.dc.json] 
    e. redeploy this file so that all running pods have the same configuration  

NOTE: The `config.php` is deployed as read-only, from the OpenShift ConfigMap in the [DeploymentConfig](./openshift/limesurvey-mysql.dc.json) file.  Any updates to this file implies that you must redeploy the application (but not necessarily the database).

If the new version of LimeSurvey has changed `update` folder changes, sync these changes to [Uploads Folder]()./upload)

4. The LimeSurvey GUI wizard-style install is not used as we enforce the NRM-specific `config.php`.  This file is always deployed into the running container's Configuration directory (read-only), and so LimeSurvey will not launch the wizard.  Launching the wizard without running the step above will result in a `HTTP ERROR 500` error.

If the new version of LimeSurvey has changed `update` folder changes, sync these changes to [./upload]

5. The LimeSurvey GUI wizard-style install is not used as we enforce the NRM-specific `config.php`.  This file is always deployed into the running container's Configuration directory (read-only), and so LimeSurvey will not launch the wizard.  Launching the wizard without running the step above will result in a `HTTP ERROR 500` error.

6. To dynamically get the pod name of the running application, this is helpful:
   `oc -n b7cg3n-deploy get pods | grep xyz-app- | grep -v deploy | grep Running | awk '{print $1}'`
  
## Using an environmental variable to deploy

For each specific survey, it may be useful to set an environment variable for the deployment, for example the `xzz` survey, which will result in a URL of `xyz-survey.pathfinder.gov.bc.ca`. Note that you must fill in the correct admin password (`supersecret` below) and email (`John.Doe@gov.bc.ca` below):

```bash
export S=xyz
oc -n b7cg3n-deploy new-app --file=./openshift/mariadb.dc.json -p SURVEY_NAME=$S
oc -n b7cg3n-deploy new-app --file=./openshift/limesurvey-mariadb.dc.json -p SURVEY_NAME=$S
```

Or if using PostgreSQL:

```bash
oc -n b7cg3n-deploy new-app --file=./openshift/postgresql.dc.json -p SURVEY_NAME=$S
oc -n b7cg3n-deploy new-app --file=./openshift/limesurvey-postgresql.dc.json -p SURVEY_NAME=$S
```

Once the application pod(s) are up, which can be verified by:  
`oc -n b7cg3n-deploy get pods | grep $S-app- | grep -v deploy | grep Running | awk '{print $1}'`

Copy over the upload folder and initialize the admin credentials:

```bash
oc -n b7cg3n-deploy rsync upload $(oc -n b7cg3n-deploy get pods | grep $S-app- | grep -v deploy | grep Running | awk '{print $1}'):/var/lib/limesurvey

oc -n b7cg3n-deploy rsh $(oc -n b7cg3n-deploy get pods | grep $S-app- | grep -v deploy | grep Running | awk '{print $1}')
cd application/commands/
php console.php install admin supersecret Administrator John.Doe@gov.bc.ca
exit

unset S
```

## TO DO

* test DB backup/restore and transfer
* test out application upgrade (e.g. LimeSurvey updates their codebase)

* check for image triggers which force a reploy (image tags.. latest -> v1)
* health checks for each of the two containers

### Done

* updated `gluster-file-db` to `netapp-block-standard`
* updated `gluster-file` to `netapp-file-standard`
* check for persistent upload between re-deploys
* appropriate resource limits (multi pods supported)
