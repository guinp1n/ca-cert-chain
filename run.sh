#!/usr/bin/env bash

#TODO: debug only, remove before release
rm -rf ca-root
rm -rf keystores

#colors
# Set the color variable
green='\033[0;32m'
# Clear the color after that
clear='\033[0m'

# -passin val           Private key and certificate password source
caKeyPassPhraseVal="pass:changeme"
# -passout val          Output file pass phrase source
caCertPassPhraseVal="pass:changeme2"

#Create the following directory tree and empty, two index.txt and serial files containing integer values.
 #Place files in their corresponding directories and modify them to match your organisation’s information.
 #Your keystores and truststores will be output to a directory named keystores one level above your working directory.

mkdir ca-root
cd ca-root
mkdir -p certs crl intermediate intermediate/certs intermediate/csr intermediate/newcerts intermediate/private private newcerts ../keystores;

#In each openssl.cnf modify dir to match their respective absolute paths (pwd will show your current working directory)
curDir=$(pwd)
curDirDoubleSlashed=$(echo $curDir | sed 's/\//\\\//g')
sedStr="s/\/home\/dir\/ca-root/$curDirDoubleSlashed/g"
sed $sedStr ../ca-openssl.cnf > ca-openssl.cnf

curDir="${curDir}/intermediate"
curDirDoubleSlashed=$(echo $curDir | sed 's/\//\\\//g')
sedStr="s/\/home\/dir\/ca-root\/intermediate/$curDirDoubleSlashed/g"
sed $sedStr ../int-openssl.cnf > intermediate/int-openssl.cnf

#Root CA
  #First we want to create a private key and root CA
echo ''
printf "${green}Create a private key${clear}"
echo ''
openssl genrsa -aes256 -out private/ca.key.pem -passout $caKeyPassPhraseVal 4096;
chmod 400 private/ca.key.pem;
printf "${green}"
ls -l private/ca.key.pem
printf "${clear}"
echo ''

printf "${green}Create a root CA${clear}"
echo ''
openssl req -config ca-openssl.cnf \
    -key private/ca.key.pem \
	-new -x509 -days 7300 -sha256 -extensions v3_ca \
	-out certs/ca.cert.pem \
	-passin $caKeyPassPhraseVal \
	-passout $caCertPassPhraseVal;
chmod 444 certs/ca.cert.pem;
printf "${green}"
if [ -f certs/ca.cert.pem ]; then ls -l certs/ca.cert.pem; fi
printf "${clear}"
echo ''



