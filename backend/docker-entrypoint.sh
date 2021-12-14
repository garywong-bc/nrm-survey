#!/bin/bash
set -eu

cd /var/www/html

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
# file_env() {
# 	local var="$1"
# 	local fileVar="${var}_FILE"
# 	local def="${2:-}"
# 	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
# 		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
# 		exit 1
# 	fi
# 	local val="$def"
# 	if [ "${!var:-}" ]; then
# 		val="${!var}"
# 	elif [ "${!fileVar:-}" ]; then
# 		val="$(< "${!fileVar}")"
# 	fi
# 	export "$var"="$val"
# 	unset "$fileVar"
# }

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
    # file_env 'DB_TYPE' 'pgsql'
	# file_env 'POSTGRESQL_DB_HOST' 'db'
	# file_env 'POSTGRESQL_PORT' '5432'
	# file_env 'LIMESURVEY_TABLE_PREFIX' ''
    # file_env 'ADMIN_NAME' 'Lime Administrator'
    # file_env 'ADMIN_EMAIL' 'lime@lime.lime'
    # file_env 'ADMIN_USER' ''
    # file_env 'ADMIN_PASSWORD' ''
    # file_env 'DEBUG' '0'
    # file_env 'SQL_DEBUG' '0'

	if [ -z "$POSTGRESQL_PASSWORD" ]; then
		echo >&2 'error: missing required POSTGRESQL_PASSWORD environment variable'
		echo >&2 '  Did you forget to -e POSTGRESQL_PASSWORD=... ?'
		echo >&2
		echo >&2 '  (Also of interest might be POSTGRESQL_USERNAME and POSTGRESQL_DB_NAME.)'
		exit 1
	fi

    echo >&2 "Copying default container default config files into config volume..."
    cp -dR /var/lime/application/config/* application/config

    if ! [ -e plugins/index.html ]; then
        echo >&2 "No index.html file in plugins dir in $(pwd) Copying defaults..."
        cp -dR /var/lime/plugins/* plugins
    fi

    if ! [ -e upload/index.html ]; then
        echo >&2 "No index.html file upload dir in $(pwd) Copying defaults..."
        cp -dR /var/lime/upload/* upload
    fi

    if ! [ -e application/config/config.php ]; then
        echo >&2 "No config file in $(pwd) Copying default config file..."
		#Copy default config file but also allow for the addition of attributes
        cp /var/lime/application/config/config-nrm-$DB_TYPE.php application/config/config.php
    fi

    # see http://stackoverflow.com/a/2705678/433558
    # sed_escape_lhs() {
    #     echo "$@" | sed -e 's/[]\/$*.^|[]/\\&/g'
    # }
    # sed_escape_rhs() {
    #     echo "$@" | sed -e 's/[\/&]/\\&/g'
    # }
    # php_escape() {
    #     php -r 'var_export(('$2') $argv[1]);' -- "$1"
    # }
    # set_config() {
    #     key="$1"
    #     value="$2"
    #     sed -i "/'$key'/s>\(.*\)>$value,1"  config/config.php
    # }

    # set_config 'connectionString' "'$DB_TYPE:host=$POSTGRESQL_DB_HOST;port=$POSTGRESQL_PORT;dbname=$POSTGRESQL_DB_NAME;'"
    # set_config 'tablePrefix' "'$LIMESURVEY_TABLE_PREFIX'"
    # set_config 'username' "'$POSTGRESQL_USERNAME'"
    # set_config 'password' "'$POSTGRESQL_PASSWORD'"
	# set_config 'urlFormat' "'path'"
    # set_config 'debug' "$DEBUG"
    # set_config 'debugsql' "$SQL_DEBUG"

    # chown www-data:0 -R tmp 
    # chown www-data:0 -R plugins
    # mkdir -p upload/surveys
    # chown www-data:0 -R upload 
    # chown www-data:0 -R config

	DBSTATUS=$(TERM=dumb php -f /usr/local/bin/nrm-check-install.php)

	if [ "${DBSTATUS}" = "NOINSTALL" ]; then
        echo >&2 'Database not yet populated - installing Limesurvey database'
	    php application/commands/console.php install "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_NAME" "$ADMIN_EMAIL" verbose
	fi

    #flush asssets (clear cache on restart)
    php application/commands/console.php flushassets

fi

exec "$@"