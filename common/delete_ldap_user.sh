#!/bin/bash
# delete ldap group, user
# usage: bash delete_ldap_user.sh username

cd `dirname $0`; cat ../config.yml | sed 's/: */=/g' > /tmp/config.sh; source /tmp/config.sh

u=$1
g=$u
backup=`sleep 1 && date +%s`.ldif

# backup the whole ldap db
ldapsearch -x -h $ldap -b "dc=$domain1,dc=$domain2" > backup/$backup

if ldapsearch -x -h $ldap -b "uid=$u,ou=People,dc=$domain1,dc=$domain2" > /dev/null 2>&1; then

cat > /tmp/scheduler.ldif<<EOF
dn: cn=scheduler,ou=Group,dc=$domain1,dc=$domain2
changetype: modify
delete: memberUid
memberUid: $u
EOF
ldapmodify -x -D "cn=admin,ou=ldap,ou=admin,dc=$domain1,dc=$domain2" -w $ldap_pw -h $ldap -f /tmp/scheduler.ldif > /dev/null 2>&1

ldapdelete -x -D "cn=admin,ou=ldap,ou=admin,dc=$domain1,dc=$domain2" -w $ldap_pw -h $ldap "uid=$u,ou=People,dc=$domain1,dc=$domain2" > /dev/null 2>&1
ldapdelete -x -D "cn=admin,ou=ldap,ou=admin,dc=$domain1,dc=$domain2" -w $ldap_pw -h $ldap "cn=$u,ou=Group,dc=$domain1,dc=$domain2" > /dev/null 2>&1

echo "$u is deleted successfully in ldap"
exit 0

else

echo "$u is not existing in ldap"
exit 0

fi
