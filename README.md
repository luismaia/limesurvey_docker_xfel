European XFEL limesurvey Docker image
=====================================

Out of the box LimeSurvey (PHP+APACHE) in use at European XFEL. 
This Docker image was inspired in https://hub.docker.com/r/crramirez/limesurvey/

In addition to the original Docker image, this image:

1. Uses 2 Environment variables:
    * **LIMESURVEY_SUBDOMAIN** (e.g. "" or "survey/")
    * **LOCAL_MYSQL** ("true" if using the container MySQL; "false" if using external MySQL) 
2. Adds European XFEL users and administrators pages theme
3. Sets LDAP configuration to European XFEL
4. Installs Apache SSL modules
5. Defines the following volumes that will only be populated the first time the container is run
    * "/app/survey/tmp"
    * "/app/survey/upload"
    * "/app/survey/application/config"
    * "/var/lib/mysql" (this was already given)

## Usage

To create the image ```maial/limesurvey```, execute the following command on the source folder:
```
docker build -t maial/limesurvey .
```
You can now push your new image to the registry:
```
docker push maial/limesurvey
```

## Running your LimeSurvey docker image

Start your image binding the host ports 8080, 4440 and 3306 in all interfaces to your container ports 80, 443 and 3306 respectively:
```
docker run --name survey_prod -d \
	--publish 8080:80 --publish 4440:443 --publish 3306:3306 \
	--volume /srv/docker/limesurvey/tmp:/app/survey/tmp \
	--volume /srv/docker/limesurvey/upload:/app/survey/upload \
	--volume /srv/docker/limesurvey/application/config:/app/survey/application/config \
	--volume /srv/docker/limesurvey/mysql:/var/lib/mysql \
	maial/limesurvey
```

In European XFEL, since we aren't running MySQL locally in the container and we only use SSL, to start the image we are running:
```
docker run --name survey_prod -d \
	--publish 4440:443 --env 'LIMESURVEY_SUBDOMAIN="survey/"' \
	--volume /srv/docker/limesurvey/tmp:/app/survey/tmp \
	--volume /srv/docker/limesurvey/upload:/app/survey/upload \
	--volume /srv/docker/limesurvey/application/config:/app/survey/application/config \
	maial/limesurvey
```

Test your deployment:
```
curl http://localhost/
```

## Upgrading

To upgrade Limesurvey version, the following steps are necessary:

0. *Only if you aren't using volumes* you may need to backup the files in the following directories:
    * "/app/survey/tmp"
    * "/app/survey/upload"
    * "/app/survey/application/config"
    * "/var/lib/mysql"

1. Update Limesurvey version in Dockerfile
```
# Check the link to the latest stable version of Limesurvey at https://www.limesurvey.org/en/stable-release
# Update the old link by the latest one in Dockerfile file
```

2. Create the new image
```
docker build -t maial/limesurvey .
```

3. Stop and remove the currently running image
```
docker stop survey_prod && docker rm survey_prod
```

4. Start the image
```
docker run --name survey_prod -d [OPTIONS] maial/limesurvey
```

5. Validate data directories:
    1. If you **are using volumes** check if any of the files under ```/app/survey/application/config``` has change and needs to be copied manually
    2. If you **aren't using volumes** you may need to copy the backuped files to the following directories:
        * "/app/survey/tmp"
        * "/app/survey/upload"
        * "/app/survey/application/config"
        * "/var/lib/mysql"


## Shell Access

For debugging and maintenance purposes you may want access the containers shell. 
If you are using docker version 1.3.0 or higher you can access a running containers shell using docker exec command.
```
docker exec -it survey_prod bash
```

## Testing images

In case you want to test the generated image in another host without pushing it to the Docker repository:
```
docker save --output=maial_limesurvey.tar.gz maial/limesurvey
scp maial_limesurvey.tar.gz root@SERVER_NAME:/tmp
docker load < /tmp/maial_limesurvey.tar.gz
```
