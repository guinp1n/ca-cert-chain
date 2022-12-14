#!/usr/bin/env bash

#TODO: debug only, remove before release
rm -rf ca-root
rm -rf keystores

#colors
# Set the color variable
green='\033[0;32m'
# Clear the color after that
clear='\033[0m'

#----- for CA and Intermediate CA ----
# Note, we use the pass: source so Key and Cert pass phrase will be the same.
# To have a different Key and PassPhrase you need to specify a file: as a source.
caKeyAndCertPassPhraseSource="pass:changeme1"
intermediateKeyAndCertPassPhraseSource="pass:changeme2"
#----- for server certificates
#TODO: put all server hostnames into array (right now they are broker1.hivemq.local and broker2.hivemq.local)
serverNum=2
serverKeyPassPhraseSources=("pass:changeme3" "pass:changeme3")
serverPKCS12ExportPasswordSources=("pass:changeme4" "pass:changeme4")
#---- for the broker-keystore.jks
brokerKeystorePass="changeme5"

#Create the following directory tree and empty, two index.txt and serial files containing integer values.
 #Place files in their corresponding directories and modify them to match your organisation’s information.
 #Your keystores and truststores will be output to a directory named keystores one level above your working directory.

mkdir ca-root
cd ca-root
mkdir -p certs crl intermediate intermediate/certs intermediate/csr intermediate/newcerts intermediate/private private newcerts ../keystores;
touch index.txt intermediate/index.txt;
echo 1001 | tee serial intermediate/serial;


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
printf "${green}Create a private key for the root CA${clear}"
echo ''
openssl genrsa -aes256 -out private/ca.key.pem \
  -passout $caKeyAndCertPassPhraseSource \
  4096;
chmod 400 private/ca.key.pem;
printf "${green}"
if [ -f private/ca.key.pem ]; then ls -l private/ca.key.pem;  else exit 66; fi
printf "${clear}"
echo ''

printf "${green}Create a root CA certificate${clear}"
echo ''
openssl req -config ca-openssl.cnf \
    -key private/ca.key.pem \
	-new -x509 -days 7300 -sha256 -extensions v3_ca \
	-out certs/ca.cert.pem \
	-passin $caKeyAndCertPassPhraseSource \
	-passout $caKeyAndCertPassPhraseSource;
chmod 444 certs/ca.cert.pem;
printf "${green}"
if [ -f certs/ca.cert.pem ]; then ls -l certs/ca.cert.pem;  else exit 66; fi
printf "${clear}"
echo ''

#Intermediate CA
 #We need to generate an intermediate CA
echo ''
printf "${green}Create a private key for the intermediate CA${clear}"
echo ''
openssl genrsa -aes256 \
	-out intermediate/private/intermediate.key.pem \
  -passout $intermediateKeyAndCertPassPhraseSource \
	4096;
chmod 400 intermediate/private/intermediate.key.pem;
printf "${green}"
if [ -f intermediate/private/intermediate.key.pem ]; then ls -l intermediate/private/intermediate.key.pem;  else exit 66; fi
printf "${clear}"
echo ''

#Since we want to sign our fresh key with the root CA, we need a CSR…
echo ''
printf "${green}Create a CSR for the intermediate CA${clear}"
echo ''

openssl req -config intermediate/int-openssl.cnf -new -sha256 \
      -key intermediate/private/intermediate.key.pem \
      -out intermediate/csr/intermediate.csr.pem \
      -passin $intermediateKeyAndCertPassPhraseSource;

printf "${green}"
if [ -f intermediate/csr/intermediate.csr.pem ]; then ls -l intermediate/csr/intermediate.csr.pem;  else exit 66; fi
printf "${clear}"
echo ''

#…which we can now sign.
openssl ca -config ca-openssl.cnf -extensions v3_intermediate_ca \
    -days 3650 -notext -md sha256 \
    -in intermediate/csr/intermediate.csr.pem \
    -out intermediate/certs/intermediate.cert.pem \
    -passin $caKeyAndCertPassPhraseSource;
