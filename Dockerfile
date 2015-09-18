FROM tutum/lamp

ENV BUILD=-1

RUN apt-get update ; \
	apt-get upgrade -q -y ;\
	apt-get install -q -y vim ;\
	apt-get install -q -y curl php5-gd php5-ldap php5-imap; apt-get clean ; \
	php5enmod imap

ENV LIMESURVEY_SUBDOMAIN="survey/" \
	LOCAL_MYSQL="false"

RUN rm -rf /app; \
	mkdir -p /app/${LIMESURVEY_SUBDOMAIN}; \
	curl -L -o /app/limesurvey.tar.bz2 https://www.limesurvey.org/en/stable-release?download=1348:limesurvey206plus-build150911tarbz2 ; \
	tar --strip-components=1 -C /app/${LIMESURVEY_SUBDOMAIN} -xvjf /app/limesurvey.tar.bz2 ; \
	rm  /app/limesurvey.tar.bz2 ; \
	chown -R www-data:www-data /app

# European XFEL users template
# svn co https://svnsrv.desy.de/desy/EuXFEL/WP76/web_services/_xfel_survey/ svn_limesurvey_xfel_template
# cd svn_limesurvey_xfel_template/upload/templates/
# tar -jcvf limesurvey_xfel_template.tar.bz2 xfel/
ADD limesurvey_xfel_template.tar.bz2 /app/${LIMESURVEY_SUBDOMAIN}upload/templates/

# European XFEL administrators template
# svn co https://svnsrv.desy.de/desy/EuXFEL/WP76/web_services/_xfel_survey/ svn_limesurvey_xfel_template
# cd svn_limesurvey_xfel_template/styles/
# tar -jcvf limesurvey_xfel_styles.tar.bz2 xfel/
ADD limesurvey_xfel_styles.tar.bz2 /app/${LIMESURVEY_SUBDOMAIN}styles/

RUN chown -R www-data:www-data /app
RUN chown www-data:www-data /var/lib/php5

# Copy source code to /tmp folder in order to have the Application files
# needed to populate the mounted volumes for the first time the Application
# is installed (validated in "entrypoint.sh" script)
RUN rm -Rf /tmp/survey_src/ ; \
	cp -rf /app/survey/ /tmp/survey_src/

# LDAP configuration
RUN echo "TLS_REQCERT never \n\
" >> /etc/ldap/ldap.conf

# Install Apache SSL modules
RUN a2ensite default-ssl
RUN a2enmod ssl
RUN /etc/init.d/apache2 restart

ADD apache_default /etc/apache2/sites-available/000-default.conf

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 80
VOLUME ["/app/survey/tmp", "/app/survey/upload", "/app/survey/application/config"]

CMD ["/bin/bash", "/sbin/entrypoint.sh"]
