#!/bin/sh

function load_default_configuration() {

	CENTREON_ADDRESS="localhost"
	CENTREON_PROTOCOL="http://"
	CENTREON_USER="admin"
	CENTREON_PWD="##CENTREON_ADMIN_PASSWORD##"

	CENTREON_DB_ADDRESS="##CENTREON_HOST_DATABASE##"
	CENTREON_DB_PORT="3306"
	CENTREON_DB_BASE="centreon"
	CENTREON_DB_USER="centreon"
	CENTREON_DB_PWD="##CENTREON_USER_DB_PASSWORD##"

	CENTREON_STORAGE_DB_BASE="centreon_storage"
  CENTREON_STORAGE_DB_ADDRESS="##CENTREON_HOST_DATABASE##"
  CENTREON_STORAGE_DB_PORT="3306"
  CENTREON_STORAGE_DB_USER="centreon"
  CENTREON_STORAGE_DB_PWD="##CENTREON_USER_DB_PASSWORD##"

	CENTREON_BROKER_PORT="5758"
	CENTREON_BROKER_XML="central-broker.xml"
	CENTREON_BROKER_OUTPUT="Centreon-Studio"
	CENTREON_BROKER_TLS="false"

	CENTREON_STUDIO_DB_ADDRESS="localhost"
	CENTREON_STUDIO_DB_PORT="3306"
	CENTREON_STUDIO_DB_BASE="centreon_studio"
	CENTREON_STUDIO_DB_USER="centreon_map"
	CENTREON_STUDIO_DB_PWD="##CENTREON_USER_DB_PASSWORD##"
	CENTREON_STUDIO_LOGGING_PATH_DIR="/var/log/centreon-studio/"
	CENTREON_STUDIO_LOGGING_PATH_FILE="centreon-studio.log"

	MAPBOX_TOKEN=""

  CENTREON_PROTOCOL+=$CENTREON_ADDRESS
	CENTREON_ADDRESS=$CENTREON_PROTOCOL
}

function check_return() {
	if [[ $1 != 0 ]]
	then
		echo "KO => $2"
		exit 1
	fi
}

function copy_file () {
	if [[ -r $1 ]]
	then
		cp $1 $2 2>/dev/null
		check_return $? "can't copy $1"
	else
		echo "$1 isn't readable"
	fi
}

