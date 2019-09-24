#!/bin/sh

MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="centreon"
MYSQL_PASSWD="c3ntr30n"
MYSQL_ROOT_PASSWORD="change123"
CENTREON_ADMIN_NAME="Administrator"
CENTREON_ADMIN_EMAIL="admin@admin.co"
CENTREON_ADMIN_PASSWD="change123"

# EMS vars
RPM_CENTREON_MAP="http://repo.centreon.com/yum/internal/19.10/el7/noarch/map-server/centreon-map-server-19.10.0-1569320612.9704d23a8/centreon-map-server-19.10.0-1569320612.9704d23a8.el7.noarch.rpm"
RPM_CENTREON_BAM="http://repo.centreon.com/yum/internal/19.10/el7/noarch/bam/centreon-bam-server-19.10.0-1569333326.a6dcd7e1/centreon-bam-server-19.10.0-1569333326.a6dcd7e1.el7.centos.noarch.rpm"
RPM_CENTREON_MBI="http://repo.centreon.com/yum/internal/19.10/el7/noarch/mbi-web/centreon-bi-server-19.10.0-1569326612.d46f005/centreon-bi-server-19.10.0-1569326612.d46f005.el7.centos.noarch.rpm"

function InstallDbCentreon() {

    CENTREON_HOST="http://localhost"
    COOKIE_FILE="/tmp/install.cookie"
    CURL_CMD="curl -q -b ${COOKIE_FILE}"

    curl -q -c ${COOKIE_FILE} ${CENTREON_HOST}/centreon/install/install.php
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=stepContent"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step3.php" \
        --data "install_dir_engine=%2Fusr%2Fshare%2Fcentreon-engine&centreon_engine_stats_binary=%2Fusr%2Fsbin%2Fcentenginestats&monitoring_var_lib=%2Fvar%2Flib%2Fcentreon-engine&centreon_engine_connectors=%2Fusr%2Flib64%2Fcentreon-connector&centreon_engine_lib=%2Fusr%2Flib%2Fcentreon-engine&centreonplugins=%2Fusr%2Flib%2Fcentreon%2Fplugins%2F"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step4.php" \
        --data "centreonbroker_etc=%2Fetc%2Fcentreon-broker&centreonbroker_cbmod=%2Fusr%2Flib64%2Fnagios%2Fcbmod.so&centreonbroker_log=%2Fvar%2Flog%2Fcentreon-broker&centreonbroker_varlib=%2Fvar%2Flib%2Fcentreon-broker&centreonbroker_lib=%2Fusr%2Fshare%2Fcentreon%2Flib%2Fcentreon-broker"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step5.php" \
        --data "admin_password=${CENTREON_ADMIN_PASSWD}&confirm_password=${CENTREON_ADMIN_PASSWD}&firstname=${CENTREON_ADMIN_NAME}&lastname=${CENTREON_ADMIN_NAME}&email=${CENTREON_ADMIN_EMAIL}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step6.php" \
        --data "address=${MYSQL_HOST}&port=${MYSQL_PORT}&root_user=root&root_password=${MYSQL_ROOT_PASSWORD}&db_configuration=centreon&db_storage=centreon_storage&db_user=${MYSQL_USER}&db_password=${MYSQL_PASSWD}&db_password_confirm=${MYSQL_PASSWD}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/configFileSetup.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/installConfigurationDb.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/installStorageDb.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/createDbUser.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/insertBaseConf.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/partitionTables.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step8.php" \
        --data "modules%5B%5D=centreon-license-manager&modules%5B%5D=centreon-pp-manager&modules%5B%5D=centreon-autodiscovery-server"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step9.php" \
        --data "send_statistics=1"
}

function installPlugins() {

    SLUGS=$(wget -O - -q 'https://api.imp.centreon.com/api/pluginpack/pluginpack?sort=catalog_level&by=asc&page[number]=1&page[size]=20')

    PLUGINS=(
      base-generic
      applications-databases-mysql
      operatingsystems-linux-snmp
      applications-monitoring-centreon-database
      applications-monitoring-centreon-central
    )

    CENTREON_HOST="http://localhost"
    CURL_CMD="curl "

    for PLUGIN in "${PLUGINS[@]}"; do
        JSON_PLUGIN="{\"slug\": \"${PLUGIN}\", \"version\": $(echo $SLUGS | jq ".data[].attributes | select(.slug | contains(\"${PLUGIN}\")).version"), \"action\": \"install\"}"
        STATUS=0
        while [ $STATUS -eq 0 ]; do
            API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
                "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
                | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
            )
            CURL_OUTPUT=$(${CURL_CMD} -X POST \
                -H "Content-Type: application/json" \
                -H "centreon-auth-token: ${API_TOKEN}"\
                -d "{\"pluginpack\":[${JSON_PLUGIN}]}" \
                "${CENTREON_HOST}/centreon/api/index.php?object=centreon_pp_manager_pluginpack&action=installupdate"
            )
            if ! [ $(echo $CURL_OUTPUT | grep "Forbidden") ]; then
                STATUS=1
            fi
        done
    done
}

