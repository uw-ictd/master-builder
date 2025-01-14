#!/bin/bash

source ../root.conf
source ./.env

workdir=`pwd`
mkdir -p $RADIUSDESK_VOLUME
mkdir -p $RADIUSDESK_VOLUME/web
mkdir -p $RADIUSDESK_VOLUME/web_conf
mkdir -p $RADIUSDESK_VOLUME/db
mkdir -p $RADIUSDESK_VOLUME/db_conf
mkdir -p $RADIUSDESK_VOLUME/db_startup
mkdir -p $RADIUSDESK_VOLUME/freeradius
mkdir -p $RADIUSDESK_VOLUME/freeradius_conf

# Get code from github
cd $RADIUSDESK_VOLUME/web
mkdir -p html
git clone https://github.com/RADIUSdesk/rdcore.git


# Prepare directories for radiusdesk nginx and php
# We will create soft links in the directory where Nginx will serve the RdCore contents.
cd $RADIUSDESK_VOLUME/web/html
ln -s ../rdcore/rd ./rd
ln -s ../rdcore/cake3 ./cake3
ln -s ../rdcore/login ./login
ln -s ../rdcore/AmpConf/build/production/AmpConf ./conf_dev
ln -s ../rdcore/login/rd_client/build/production/AmpConf ./usage
ln -s ../rdcore/cake3/rd_cake/setup/scripts/reporting ./reporting

# Create requried directories
mkdir -p $RADIUSDESK_VOLUME/web/html/cake3/rd_cake/logs
mkdir -p $RADIUSDESK_VOLUME/web/html/cake3/rd_cake/webroot/files/imagecache
mkdir -p $RADIUSDESK_VOLUME/web/html/cake3/rd_cake/tmpls

# Get Sanchez JS Ext 7
#wget  https://trials.sencha.com/cmd/7.5.0.5/no-jre/SenchaCmd-7.5.0.5-linux-amd64.sh.zip
sudo apt install subversion
svn checkout svn://svn.code.sf.net/p/radiusdesk/code/extjs ./
mv ext-6-2-sencha_cmd.tar.gz ./rd
rm *.zip 
rm *.gz
cd ./rd
tar -xzvf ext-6-2-sencha_cmd.tar.gz
rm *.gz

cd $workdir
# place nginx config file in shared config directory
cp ./default.conf $RADIUSDESK_VOLUME/web_conf

# Fix the configs 
### NEED CODE HERE TO FIX DATABASE REFERENCE
sed  -i  "s/'host' => 'localhost'/'host' => 'rdmariadb'/g"  $RADIUSDESK_VOLUME/web/html/cake3/rd_cake/vendor/cakephp/cakephp/src/Database/Driver/Mysql.php
sed  -i  "s/'password' => ''/'password' => 'rd'/g"  $RADIUSDESK_VOLUME/web/html/cake3/rd_cake/vendor/cakephp/cakephp/src/Database/Driver/Mysql.php
sed  -i  "s/'database' => 'cake'/'database' => 'rd'/g"  $RADIUSDESK_VOLUME/web/html/cake3/rd_cake/vendor/cakephp/cakephp/src/Database/Driver/Mysql.php
sed  -i  "s/'host' => 'localhost'/'host' => 'rdmariadb'/g" $RADIUSDESK_VOLUME/web/html/cake3/rd_cake/config/app.php

# Prepare database configuration
cp ./my_custom.cnf $RADIUSDESK_VOLUME/db_conf

# Prepare database startup files
# Note this directory will be mounted as /docker-entrypoint-initdb.d on docker - docker instance will 
# execute all sql files in this directory the first time in alphabetical order
cp $RADIUSDESK_VOLUME/web/rdcore/cake3/rd_cake/setup/db/rd.sql $RADIUSDESK_VOLUME/db_startup
## FIXME - this causes mariadb to fail to come up cp ./db_priveleges.sql $RADIUSDESK_VOLUME/db_startup

# Prepare files for freeradius
# See Dockerfile-freeradius - custome image built for freeradius
# tar xzf $RADIUSDESK_VOLUME/web/rdcore/cake3/rd_cake/setup/radius/freeradius-3-radiusdesk.tar.gz -C $RADIUSDESK_VOLUME/freeradius --strip-components=1
# cp ./freeradius.service $RADIUSDESK_VOLUME/freeradius_conf

# Fix the Freeradius config to point to our new database
cp $RADIUSDESK_VOLUME/web/rdcore/cake3/rd_cake/setup/radius/freeradius-3-radiusdesk.tar.gz .
tar xzf freeradius-3-radiusdesk.tar.gz
sed  -i 's/server = \"localhost\"/server = \"rdmariadb\"/g'  ./freeradius/mods-available/sql
#sed  -i 's/raddbdir = \/etc\/freeradius\/3.0/raddbdir = \/etc\/freeradius\//g' ./freeradius/radiusd.conf
tar czvf  freeradius-3-radiusdesk.tar.gz ./freeradius


docker-compose config
docker-compose build
docker-compose up -d