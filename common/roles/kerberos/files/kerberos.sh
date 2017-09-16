#!/bin/sh

# workaround for kerberos login
export KRB5CCNAME=FILE:/tmp/krb5cc_`id -u`
