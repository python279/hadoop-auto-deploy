#!/bin/bash
#delete kerberos pricipal and credantial of user
#usage: bash delete_user_keytab.sh username

cd `dirname $0`; cat ../config.yml | sed 's/: */=/g' > /tmp/config.sh; source /tmp/config.sh
UPPER_PATH=..

u=$1

if grep "^$u:" $UPPER_PATH/accounts.txt > /dev/null 2>&1; then
	if kadmin.local -q "delprinc -force $u" > /dev/null 2>&1; then
		rm -f $UPPER_PATH/keytab/$u.keytab
		flock -x -w 5 $UPPER_PATH/accounts.txt -c "sed -i "/^${u}:/d" $UPPER_PATH/accounts.txt"
		echo "keytab for $u is deleted successfully"
		exit 0
	else
		echo "failed to delete keytab for $u"
		exit 127
	fi
else
	echo "keytab for $u is not existing"
	exit 0
fi
