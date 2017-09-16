#!/bin/bash

cd `dirname $0`; cat ../config.yml | sed 's/: */=/g' > /tmp/config.sh; source /tmp/config.sh

openssl req -new -x509 -keyout ca.key -out ca.cert -days 9999