function write_change() {
	echo "################################################"
	echo "##### Centreon-Studio configuration files ######"
	echo "################################################"
	echo
	# ASK FOR CONFIGURATION OVERWRITE

	echo "-> Copying tomcat configuration file"
	yes y | ./configureTomcat.sh

  configPath="/etc/centreon-studio"
  templatePath="$configPath/templates"

	echo "-> Copying template configuration "
	if [[ -w $configPath && -r $templatePath ]]
	then
		# COPY TEMPLATES
		copy_file  "$templatePath/centreon-database.properties" "$configPath/centreon-database.properties"
		echo -n "."
		copy_file  "$templatePath/studio-config.properties" "$configPath/studio-config.properties"
		echo -n "."
		copy_file  "$templatePath/studio-database.properties" "$configPath/studio-database.properties"
		echo -n "."
		copy_file  "$templatePath/studio-log4j2.xml" "$configPath/studio-log4j2.xml"
		echo -n "."
		echo " Done!"
	else
		echo "Templates can't be used. Please check $configPath and $templatePath rights."
		exit 1
	fi

	echo -n "-> Create log directory "
	mkdir $CENTREON_STUDIO_LOGGING_PATH_DIR
	chown tomcat:root $CENTREON_STUDIO_LOGGING_PATH_DIR

	# REPLACE MACRO
	echo -n "-> Replacing macro inside configuration files "

	sed -i "s|%%CENTREON_STUDIO_LOGGING_PATH_FILE%%|$CENTREON_STUDIO_LOGGING_PATH_FILE|g" "$configPath/studio-log4j2.xml"

	sed -i "s|%CENTREON_DB_ADDRESS%|$CENTREON_DB_ADDRESS|g" "$configPath/centreon-database.properties"
	sed -i "s|%CENTREON_DB_PORT%|$CENTREON_DB_PORT|g" "$configPath/centreon-database.properties"
	sed -i "s|%CENTREON_DB_BASE%|$CENTREON_DB_BASE|g" "$configPath/centreon-database.properties"
	sed -i "s|%CENTREON_DB_USER%|$CENTREON_DB_USER|g" "$configPath/centreon-database.properties"
	sed -i "s|%CENTREON_DB_PWD%|$CENTREON_DB_PWD|g" "$configPath/centreon-database.properties"

	sed -i "s|%CENTREON_STORAGE_DB_ADDRESS%|$CENTREON_STORAGE_DB_ADDRESS|g" "$configPath/centreon-database.properties"
	sed -i "s|%CENTREON_STORAGE_DB_PORT%|$CENTREON_STORAGE_DB_PORT|g" "$configPath/centreon-database.properties"
	sed -i "s|%CENTREON_STORAGE_DB_BASE%|$CENTREON_STORAGE_DB_BASE|g" "$configPath/centreon-database.properties"
	sed -i "s|%CENTREON_STORAGE_DB_USER%|$CENTREON_STORAGE_DB_USER|g" "$configPath/centreon-database.properties"
	sed -i "s|%CENTREON_STORAGE_DB_PWD%|$CENTREON_STORAGE_DB_PWD|g" "$configPath/centreon-database.properties"

	sed -i "s|%CENTREON_STUDIO_DB_ADDRESS%|$CENTREON_STUDIO_DB_ADDRESS|g" "$configPath/studio-database.properties"
	sed -i "s|%CENTREON_STUDIO_DB_PORT%|$CENTREON_STUDIO_DB_PORT|g" "$configPath/studio-database.properties"
	sed -i "s|%CENTREON_STUDIO_DB_BASE%|$CENTREON_STUDIO_DB_BASE|g" "$configPath/studio-database.properties"
	sed -i "s|%CENTREON_STUDIO_DB_USER%|$CENTREON_STUDIO_DB_USER|g" "$configPath/studio-database.properties"
	sed -i "s|%CENTREON_STUDIO_DB_PWD%|$CENTREON_STUDIO_DB_PWD|g" "$configPath/studio-database.properties"

	sed -i "s|%CENTREON_BROKER_ADDRESS%|$CENTREON_BROKER_ADDRESS|g" "$configPath/studio-config.properties"
	sed -i "s|%CENTREON_BROKER_PORT%|$CENTREON_BROKER_PORT|g" "$configPath/studio-config.properties"
	sed -i "s|%CENTREON_BROKER_TLS%|$CENTREON_BROKER_TLS|g" "$configPath/studio-config.properties"
	sed -i "s|%CENTREON_ADDRESS%|$CENTREON_ADDRESS|g" "$configPath/studio-config.properties"
	sed -i "s|%CENTREON_USER%|$CENTREON_USER|g" "$configPath/studio-config.properties"
	sed -i "s|%CENTREON_PWD%|$CENTREON_PWD|g" "$configPath/studio-config.properties"
	sed -i "s|%MAPBOX_TOKEN%|$MAPBOX_TOKEN|g" "$configPath/studio-config.properties"
	sed -i "s|%MAPBOX_MAP%|$MAPBOX_MAP|g" "$configPath/studio-config.properties"

	echo "... Done!"
}

