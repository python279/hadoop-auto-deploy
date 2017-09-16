#!/bin/bash

cd `dirname $0`; cat ../config.yml | sed 's/: */=/g' > /tmp/config.sh; source /tmp/config.sh

ip=$kdc

yum install -y rsync openladp openldap-clients openldap-servers openldap-devel vim iostat krb5* pam_krb5 \
ansible libselinux-python xz iostat iotop install openssl-devel vim glibc-devel libaio libaio-devel libgcc libstdc++ libstdc++-devel make sysstat binutils elfutils-libelf gcc gcc-c++ glibc glibc-common glibc-devel compat-libstdc++-33 svn compat-libcap1 compat-libstdc++-33*.i686 glibc-devel*.i686 ksh zip unzip libstdc++*.i686 libaio*.i686 unixODBC unixODBC*.i686 unixODBC-devel lapack-devel libjpeg libjpeg-devel freetype freetype-devel lcms lcms-devel python-imaging libpng libpng-devel readline-devel patch lapack lapack-devel python-devel.x86_64 cyrus-sasl-devel.x86_64 blas blas-devel lrzsz git mysql mysql-devel bzip2* cyrus-sasl-plain cyrus-sasl-devel cyrus-sasl-gssapi openldap-clients krb5-workstation pam_krb5 sssd iftop iotop iostat lzop rsync jq pssh
chkconfig slapd on
chkconfig krb5kdc on
chkconfig kadmin on
service slapd stop
service krb5kdc stop
service kadmin stop

slapd_adminpw=$ldap_pw
slapd_adminpw_hash=$(slappasswd -s $slapd_adminpw)
if [ -e /etc/openldap/slapd.conf ]; then
  rm -f /etc/openldap/slapd.conf
fi

echo "local4.* /var/log/ldap.log" > /etc/rsyslog.d/ldap.conf
service rsyslog restart

cat > /etc/openldap/slapd.conf<<EOF
#
# See slapd.conf(5) for details on configuration options.
# This file should NOT be world readable.
#

include		/etc/openldap/schema/corba.schema
include		/etc/openldap/schema/core.schema
include		/etc/openldap/schema/cosine.schema
include		/etc/openldap/schema/duaconf.schema
include		/etc/openldap/schema/dyngroup.schema
include		/etc/openldap/schema/inetorgperson.schema
include		/etc/openldap/schema/java.schema
include		/etc/openldap/schema/misc.schema
include		/etc/openldap/schema/nis.schema
include		/etc/openldap/schema/openldap.schema
include		/etc/openldap/schema/ppolicy.schema
include		/etc/openldap/schema/collective.schema
include		/etc/openldap/schema/kerberos.schema

# Allow LDAPv2 client connections.  This is NOT the default.
allow bind_v2

# Do not enable referrals until AFTER you have a working directory
# service AND an understanding of referrals.
#referral	ldap://root.openldap.org

pidfile		/var/run/openldap/slapd.pid
argsfile	/var/run/openldap/slapd.args
loglevel	4095

# Load dynamic backend modules
# - modulepath is architecture dependent value (32/64-bit system)
# - back_sql.la overlay requires openldap-server-sql package
# - dyngroup.la and dynlist.la cannot be used at the same time

# modulepath /usr/lib/openldap
# modulepath /usr/lib64/openldap

# moduleload accesslog.la
# moduleload auditlog.la
# moduleload back_sql.la
# moduleload chain.la
# moduleload collect.la
# moduleload constraint.la
# moduleload dds.la
# moduleload deref.la
# moduleload dyngroup.la
# moduleload dynlist.la
# moduleload memberof.la
# moduleload pbind.la
# moduleload pcache.la
# moduleload ppolicy.la
# moduleload refint.la
# moduleload retcode.la
# moduleload rwm.la
# moduleload seqmod.la
# moduleload smbk5pwd.la
# moduleload sssvlv.la
# moduleload syncprov.la
# moduleload translucent.la
# moduleload unique.la
# moduleload valsort.la

# The next three lines allow use of TLS for encrypting connections using a
# dummy test certificate which you can generate by running
# /usr/libexec/openldap/generate-server-cert.sh. Your client software may balk
# at self-signed certificates, however.
TLSCACertificatePath /etc/openldap/certs
TLSCertificateFile "\"OpenLDAP Server\""
TLSCertificateKeyFile /etc/openldap/certs/password

# Sample security restrictions
#	Require integrity protection (prevent hijacking)
#	Require 112-bit (3DES or better) encryption for updates
#	Require 63-bit encryption for simple bind
# security ssf=1 update_ssf=112 simple_bind=64

# Sample access control policy:
#	Root DSE: allow anyone to read it
#	Subschema (sub)entry DSE: allow anyone to read it
#	Other DSEs:
#		Allow self write access
#		Allow authenticated users read access
#		Allow anonymous users to authenticate
#	Directives needed to implement policy:
# access to dn.base="" by * read
# access to dn.base="cn=Subschema" by * read
# access to *
#	by self write
#	by users read
#	by anonymous auth
#
# if no access controls are present, the default policy
# allows anyone and everyone to read anything but restricts
# updates to rootdn.  (e.g., "access to * by * read")
#
# rootdn can always read and write EVERYTHING!

# enable on-the-fly configuration (cn=config)
access to *
    by self write
    by users read
    by anonymous read

database config
access to *
	by dn.exact="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
	by * none

