<?php if (!defined('BASEPATH')) exit('No direct script access allowed');
/*
| -------------------------------------------------------------------
| DATABASE CONNECTIVITY SETTINGS
| -------------------------------------------------------------------
| This file will contain the settings needed to access your database.
|
| For complete instructions please consult the 'Database Connection'
| page of the User Guide.
|
| -------------------------------------------------------------------
| EXPLANATION OF VARIABLES
| -------------------------------------------------------------------
|
|    'connectionString' Hostname, database, port and database type for
|     the connection. Driver example: mysql. Currently supported:
|                 mysql, pgsql, mssql, sqlite, oci
|    'username' The username used to connect to the database
|    'password' The password used to connect to the database
|    'tablePrefix' You can add an optional prefix, which will be added
|                 to the table name when using the Active Record class
|
*/
$dbhost     = getenv('POSTGRESQL_DB_HOST');
$dbport     = getenv('POSTGRESQL_PORT');
$dbname     = getenv('POSTGRESQL_DB_NAME');
$dbusername = getenv('POSTGRESQL_USERNAME');
$dbpassword = getenv('POSTGRESQL_PASSWORD');
$db_table_prefix = getenv('DB_TABLE_PREFIX');
$connectstring = "pgsql:host=" . $dbhost . ";port=" . $dbport . ";dbname=" . $dbname;

$sitename = getenv('SITENAME');
$adminemail = getenv('ADMIN_EMAIL');
$adminname  = getenv('ADMIN_NAME');

$app_debug      = getenv('DEBUG_APP');
$debug_sql      = getenv('DEBUG_SQL');
$bounce_email   = getenv('BOUNCE_EMAIL');
$email_protocol = getenv('EMAIL_PROTOCOL');
$smtp_host      = getenv('SMTP_HOST');
$smtp_user      = getenv('SMTP_USER');
$smtp_password  = getenv('SMTP_PASSWORD');
$smtp_ssl       = getenv('SMTP_SSL');
$smtp_debug     = getenv('SMTP_DEBUG');
$email_max      = getenv('EMAIL_MAX');

return array(
        'components' => array(
                'db' => array(
                        'connectionString' => $connectstring,
                        'emulatePrepare' => true,
                        'username' => $dbusername,
                        'password' => $dbpassword,
                        'charset' => 'utf8',
                        'tablePrefix' => $db_table_prefix,
                ),

                // Uncomment the following lines if you need table-based sessions.
                // Note: Table-based sessions are currently not supported on MSSQL server.
                // 'session' => array (
                // 'class' => 'application.core.web.DbHttpSession',
                // 'connectionID' => 'db',
                // 'sessionTableName' => '{{sessions}}',
                // ),

                'urlManager' => array(
                        'urlFormat' => 'path',
                        'rules' => array(
                                // You can add your own rules here
                        ),
                        'showScriptName' => true,
                ),

        ),
        // For security issue : it's better to set runtimePath out of web access
        // Directory must be readable and writable by the webuser
        // 'runtimePath'=>'/var/limesurvey/runtime/'
        // Use the following config variable to set modified optional settings copied from config-defaults.php
        'config' => array(
                // debug: Set this to 1 if you are looking for errors. If you still get no errors after enabling this
                // then please check your error-logs - either in your hosting provider admin panel or in some /logs directory
                // on your webspace.
                // LimeSurvey developers: Set this to 2 to additionally display STRICT PHP error messages and get full access to standard templates
                'debug'    => $app_debug,
                'debugsql' => $debug_sql, // Set this to 1 to enanble sql logging, only active when debug = 2
                // Update default LimeSurvey config here
                'updatable'         => false,
                'ssl_disable_alert' => true,
                'sitename'          => $sitename,
                'siteadminemail'    => $adminemail, // The default email address of the site administrator
                'siteadminbounce'   => $bounce_email, // The default email address used for error notification of sent messages for the site administrator (Return-Path)
                'siteadminname'     => $adminname, // The name of the site administrator
                'emailmethod'       => $email_protocol, // mail, sendmail, smtp
                'protocol'          => $email_protocol,
                'emailsmtphost'     => $smtp_host, // SMTP host:port (port defaults to 25)
                'emailsmtpuser'     => $smtp_user,
                'emailsmtppassword' => $smtp_password,
                'emailsmtpssl'      => $smtp_ssl, // Set this to 'ssl' or 'tls' to use SSL/TLS for SMTP connection
                'emailsmtpdebug'    => $smtp_debug,
                'maxemails'         => $email_max,
                'uploaddir'         => "/var/www/html/upload", // Persistent upload folder, shared amongst pods
        )
);
/* End of file config.php */
/* Location: ./application/config/config.php */