function configure_broker() {

	echo "################################################"
	echo "############ Centreon broker Output ############"
	echo "################################################"
	echo
	echo '/!\ The user you have configured to access Centreon database must have INSERT permission on Centreon DB /!\'

	SQL_COUNT_CONFIG="SELECT count(*) FROM cfg_centreonbroker_info WHERE config_value LIKE '$CENTREON_BROKER_OUTPUT'"
	SQL_CONFIG_GROUP_ID="SELECT MAX(config_group_id)+1 as config_group_id FROM cfg_centreonbroker_info"
	SQL_CONFIG_ID="SELECT min(config_id) FROM cfg_centreonbroker WHERE config_filename LIKE '$CENTREON_BROKER_XML'"

	echo
	echo -n "-> Check if Centreon-Broker output for Centreon-Studio exist (using previously configured access) : "
	BROKER_CONFIG_EXIST=$(mysql -h $CENTREON_DB_ADDRESS -P $CENTREON_DB_PORT -u $CENTREON_DB_USER -p$CENTREON_DB_PWD -e "$SQL_COUNT_CONFIG" $CENTREON_DB_BASE | tail -1)
	check_return $? "can't connect or execute query $SQL_COUNT_CONFIG ... Exiting, please run this script again."

	if [[ $BROKER_CONFIG_EXIST == "0" ]]
	then
		echo -n "Centreon-Broker configuration for Centreon-Studio not found. Creating "

		CONFIG_GROUP_ID=`mysql -h $CENTREON_DB_ADDRESS -P $CENTREON_DB_PORT -u $CENTREON_DB_USER -p$CENTREON_DB_PWD -e "$SQL_CONFIG_GROUP_ID" $CENTREON_DB_BASE | tail -1`
		check_return $? "can't connect or execute query $SQL_CONFIG_GROUP_ID ... Exiting, please run this script again."
		CONFIG_ID=`mysql -h $CENTREON_DB_ADDRESS -P $CENTREON_DB_PORT -u $CENTREON_DB_USER -p$CENTREON_DB_PWD -e "$SQL_CONFIG_ID" $CENTREON_DB_BASE | tail -1`
		check_return $? "can't connect or execute query $SQL_CONFIG_ID ... Exiting, please run this script again."

		SQL_CREATE_OUTPUT="INSERT INTO cfg_centreonbroker_info (config_id, config_key, config_value, config_group, config_group_id, grp_level, subgrp_id, parent_grp_id) VALUES "
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'name', '$CENTREON_BROKER_OUTPUT', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'port', '$CENTREON_BROKER_PORT', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'host', '', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'failover', '', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'retry_interval', '', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'buffering_timeout', '0', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'protocol', 'bbdo', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'tls', 'auto', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'private_key', '', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'public_cert', '', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'ca_certificate', '', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'negociation', 'yes', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'one_peer_retention_mode', 'no', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'filters', '', 'output', $CONFIG_GROUP_ID, 0, 1, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'category', 'bam', 'output', $CONFIG_GROUP_ID, 1, NULL, 1),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'category', 'neb', 'output', $CONFIG_GROUP_ID, 1, NULL, 1),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'compression', 'auto', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'compression_level', '', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'compression_buffer', '', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'type', 'ipv4', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL),"
		SQL_CREATE_OUTPUT="$SQL_CREATE_OUTPUT ($CONFIG_ID, 'blockId', '1_3', 'output', $CONFIG_GROUP_ID, 0, NULL, NULL);"

		CREATED=`mysql -h $CENTREON_DB_ADDRESS -P $CENTREON_DB_PORT -u $CENTREON_DB_USER -p$CENTREON_DB_PWD -e "$SQL_CREATE_OUTPUT" $CENTREON_DB_BASE`
		check_return $? "can't connect or execute query $SQL_CREATE_OUTPUT ... Exiting, please run this script again."
		echo "... Done."
	else
		echo "Centreon-Broker configuration for Centreon-Studio found. Ignored."
	fi
}