function installWidgets() {
    WIDGETS=(
        engine-status
        global-health
        graph-monitoring
        grid-map
        host-monitoring
        hostgroup-monitoring
        httploader
        live-top10-cpu-usage
        live-top10-memory-usage
        service-monitoring
        servicegroup-monitoring
        tactical-overview
    )

    CENTREON_HOST="http://localhost"
    CURL_CMD="curl -q -o /dev/null"
    API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
        "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
        | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
    )

    for WIDGET in "${WIDGETS[@]}"; do
        # Install package
        yum install -y centreon-widget-${WIDGET}
        # Configure widget in Centreon
        ${CURL_CMD} -X POST \
            -H "Content-Type: application/json" \
            -H "centreon-auth-token: ${API_TOKEN}"\
            "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=${WIDGET}&type=widget"
    done
}

function installEMS() {

    # After Centreon configuration, install modules EMS
    if [ ! "$(rpm -aq | grep centreon-map-server)" ]; then
        MYSQL_HOST_CLIENT=$( \
            echo "SELECT host FROM information_schema.processlist WHERE ID=connection_id();" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST} \
            | sed 1d | cut -f1 -d":" \
        )
        echo "CREATE USER 'centreon_map'@'${MYSQL_HOST_CLIENT}' IDENTIFIED BY '${MYSQL_PASSWD}';" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST}
        echo "GRANT SELECT ON centreon_storage.* TO 'centreon_map'@'${MYSQL_HOST_CLIENT}';" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST}
        echo "GRANT SELECT, INSERT ON centreon.* TO 'centreon_map'@'${MYSQL_HOST_CLIENT}';" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST}

        yum install -y $RPM_CENTREON_MAP expect
        cd /etc/centreon-studio
        mv -v /tmp/map-install.sh /etc/centreon-studio/map-install.sh
        find /etc/centreon-studio -type f -name \*.sh | xargs chmod -v +x
        export PATH="$PATH:/etc/centreon-studio"
        sed -i \
            -e "s/##CENTREON_ADMIN_PASSWORD##/${CENTREON_ADMIN_PASSWD}/g" \
            -e "s/##CENTREON_HOST_DATABASE##/${MYSQL_HOST}/g" \
            -e "s/##CENTREON_USER_DB_PASSWORD##/${MYSQL_PASSWD}/g" \
            -e "s/##MYSQL_ROOT_PASSWORD##/${MYSQL_ROOT_PASSWORD}/g" \
            /etc/centreon-studio/map-install.sh
        ./map-install.sh
        systemctl restart cbd
        systemctl start tomcat
        systemctl enable tomcat
    fi
    if [ ! "$(rpm -aq | grep centreon-bam-server)" ]; then
        yum install -y $RPM_CENTREON_BAM
    fi
    if [ ! "$(rpm -aq | grep centreon-bi-server)" ]; then
        MYSQL_HOST_CLIENT=$( \
            echo "SELECT host FROM information_schema.processlist WHERE ID=connection_id();" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST} \
            | sed 1d | cut -f1 -d":" \
        )
        echo "CREATE USER 'centreonbi'@'${MYSQL_HOST_CLIENT}' IDENTIFIED BY '${MYSQL_PASSWD}';" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST}
        echo "GRANT SELECT ON centreon_storage.* TO 'centreonbi'@'${MYSQL_HOST_CLIENT}';" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST}
        echo "GRANT SELECT, INSERT ON centreon.* TO 'centreonbi'@'${MYSQL_HOST_CLIENT}';" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST}
        yum install -y $RPM_CENTREON_MBI
    fi

    # Install widgets
    WIDGETS=(
        bam-ba-list
        bam-ba-listing
        mbi-ba-mtbf-mtrs
        mbi-ba-availability-graph-day
        mbi-ba-availability-gauge
        mbi-ba-availability-graph-month
        mbi-bv-availability-graph-month
        mbi-hgs-hc-by-host-mtbf-mtrs
        mbi-hg-availability-by-host-graph-day
        mbi-hg-availability-by-hc-graph-month
        mbi-hgs-availability-by-hg-graph-month
        mbi-hgs-performances-Top-X
        mbi-hgs-hcs-scs-metric-performance-day
        mbi-metric-capacity-planning
        mbi-hgs-hc-by-service-mtbf-mtrs
        mbi-storage-list-near-saturation
        mbi-hgs-hc-by-service-mtbf-mtrs
        mbi-typical-performance-day
    )

    CENTREON_HOST="http://localhost"
    CURL_CMD="curl -q -o /dev/null"
    API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
        "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
        | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
    )

    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=centreon-bam-server&type=module"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=centreon-bi-server&type=module"

    for WIDGET in "${WIDGETS[@]}"; do
        # Configure widget in Centreon
        ${CURL_CMD} -X POST \
            -H "Content-Type: application/json" \
            -H "centreon-auth-token: ${API_TOKEN}"\
            "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=${WIDGET}&type=widget"
    done
}

