#!/bin/bash

# Apache
sed -ri -e "s/^upload_max_filesize.*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" \
    -e "s/^post_max_size.*/post_max_size = ${PHP_POST_MAX_SIZE}/" /etc/php5/apache2/php.ini

# MySQL volume mount
if [ "$LOCAL_MYSQL" = "true" ]; then
    VOLUME_HOME="/var/lib/mysql"

    if [[ ! -d $VOLUME_HOME/mysql ]]; then
        echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
        echo "=> Installing MySQL ..."
        mysql_install_db > /dev/null 2>&1
        echo "=> Done!"
        /create_mysql_admin_user.sh
    else
        echo "=> Using an existing volume of MySQL"
    fi
else
    echo "=> Using an external MySQL installation"
    mv /etc/supervisor/conf.d/supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf_disable
    /etc/init.d/mysql stop
fi

# Data and configuration volumes mount
if [ ! -f /app/survey/tmp/readme.txt ] || [ ! -f /app/survey/upload/readme.txt ] || [ ! -f /app/survey/application/config/config.php ]; then
    # Application tmp files
    if [ ! -f /app/survey/tmp/readme.txt ]; then
        cp -rf /tmp/survey_src/tmp/* /app/survey/tmp/
    fi

    # Application upload files
    if [ ! -f /app/survey/upload/readme.txt ]; then
        cp -rf /tmp/survey_src/upload/* /app/survey/upload/
    fi

    # Application application/config files
    if [ ! -f /app/survey/application/config/config.php ]; then
        cp -rf /tmp/survey_src/application/config/* /app/survey/application/config/
    fi

    chown -R www-data:www-data /app
    # rm -rf /app/survey_src/
fi

exec supervisord -n
