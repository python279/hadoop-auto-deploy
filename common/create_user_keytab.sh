#!/bin/bash
#create kerberos pricipal and credantial for user
#usage: bash create_user_keytab.sh username

cd `dirname $0`; cat ../config.yml | sed 's/: */=/g' > /tmp/config.sh; source /tmp/config.sh
UPPER_PATH=..

u=$1
pw=$(date | md5sum | awk '{print substr($1,0,8)}')

if grep "^$u:" $UPPER_PATH/accounts.txt > /dev/null 2>&1; then
	echo "keytab for $u is already existing"
	if [ ! -e $UPPER_PATH/keytab/$u.keytab ]; then
		kadmin.local -q "ktadd -norandkey -k $UPPER_PATH/keytab/$u.keytab $u" > /dev/null 2>&1
		chmod 400 $UPPER_PATH/keytab/$u.keytab
		chown $u:$u $UPPER_PATH/keytab/$u.keytab
	fi
	exit 0
else
	if kadmin.local -q "addprinc -pw $pw $u" > /dev/null 2>&1; then
		if kadmin.local -q "ktadd -norandkey -k $UPPER_PATH/keytab/$u.keytab $u" > /dev/null 2>&1; then
			chmod 400 $UPPER_PATH/keytab/$u.keytab
			chown $u:$u $UPPER_PATH/keytab/$u.keytab
			flock -x -w 5 $UPPER_PATH/accounts.txt -c "echo $u:$pw >> $UPPER_PATH/accounts.txt"
			echo "keytab for $u is created successfully"
			exit 0
		else
			kadmin.local -q "delprinc -force $u" > /dev/null 2>&1
		fi
	fi
	echo "failed to create keytab for $u"
	exit 128
fi