chmod 444 intermediate/certs/intermediate.cert.pem;

printf "${green}"
if [ -f intermediate/certs/intermediate.cert.pem ]; then ls -l intermediate/certs/intermediate.cert.pem;  else exit 66; fi
printf "${clear}"
echo ''

#You can verify that CA index contains the certificate by inspecting index.txt
 #and the certificate chain with the following command
echo ''
printf "${green}Verify that CA index contains the certificate by inspecting index.txt${clear}"
echo ''
if [ -f index.txt ]; then cat index.txt;  else exit 66; fi
echo ''
printf "${green}Verify the certificate chain${clear}"
echo ''
openssl verify -CAfile certs/ca.cert.pem \
      intermediate/certs/intermediate.cert.pem;

#Should both be OK, it is time to create the certificate chain
echo ''
printf "${green}Create the certificate chain${clear}"
echo ''

cat intermediate/certs/intermediate.cert.pem \
      certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem;

chmod 444 intermediate/certs/ca-chain.cert.pem;

printf "${green}"
if [ -f intermediate/certs/ca-chain.cert.pem ]; then ls -l intermediate/certs/ca-chain.cert.pem;  else exit 66; fi
printf "${clear}"
echo ''

#Server Certificate
 #Next we will be creating a certificate and key for our server, sign it and generate the keystore to be used by HiveMQ. In the following examples, you will need to replace broker.hivemq.local with the FQDN of the individual nodes you are creating these for.
