#!/bin/bash

echo "Checking Variable settings."

. ./settings/nc_setup/nextcloud.cfg

#Admin password should be a random hash in the end
if [ -z "$ADMIN_PASSWORD" ]
then
      echo "You did not enter an admin password, please set an admin password before starting the installation"
      exit
fi

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
    uservar=  </dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 32  ; 
    passvar=  </dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 32  ; 
    

fi

echo "$uservar"

echo "$passvar"