function sendLicenses() {
    CENTREON_HOST="http://localhost"
    CURL_CMD="curl -q -o /dev/null"
    API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
        "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
        | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
    )

    ${CURL_CMD} -X POST \
        -H "accept: application/json" \
        -H "Content-Type: multipart/form-data" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        -F "file[]=@/tmp/licenses.zip" \
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_license&action=file"
}

function initialConfiguration() {
    # Add server and set snmp configuration
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HG -a add -v "Linux;Linux servers"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a ADD -v "centreon-central;Centreon Central;127.0.0.1;App-Monitoring-Centreon-Central-custom|App-Monitoring-Centreon-Database-custom;central;Linux"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a setmacro -v "centreon-central;MYSQLPASSWORD;${MYSQL_PASSWD}"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a setparam -v "centreon-central;snmp_community;public"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a setparam -v "centreon-central;snmp_version;2c"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a applytpl -v "centreon-central"

    # add a plugin to monitor each ethernet interface
    ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo' | while read IFNAME; do
        centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a add -v "centreon-central;Interface-${IFNAME};OS-Linux-Traffic-Generic-Name-SNMP"
        centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setmacro -v "centreon-central;Interface-${IFNAME};INTERFACENAME;${IFNAME}"
    done

    # add mount point from partition of system to monitor
    lsblk -o MOUNTPOINT | sed -e 1d -e '/^$/d' | while read MP; do
        centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a add -v "centreon-central;Mountpoint-${MP};OS-Linux-Disk-Generic-Name-SNMP"
        centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setmacro -v "centreon-central;Mountpoint-${MP};DISKNAME;${MP}"
    done

    # Apply configuration
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -a APPLYCFG -v 1
    systemctl restart centreon
    systemctl restart cbd
    systemctl restart centengine
}

timedatectl set-timezone Europe/Paris
setenforce 0
sed -i 's/enforcing/disabled/' /etc/selinux/config
yum upgrade -y
yum install -y centos-release-scl wget curl
yum install -y yum-utils http://yum.centreon.com/standard/19.10/el7/stable/noarch/RPMS/centreon-release-19.10-1.el7.centos.noarch.rpm
yum-config-manager --enable 'centreon-testing*'
##curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
##yum install -y centreon-base-config-centreon-engine

# Devel version
wget -O /etc/yum.repos.d/centreon-web-devel.repo http://repo.centreon.com/yum/internal/19.10/el7/noarch/web/centreon-web-19.10.0-beta.3-1568886926.1cdc58ef4/centreon-internal.repo
sed -i 's/srvi-repo.int.centreon.com/repo.centreon.com/' /etc/yum.repos.d/centreon-web-devel.repo
yum install -y centreon

echo "date.timezone = Europe/Paris" > /etc/opt/rh/rh-php72/php.d/php-timezone.ini
systemctl daemon-reload
systemctl restart mysql
mysqladmin -u root password $MYSQL_ROOT_PASSWORD # Set password to root mysql
systemctl restart rh-php72-php-fpm
systemctl restart httpd24-httpd
sleep 5 # waiting start httpd process
InstallDbCentreon # Configure database
su - centreon -c "/opt/rh/rh-php72/root/bin/php /usr/share/centreon/cron/centreon-partitioning.php"
systemctl restart cbd

# Enable all others services
systemctl enable httpd24-httpd
systemctl enable snmpd
systemctl enable snmptrapd
systemctl enable rh-php72-php-fpm
systemctl enable centcore
systemctl enable centreontrapd
systemctl enable cbd
systemctl enable centengine
systemctl enable centreon

systemctl restart rh-php72-php-fpm
systemctl stop firewalld
systemctl disable firewalld
systemctl start rh-php72-php-fpm
systemctl start httpd24-httpd
systemctl start mysqld
systemctl start cbd
systemctl start snmpd
systemctl start snmptrapd

# Install JQ tool (https://stedolan.github.io/jq/)
# to help manage json output in shell
wget -O /usr/sbin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x /usr/sbin/jq

# Install License files
sendLicenses

# Install widgets and configure
installWidgets

# Install Plugins
installPlugins

# Install EMS components
installEMS

# Apply initial configuration from owner server
initialConfiguration