for ((i=1; i <= $serverNum; i++)); do
  index=$(( $i - 1 ))
  echo ''
  printf "${green}Create the server $i chain${clear}"
  echo ''

  #Generate the server’s private key
  echo ''
  printf "${green}Create the server $i private key${clear}"
  echo ''
  printf "${green}Using pass phrase $i = ${serverKeyPassPhraseSources[$index]}${clear}"
  echo ''
  openssl genrsa -aes256 \
        -out "intermediate/private/broker${i}.hivemq.local.key.pem" \
        -passout ${serverKeyPassPhraseSources[$index]} \
        2048;

  chmod 400 "intermediate/private/broker${i}.hivemq.local.key.pem";

  printf "${green}"
  if [ -f "intermediate/private/broker${i}.hivemq.local.key.pem" ]; then ls -l "intermediate/private/broker${i}.hivemq.local.key.pem";  else exit 66; fi
  printf "${clear}"
  echo ''

  #Create a signing request
  echo ''
  printf "${green}Create a signing request for server ${i}${clear}"
  echo ''

  serverCNSedStr="s/commonName_default.*/commonName_default = broker${i}.hivemq.local/"
  serverEmailSedStr="s/emailAddress_default.*/emailAddress_default = info-broker${i}@example.com/"

  sed "$serverCNSedStr" intermediate/int-openssl.cnf \
     | sed "$serverEmailSedStr" > intermediate/broker${i}-openssl.cnf

  printf "${green}"
  if [ -f intermediate/broker${i}-openssl.cnf ]; then ls -l intermediate/broker${i}-openssl.cnf; else exit 66; fi
  printf "${clear}"
  echo ''

  openssl req -config intermediate/broker${i}-openssl.cnf \
        -key "intermediate/private/broker${i}.hivemq.local.key.pem" \
        -new -sha256 -out "intermediate/csr/broker${i}.hivemq.local.csr.pem" \
        -passin ${serverKeyPassPhraseSources[$index]};

  printf "${green}"
  if [ -f "intermediate/csr/broker${i}.hivemq.local.csr.pem" ]; then ls -l "intermediate/csr/broker${i}.hivemq.local.csr.pem"; else exit 66; fi
  printf "${clear}"
  echo ''

  #Sign the server’s key and generate its certificate
  echo ''
  printf "${green}Sign the server $i key and generate its certificate${clear}"
  echo ''

  openssl ca -config intermediate/int-openssl.cnf \
        -extensions server_cert -days 375 -notext -md sha256 \
        -in "intermediate/csr/broker${i}.hivemq.local.csr.pem" \
        -out "intermediate/certs/broker${i}.hivemq.local.cert.pem" \
        -passin $intermediateKeyAndCertPassPhraseSource;

  chmod 444 "intermediate/certs/broker${i}.hivemq.local.cert.pem";

  printf "${green}"
  if [ -f "intermediate/certs/broker${i}.hivemq.local.cert.pem" ]; then ls -l "intermediate/certs/broker${i}.hivemq.local.cert.pem";  else exit 66; fi
  printf "${clear}"
  echo ''

  echo ''
  printf "${green}Verify that intermediate CA index contains the certificate for server ${i} by inspecting intermediate/index.txt${clear}"
  echo ''
  if [ -f intermediate/index.txt ]; then cat intermediate/index.txt;  else exit 66; fi
  echo ''
  printf "${green}Verify the certificate chain for server ${i}${clear}"
  echo ''
  openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
        "intermediate/certs/broker${i}.hivemq.local.cert.pem";
  echo ''


  #We now have all necessary parts to produce a keystore…

  #Concatenate the certificate chain:
  echo ''
  printf "${green}Concatenate the certificate chain for server ${i}${clear}"
  echo ''

  cat certs/ca.cert.pem intermediate/certs/intermediate.cert.pem "intermediate/certs/broker${i}.hivemq.local.cert.pem" > "../keystores/broker${i}.hivemq.local.chain.pem";

  printf "${green}"
  if [ -f "../keystores/broker${i}.hivemq.local.chain.pem" ]; then ls -l "../keystores/broker${i}.hivemq.local.chain.pem";  else exit 66; fi
  printf "${clear}"
  echo ''

  #Import the certificate chain and the private key in to a PKCS12 container
  echo ''
  printf "${green}Import the certificate chain and the private key in to a PKCS12 container for server ${i}${clear}"
  echo ''
  printf "${green}Using pass phrase for server ${i} key = ${serverKeyPassPhraseSources[$index]}${clear}"
  echo ''
  printf "${green}Using PKCS12 export password = ${serverPKCS12ExportPasswordSources[$index]}${clear}"
  echo ''

  openssl pkcs12 -export -in ."./keystores/broker${i}.hivemq.local.chain.pem" \
    -inkey "intermediate/private/broker${i}.hivemq.local.key.pem" \
    -certfile "../keystores/broker${i}.hivemq.local.chain.pem" \
    -passin ${serverKeyPassPhraseSources[$index]} \
    -passout ${serverPKCS12ExportPasswordSources[$index]} \
    > "../keystores/broker${i}.hivemq.local.p12";

  printf "${green}"
  if [ -f "../keystores/broker${i}.hivemq.local.p12" ]; then ls -l "../keystores/broker${i}.hivemq.local.p12";  else exit 66; fi
  printf "${clear}"
  echo ''

  #Import the contents of the PKCS12 container in to an JKS container.
  serverPKCS12ExportPassword=$(echo "${serverPKCS12ExportPasswordSources[$index]}" | cut -d':' -f2)
  echo ''
  printf "${green}Import PKCS12 for server ${i} key to a JKS container${clear}"
  echo ''
  printf "${green}Using PKCS12 password = ${serverPKCS12ExportPassword}${clear}"
  echo ''
  printf "${green}Using export password = ${brokerKeystorePass}${clear}"
  echo ''
  keytool -importkeystore -trustcacerts \
    -srckeystore "../keystores/broker${i}.hivemq.local.p12" \
    -srcstorepass "${serverPKCS12ExportPassword}" \
    -srcstoretype pkcs12 \
    -destkeystore ../keystores/broker-keystore.jks \
    -deststorepass "$brokerKeystorePass" \
    -srcalias 1 -destalias "broker${i}.hivemq.local" ;

  printf "${green}"
  if [ -f ../keystores/broker-keystore.jks ]; then ls -l ../keystores/broker-keystore.jks;  else exit 66; fi
  printf "${clear}"
  echo ''
done