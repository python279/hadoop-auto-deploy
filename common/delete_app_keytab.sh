#!/bin/bash
#delete kerberos pricipal and credantial of app and host
#usage: bash delete_app_keytab.sh app host


cd `dirname $0`; cat ../config.yml | sed 's/: */=/g' > /tmp/config.sh; source /tmp/config.sh

a=$1
h=$2

if kadmin.local -q "listprincs" | grep "$a/$h"; then
	if kadmin.local -q "delprinc -force $a/$h" > /dev/null 2>&1; then
		echo "$a/$h is deleted successfully"
		exit 0
	else
		echo "failed to delete $a/$h"
		exit 128
	fi
else
	echo "$a/$h is not existing"
	exit 128
fi