# enable server status monitoring (cn=monitor)
database monitor
access to *
	by dn.exact="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read
        by dn.exact="cn=admin,ou=ldap,ou=admin,dc=$domain1,dc=$domain2" read
        by * none

#######################################################################
# database definitions
#######################################################################

database	bdb
suffix  	"dc=$domain1,dc=$domain2"
checkpoint	1024 15
cachesize  	10000
rootdn  	"cn=admin,ou=ldap,ou=admin,dc=$domain1,dc=$domain2"
# Cleartext passwords, especially for the rootdn, should
# be avoided.  See slappasswd(8) and slapd.conf(5) for details.
# Use of strong authentication encouraged.
# rootpw		secret
# rootpw		{crypt}ijFYNcSNctBYg

# The database directory MUST exist prior to running slapd AND 
# should only be accessible by the slapd and slap tools.
# Mode 700 recommended.
directory	/var/lib/ldap

# Indices to maintain for this database
index objectClass                       eq,pres 
index ou,cn,mail,surname,givenname      eq,pres,sub 
index uidNumber,gidNumber,loginShell    eq,pres 
index uid,memberUid                     eq,pres,sub 
index nisMapName,nisMapEntry            eq,pres,sub

# Replicas of this database
#replogfile /var/lib/ldap/openldap-master-replog
#replica host=ldap-1.example.com:389 starttls=critical
#     bindmethod=sasl saslmech=GSSAPI
#     authcId=host/ldap-master.example.com@EXAMPLE.COM
EOF

cp -f /usr/share/doc/krb5-server-ldap-1.10.3/kerberos.schema /etc/openldap/schema
sed -i "/^# rootpw.*ijFYNcSNctBYg/a\rootpw\t\t$slapd_adminpw_hash" /etc/openldap/slapd.conf

rm -rf /etc/openldap/slapd.d/*
rm -rf /var/lib/ldap/*
cp -f /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown -R ldap:ldap /var/lib/ldap/
service slapd start
slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
chown -R ldap:ldap /etc/openldap/slapd.d/*
service slapd restart

cat > /tmp/init.ldiff<<EOF
dn: dc=$domain1,dc=$domain2
dc: $domain1
objectClass: domain
objectClass: dcObject

dn: ou=Group,dc=$domain1,dc=$domain2
ou: Group
objectClass: organizationalUnit

dn: ou=People,dc=$domain1,dc=$domain2
ou: People
objectClass: organizationalUnit

dn: ou=Eos,dc=$domain1,dc=$domain2
ou: Eos
objectClass: organizationalUnit

dn: ou=Control,dc=$domain1,dc=$domain2
ou: Control
objectClass: organizationalUnit

dn: ou=Aliases,dc=$domain1,dc=$domain2
ou: Aliases
objectClass: organizationalUnit
EOF
ldapadd -x -D "cn=admin,ou=ldap,ou=admin,dc=$domain1,dc=$domain2" -w $slapd_adminpw -h $ip -f /tmp/init.ldiff
rm -f /tmp/init.ldiff


#
# setup kerberos
#
rm -rf /var/kerberos/krb5kdc/*

cat > /etc/krb5.conf<<EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = $domain1_upper.$domain2_upper
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = false

[realms]
 $domain1_upper.$domain2_upper = {
  kdc = $ip
  admin_server = $ip
  default_domain = eu-central-1.compute.internal
  key_stash_file = /var/kerberos/krb5kdc/.k5.$domain1_upper.$domain2_upper
  dict_file = /usr/share/dict/words
 }

[domain_realm]
 .$domain1.$domain2 = $domain1_upper.$domain2_upper
 $domain1.$domain2 = $domain1_upper.$domain2_upper
EOF

cat > /var/kerberos/krb5kdc/kdc.conf<<EOF
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 $domain1_upper.$domain2_upper = {
  kadmind_port = 749
  master_key_type = aes256-cts-hmac-sha1-96
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  supported_enctypes = aes256-cts-hmac-sha1-96:normal aes128-cts-hmac-sha1-96:normal des3-cbc-sha1:normal arcfour-hmac-md5:normal des-cbc-md5:normal
  max_life = 24h 0m 0s
  max_renewable_life = 7d 0h 0m 0s
  dict_file = /usr/share/dict/words
  key_stash_file = /var/kerberos/krb5kdc/.k5.$domain1_upper.$domain2_upper
  database_name = /var/kerberos/krb5kdc/principal
 }
EOF

cat > /var/kerberos/krb5kdc/kadm5.acl<<EOF
*/admin@$domain1_upper.$domain2_upper	*
EOF

krb_adminpw=$kadmin_pw
kdb5_util create -r $domain1_upper.$domain2_upper -s -P $krb_adminpw
kadmin.local -w $krb_adminpw -q "addprinc -pw $krb_adminpw root/admin"
service krb5kdc start
service kadmin start
kadmin.local -w $krb_adminpw -q "addprinc -pw 1q@w3e$r hadoop"

# enable local pam_krb5 and ldap user info
authconfig --enableldap --ldapserver=ldap://$ldap --ldapbasedn=dc=$domain1,dc=$domain2 --enablekrb5 --krb5kdc=$kdc --krb5adminserver=$kadmin --krb5realm=$domain1_upper.$domain2_upper --updateall --enablemkhomedir  --enablesssd --enablesssdauth --enablecachecreds

