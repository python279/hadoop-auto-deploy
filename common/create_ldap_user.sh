#!/bin/bash
# create ldap group, user
# usage: bash create_ldap_user.sh username groups


function create_ldap_user_internal()
{

u=$1
g=$u
groups=$2
backup=`sleep 1 && date +%s`.ldif
if [ ! -e backup ]; then
  mkdir backup
fi

# backup the whole ldap db
ldapsearch -x -h $ldap -b "dc=$domain1,dc=$domain2" > backup/$backup

if ldapsearch -x -h $ldap -b "uid=$u,ou=People,dc=$domain1,dc=$domain2" > /dev/null 2>&1; then

echo "$u is already existing in ldap"
return 0

else

max_id=$(ldapsearch -x -h $ldap -b "ou=Group,dc=$domain1,dc=$domain2"  | grep gidNumber | awk '{print $2;}' | sort | tail -n 1)
if [ -z $max_id ]; then
  max_id=100000
else
  max_id=$(expr $max_id + 1)
fi

cat > /tmp/$u.ldif<<EOF
dn: cn=$g,ou=Group,dc=$domain1,dc=$domain2
objectClass: posixGroup
objectClass: top
cn: $g
gidNumber: $max_id

dn: uid=$u,ou=People,dc=$domain1,dc=$domain2
objectClass: posixAccount
objectClass: top
objectClass: inetOrgPerson
gidNumber: $max_id
givenName: $u
sn: $u
displayName: $u
uid: $u
homeDirectory: /home/$u
loginShell: /bin/bash
cn: $u
uidNumber: $max_id
EOF
ldapadd -x -D "cn=admin,ou=ldap,ou=admin,dc=$domain1,dc=$domain2" -w $ldap_pw -h $ldap -f /tmp/$u.ldif > /dev/null 2>&1

for sg in $groups; do
cat > /tmp/$u.ldif<<EOF
dn: cn=$sg,ou=Group,dc=$domain1,dc=$domain2
changetype: modify
add: memberUid
memberUid: $u
EOF
ldapmodify -x -D "cn=admin,ou=ldap,ou=admin,dc=$domain1,dc=$domain2" -w $ldap_pw -h $ldap -f /tmp/$u.ldif > /dev/null 2>&1
done

echo "$u is created successfully in ldap"
return 0

fi

}


cd `dirname $0`; cat ../config.yml | sed 's/: */=/g' > /tmp/config.sh; source /tmp/config.sh
UPPER_PATH=..
create_ldap_user_internal $1 \"$2\"

HOME_PATH=$UPPER_PATH/home/$u
if [ ! -e $HOME_PATH/.ssh ]; then
  mkdir -p $HOME_PATH/.ssh
  ssh-keygen -q -t rsa -C "$u@gateway" -N '' -f $HOME_PATH/.ssh/id_rsa
  cat $HOME_PATH/.ssh/id_rsa.pub > $HOME_PATH/.ssh/authorized_keys
  chown -R $u:$u $HOME_PATH
  chmod -R 750 $HOME_PATH
  chmod 600 $HOME_PATH/.ssh/authorized_keys
  chmod 400 $HOME_PATH/.ssh/id_rsa
  chmod 400 $HOME_PATH/.ssh/id_rsa.pub
fi
