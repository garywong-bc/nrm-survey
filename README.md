# NRM LimeSurvey


 applications, ready for deployment on OpenShift

OpenShift templates for LimeSurvey, used within Natural Resources Ministries and ready for deployment on [OpenShift](https://www.openshift.com/).  [LimeSurvey](https://www.limesurvey.org/) is an open-source PHP application with a relational database for persistent data.  MariaDB was chosen over the usual CSI Lab PostgreSQL due to LimeSurvey supporting DB backup out-of-the-box with MariaDB, but not PostgreSQL.

The application pod has been constrained to `maxReplicas=1` to prevent issues with multiple pods with different (possibly conflicting) Configuration Files against the same single database.

## Files

* `openshift/mariadb.dc.json`: Deployment configuration for MariaDB database
* `openshift/limesurvey.dc.json`: Deployment configuration for LimeSurvey PHP application

## Build

To ensure we can update to the latest version of LimeSurvey, we build images based upon the upstream code repository.

`oc -n b7cg3n-tools new-build openshift/php:7.1~https://github.com/LimeSurvey/LimeSurvey.git --name=limesurvey-app`

To delete previous builds:

`LimeSurvey (nrm_baseline)]$ oc -n b7cg3n-tools delete bc/limesurvey-app` 

All build images are vanilla out-of-the-box LimeSurvey code.

## Deploy

### Database
Deploy the DB using the survey-specific parameter (e.g. `mds`):

`oc -n b7cg3n-deploy new-app --file=./openshift/mariadb.dc.json -p SURVEY_NAME=mds`

All DB deployments are based on the out-of-the-box [OpenShift Database Image](https://docs.openshift.com/container-platform/3.11/using_images/db_images/mariadb.html).

#### Reset

To redeploy *just* the database, first delete the deployed objects from the last run, with the correct SURVEY_NAME, such as:  
`oc -n b7cg3n-deploy delete secret/mds-mariadb pvc/mds-mariadb dc/mds-mariadb svc/mds-mariadb`

### Application
Deploy the Application using the survey-specific parameter (e.g. `mds`):  
`oc -n b7cg3n-deploy new-app --file=./openshift/limesurvey.dc.json -p SURVEY_NAME=mds`

#### Reset

To redeploy *just* the application, first delete the deployed objects from the last run, with the correct SURVEY_NAME, such as:  
`oc -n b7cg3n-deploy delete pvc/mds-app-uploads dc/mds-app svc/mds route/mds`

## Perform initial LimeSurvey installation

### Copy over the NRM-specific Configuration File

Use `oc cp` to copy the config.php file, with the correct SURVEY_NAME, such as:

`oc -n b7cg3n-deploy cp openshift/application/config/config.php $(oc -n b7cg3n-deploy get pods | grep mds-app- | grep Running | awk '{print $1}'):/opt/app-root/src/application/config/`

NOTE: This file will not exist yet, as the initial install has not yet been run.  

The `config.php` file has NRM-specific details such as the SMTP host and settings, and reply-to email addresses.

### Run the command-line install

1. Run the [command line install](https://manual.limesurvey.org/Installation_using_a_command_line_interface_(CLI)) via `oc rsh`, with the correct SURVEY_NAME and credentials, such as:
```
oc rsh $(oc -n b7cg3n-deploy get pods | grep mds-app- | grep Running | awk '{print $1}')
cd application/commands/
php console.php install admin sfxzgsdjsS! "John Smith"  Joe.Fake.Person@gov.bc.ca
```

2. Navigate the out-of-box GUI wizard by opening the route in a browser (e.g. https://mds-survey.pathfinder.gov.bc.ca). 

Once the application has finished the initial install you may log in as the admin user (created in either of the two methods above).  For example:   
https://mds-survey.pathfinder.gov.bc.ca/index.php/admin


## FAQ

1. To login the database, open the DB pod terminal (via OpenShift Console or `oc rsh`) and enter:
`MYSQL_PWD="$MYSQL_PASSWORD" mysql -h 127.0.0.1 -u $MYSQL_USER -D $MYSQL_DATABASE`

2. To reset all deployed objects (this will destroy all data).  Only do this on a botched install or if you have the DB backed up and ready to restore into the new wiped database.

`oc -n b7cg3n-deploy delete all,secret,configmap,pvc -l app=mds`

## TO DO

* check for persistent upload between re-deploys
* check for image triggers which force a reploy
* health checks for each of the two containers
* appropriate resource limits
* test DB backup/restore and transfer
* test out application upgrade (e.g. LimeSurvey updates their codebase)