#!/bin/bash
#create kerberos pricipal and credantial for app
#usage: bash create_app_keytab.sh app hostname keytab_file

cd `dirname $0`; cat ../config.yml | sed 's/: */=/g' > /tmp/config.sh; source /tmp/config.sh

a=$1
h=$2
k=$3

if kadmin.local -q "listprincs" | grep "$a/$h"; then
        # if exists, just export it to keytab_file
        if [ -e $k ]; then
                if klist -kt $k | grep "$a/$h"; then
                        echo "$a/$h is created successfully"
                        exit 0
                else
                        if kadmin.local -q "ktadd -norandkey -k $k $a/$h" > /dev/null 2>&1; then
                                echo "$a/$h is created successfully"
                                exit 0
                        fi
                fi
        else
                if kadmin.local -q "ktadd -norandkey -k $k $a/$h" > /dev/null 2>&1; then
                        echo "$a/$h is created successfully"
                        exit 0
                fi
        fi
else
        # if not exists, create it and export it to keytab_file
        if kadmin.local -q "addprinc -randkey $a/$h" > /dev/null 2>&1; then
                if kadmin.local -q "ktadd -norandkey -k $k $a/$h" > /dev/null 2>&1; then
                        echo "$a/$h is created successfully"
                        exit 0
                fi
        fi
fi

# failed
echo "failed to create $a/$h"
exit 128
