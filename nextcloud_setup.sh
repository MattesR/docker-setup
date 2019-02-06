#!/bin/bash

echo "Checking Variable settings."

. ./settings/nc_setup/nextcloud.cfg

#Admin password should be a random hash in the end, or set by the user, for now, I disable setting via cfg
# if [ -z "$ADMIN_PASSWORD" ]
# then
     # echo "You did not enter an admin password, please set an admin password before starting the installation"
     # exit
# fi

echo "running first time installation of nextcloud"
      
# if the user does not input a uesrname and password for the web-admin, the web admin credentials will be random strings
read -p $'Set the web-admin Username, leave blank -> no web admin: \n' uservar
if  ( ! [ -z "$uservar" ] )
then
    while [ $passvar != $passvar2 ]
    do
        unset passvar
        unset passvar2
        read -sp $'Set the Password: \n' passvar
        read -sp $'Retype, please: \n' passvar2
        if  [ $passvar != $passvar2 ] 
        then 
            echo "passwords don't match"
        else
            echo "username and password set"
        fi
    done
else
    uservar= </dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 32  ; 
    passvar= </dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 32  ; 
    

fi


echo "creating directories"
mkdir -p ./collections/ncsync
chown -R 33:33 ./collections/ncsync

mkdir -p ./volumes/snoop-pg--ncsyc
mkdir -p ./volumes/nextcloud
chown -R 33:33 ./volumes/nextcloud
chmod g+s ./volumes/nextcloud



      
#install nextcloud via command line. Variables are set in nextcloud.cfg

echo "installing Nextcloud"
#If you use Docker for Windows and use a bash shell, you have to add winpty in front of all Docker commands. Don't use Windows! 
docker-compose exec --user www-data nextcloud php occ  maintenance:install \
--database=$DATABASE_TYPE --database-host=$DATABASE_HOST --database-name=$DATABASE_NAME \
--database-user=$DATABASE_USER --database-pass=$DATABASE_PW \
--admin-user=$uservar --admin-pass=$passvar


echo "copying custom config file"

cp ./settings/nc_setup/nextcloud_config.php ./$NEXTCLOUD_BASE_DIR/config/custom.config.php

#Read which apps are to be disabled from disable.cfg and disable the apps.
#The While loops breaks when using docker-compose exec in in, that's why it's necessary to store the umwanted app in an array first.

echo "Disabling unwanted apps"
items_to_disable=()

while IFS='' read -r line || [[ -n "$line" ]]; do    
    items_to_disable+=($line)   
done < ./settings/nc_setup/disable.cfg

for i in "${items_to_disable[@]}"
do
    echo "Disabling $i"
        docker-compose exec  --user www-data nextcloud php occ app:disable $i
done

echo "Create nextcloud-sync" 

docker-compose exec -u www-data nextcloud php occ user:add --password-from-env --display-name="ncsync" ncsync


echo "done"

docker-compose run --rm snoop--ncsync ./manage.py initcollection 

docker-compose run --rm search ./manage.py addcollection ncsync --index ncsync http://snoop--ncsync/collection/json --public
