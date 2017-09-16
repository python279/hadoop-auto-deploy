#!/bin/bash

cd `dirname $0`; cat ../config.yml | sed 's/: */=/g' > /tmp/config.sh; source /tmp/config.sh

sh create_ldap_user.sh $1 "$2"
sh create_user_keytab.sh $1
cd ..; ansible-playbook -i hosts common/gateway_user_sync.yml