function configure_db_studio() {

	echo "################################################"
	echo "############## DB Configuration ################"
	echo "################################################"
	echo

	login="root"
	password="##MYSQL_ROOT_PASSWORD##"

	creationSuccess=1
	while [ $creationSuccess -ne 0 ]
	do
		if [[ "$password" != "" ]]
		then
			temp="-p"
			temp+=$password
			password=$temp
		fi

		SQL_HOST_CLIENT="$( \
			echo "SELECT host FROM information_schema.processlist WHERE ID=connection_id();" \
			| mysql -N -u ${login} ${password} -h ${CENTREON_STUDIO_DB_ADDRESS} -P $CENTREON_STUDIO_DB_PORT \
			| cut -f1 -d":" \
		)"

		SQL_CREATE_STUDIO_DB="CREATE DATABASE $CENTREON_STUDIO_DB_BASE;"
		SQL_CREATE_STUDIO_USER="CREATE USER '$CENTREON_STUDIO_DB_USER'@'$SQL_HOST_CLIENT' IDENTIFIED BY '$CENTREON_STUDIO_DB_PWD';"
		SQL_GRANT_STUDIO_USER="GRANT ALL ON $CENTREON_STUDIO_DB_BASE.* TO '$CENTREON_STUDIO_DB_USER'@'$SQL_HOST_CLIENT' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"
		SQL_SET_COLLATION="ALTER DATABASE $CENTREON_STUDIO_DB_BASE CHARACTER SET utf8 COLLATE utf8_general_ci;"

		table=`mysql -sN -h $CENTREON_STUDIO_DB_ADDRESS -P $CENTREON_STUDIO_DB_PORT -u $login $password -e "show databases;" 2>/dev/null | grep "^$CENTREON_STUDIO_DB_BASE$"`
		echo -n "Creating $CENTREON_STUDIO_DB_BASE database : "
		if [[ $table == "" ]]
		then
			`mysql -h $CENTREON_STUDIO_DB_ADDRESS -P $CENTREON_STUDIO_DB_PORT -u $login $password -e "$SQL_CREATE_STUDIO_DB" 2>/dev/null`
			creationSuccess=$?
			if [[ $creationSuccess -ne 0 ]]
			then
				echo "can't connect or execute query $SQL_CREATE_STUDIO_DB ... Please try again."
				continue
			else
				echo "OK, Done !"
			fi
		else
			echo "database already exists => no modifications."
			creationSuccess=0
		fi

		user=`mysql -sN -h $CENTREON_STUDIO_DB_ADDRESS -P $CENTREON_STUDIO_DB_PORT -u $login $password -e "select Host,User from mysql.user where User='$CENTREON_STUDIO_DB_USER' and Host='$SQL_HOST_CLIENT'" 2>/dev/null`
		echo -n "Creating $CENTREON_STUDIO_DB_USER user for $SQL_HOST_CLIENT: "
		if [[ $user == "" ]]
		then
			`mysql -h $CENTREON_STUDIO_DB_ADDRESS -P $CENTREON_STUDIO_DB_PORT -u $login $password -e "$SQL_CREATE_STUDIO_USER" 2>/dev/null`
			creationSuccess=$?
			if [[ $creationSuccess -ne 0 ]]
			then
				echo "can't connect or execute query $SQL_CREATE_STUDIO_USER ... Exiting, please run this script again."
				continue
			else
				echo "OK, Done !"
			fi
		else
			creationSuccess=0
			echo "user already exists => no modifications."
		fi

		echo -n "Granting $CENTREON_STUDIO_DB_USER user: "
		`mysql -h $CENTREON_STUDIO_DB_ADDRESS -P $CENTREON_STUDIO_DB_PORT -u $login $password -e "$SQL_GRANT_STUDIO_USER" 2>/dev/null`
		creationSuccess=$?
		if [[ $creationSuccess -ne 0 ]]
		then
			echo "can't connect or execute query $SQL_GRANT_USER_STUDIO ... Exiting, please run this script again."
			continue
		fi

		echo -n "Setting UTF8 for database: "
		`mysql -h $CENTREON_STUDIO_DB_ADDRESS -P $CENTREON_STUDIO_DB_PORT -u $login $password -e "$SQL_SET_COLLATION" 2>/dev/null`
		creationSuccess=$?
		if [[ $creationSuccess -ne 0 ]]
		then
			echo "can't connect or execute query $SQL_GRANT_USER_STUDIO ... Exiting, please run this script again."
			continue
		fi
		echo "OK, Done !"
	done
}

function post_installation() {
	echo "Configuration completed"
	echo "Enjoy !"
}

###################################################################################
# SCRIPT RUNNER ###################################################################
###################################################################################
load_default_configuration
echo
write_change
echo
configure_broker
echo
configure_db_studio
echo
post_installation
