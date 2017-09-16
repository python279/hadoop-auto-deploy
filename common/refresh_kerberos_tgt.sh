KEYTAB=/usr/local/hadoop/keytab
for k in `cd $KEYTAB && ls *.keytab`; do
   u=`basename $k .keytab` 
   chown $u:$u $KEYTAB/$k
   su -l $u -c "kinit -kt $KEYTAB/$k $u"
done
