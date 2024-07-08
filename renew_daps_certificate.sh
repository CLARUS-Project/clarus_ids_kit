#!/bin/bash

#Relative truststore path (from docker compose file)
#TRUSTORE_PATH="./TRUEConnector/cert/consumer"
TRUSTORE_PATH="./ecc_cert"

#Load the .env file (to retrieve the parameters)
source .env

#Download new daps certificate
echo | openssl s_client -servername daps.mvds-clarus.eu -connect daps.mvds-clarus.eu:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ./mvds-clarus.eu

#Backup truststore before modify
cp "${TRUSTORE_PATH}/${TRUSTORE_NAME}" "${TRUSTORE_PATH}/${TRUSTORE_NAME}_backup_$(date +%Y%m%d)"

#Remove old certifcate from truststore
keytool -delete -keystore "${TRUSTORE_PATH}/${TRUSTORE_NAME}" -alias 'mvds-clarus.eu (r3)' -storepass ${TRUSTORE_PASSWORD} -noprompt

#Add new certifcate to truststore
keytool -import -file mvds-clarus.eu -keystore "${TRUSTORE_PATH}/${TRUSTORE_NAME}" -alias 'mvds-clarus.eu (r3)' -storepass ${TRUSTORE_PASSWORD} -noprompt

#Remove the downloaded certificate
rm ./mvds-clarus.eu
