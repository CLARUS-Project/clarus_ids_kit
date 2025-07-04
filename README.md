# clarus_ids_kit

This repository contains the docker-compose file and the configuration files and folders needed to deploy  a TRueConnector using SFTP protocol  and a clarus agent to manage the connector and register clarus assets (datasets). This TRueConnector uses WSS Protocol to communicate with other TRueConnectors, for this reason it can not be configured as both provider and consumer. In this repository, the connector is configured by default as a provider but it can be configured as consumer just by changing one property.
The repository also contains an additional docker compose file to deploy also a MinIO server that can be used to save the pilots datasets.


## Table of Contents <!-- omit in toc -->


- [clarus\_ids\_kit](#clarus_ids_kit)
  - [Requirements](#requirements)
  - [Components](#components)
  - [Deployment](#deployment)
    - [Clone repository](#clone-repository)
    - [Certificates generation](#certificates-generation)
      - [DAPS certificate generation](#daps-certificate-generation)
      - [TRue Connector certificate generation](#true-connector-certificate-generation)
      - [MetadataBroker interaction certificate](#metadatabroker-interaction-certificate)
    - [Configuration](#configuration)
      - [Environment variables configuration](#environment-variables-configuration)
      - [Ecc properties configuration](#ecc-properties-configuration)
      - [Datapp properties configuration](#datapp-properties-configuration)
    - [Start services](#start-services)
  - [How to share datasets within Clarus Data Space](#how-to-share-datasets-within-clarus-data-space)
  - [How to Query MetadataBroker](#how-to-query-metadatabroker)

## Requirements
- Linux machine with public IP with 8 GB RAM and 70 GB Disk 
- Docker version 23.0.5 or above installed
- Docker-compose version 1.29.2 or above installed
- Open ports: 8086, 2223 & 8082
## Components
Next figure shows the components that are part of the clarus_ids_kit.

![clarus_ids_kit](images/clarus_ids_kit.png)

A brief description of the clarus_ids_kit components:

- TRueConnector A complete description of TrueConnector can be found [here](https://github.com/Engineering-Research-and-Development/true-connector)

- clarus_ids_agent: service that provides diferent endpoints to make easier the management of TRueConnector. It is also in charge of moving datasets from MinIO to dataapp datalake.

- clarus-hmi: Frontend that consumes clarus_ids_agent endpoints. It allows the user to register, delete and view the metamodel for shared datasets within the Clarus Data Space.

- MinIO server: Optional component that can be used by pilot to save their datasets instead of using its own.
  
## Deployment 
The content needed for the deployment is available in the Clarus github repository https://github.com/CLARUS-Project and the images used are in the Clarus docker hub repository https://hub.docker.com/repositories/clarusproject.
The credentials to pull images from docker hub  are saved in the Polimi repository.
### Clone repository
- Clone clarus_ids_kit
    ```
    ./git clone https://github.com/CLARUS-Project/clarus_ids_kit.git
    ``` 
Once repository is cloned you should see next folder tree

![Folders_and_files](images/Folders_and_files.png)

- be-dataapp_data_consumer: Not used currently
- be-dataapp_data_provider: Folder used as datalake by the SFTP server started by the dataapp TRueConnector component.
- be-dataapp_resources: Folder where the properties files used by the dataapp are located
- ecc_cert: Folder to save the certificates keystore and truststore
- ecc_reources_provider: Folder where the properties files used by the ecc are located
- images: Not relevant. Images for the Readme file
- uc-dataapp_pip_resources_provider: Folder where the properties files used by the uc-dataapp-pip-provider are located. Currently, usage control components are not used. 
- uc-dataapp_resources_provider: Folder where the properties files used by the uc-dataapp-provider are located. Currently, usage control components are not used.
- .env: Enviromental: variables needed to configure all the components
- docker-compose.yml: File to start all the services. By default, it contains same services as docker-compose-basic.yml
- docker-compose-basic.yml: File with the basic services. (ecc-provider,uc-dataapp-provider,be-dataapp-provideruc-dataapp-pip-provider,clarus_ids_agent)
- docker-compose-minio.yml: MinIO server is added to the basic services
- prepopulate_be_dataapp_data_provider.sh: Not used currently
- renew_daps_certificate.sh: script to renew the Daps certificate when it expires.
- ClarusIdsAgent.postman_collection: Collection that can be imported in Postman tool to make easier the registration of clarus assets. These requests will be used by the clarus-hmi. It is possible to use Postman instead of clarus-hmi. 
- TRUE Connector v1.postman_collection: Collection that can be imported in Postman tool to manage directly the TRueConnector. Not needed if you use the ClarusIdsAgent.postman_collection.

  
**Make sure permissions for folder ecc_cer & be-dataapp_data_provider are set to 777**
### Certificates generation

All the certificates used by the TRue Connector are stored in the keystore ssl-server.jks and in the truststore truststore.jks located in the folder ecc_cert. 
The connector uses the identity provider (DAPS) deployed in the Clarus Data Space. A certificate is needed to authenticate within this Identity Provider.
The connector also needs another certificate to be able to share data with the connector deployed in the MLOps platform and registered also in the Clarus Data Space. 
#### DAPS certificate generation
 The following steps and examples describe the sequence of operations. The names in italics and bold are only as examples.
1.	Create certificate for sharing with DAPS

    openssl req -x509 -nodes -newkey rsa:2048 -keyout ***xx-daps-edge***.key -out ***xx-daps-edge***.cert -sha256 -days 365 -subj "/C=***ES***/ST=***Spain***/L=***GI***/O=***IKERLAN***/OU=***IPD***/CN=***xx-daps-edge-cn***” -addext "subjectAltName = DNS:***your public DNS or IP***" 
    
2.	Send ***xx-daps-edge***.cert to DAPS operator (luigi.dicorrado@eng.it)

3.	Generate a .p12 using the key/cert pair you created at step 1, (set a password when prompted) and save it at ecc_cert folder
 
    openssl pkcs12 -export -out ***xx-daps-edge***.p12 -inkey ***xx-daps-edge***.key -in ***xx-daps-edge***.cert -name ***preferred_name***
    
4.	Download public certificate (mvds-clarus.eu.crt) from DAPS operator ( http://daps.mvds-clarus.eu ) 

5.	Import certificates to the truststore at ecc_cert

    keytool -import -v -trustcacerts -alias mvds-clarus.eu -file mvds-clarus.eu.crt -keystore truststoreEcc.jks -keypass changeit -storepass allpassword 

    keytool -import -v -trustcacerts -alias ***xx-daps-edge*** -file ***xx-daps-edge***.cert -keystore truststoreEcc.jks -keypass changeit -storepass allpassword 

**DAPS certificate expires every 3 months. In those cases you need to renew the certificate from  daps.mvds-clarus.eu executing the provided script**

- Renew DAPS certificate
  
    ```
    ./renew_daps_certificate.sh
    ```   

#### TRue Connector certificate generation 
The following steps and examples describe the sequence of operations. The names in italics and bold are only as examples.
1.	Create public/private key in keystore

    
    keytool -genkey -alias ***xx-tc-edge*** -keyalg RSA -keypass changeit -storepass changeit -keystore ssl-server.jks -ext SAN=ip:***your public IP***,dns:uc-dataapp-provider,dns:ecc-provider,dns:be-dataapp-provider 
    
2.	Export certificate. 

    
    keytool -export -alias ***xx-tc-edge***  -storepass changeit  -file ***xx-tc-edge***.cer -keystore ssl-server.jks 
    

3.	Import own certificate in truststore

    
    keytool -import -v -trustcacerts -alias ***xx-tc-edge*** -file ***xx-tc-edge***.cer -keystore truststoreEcc.jks -keypass changeit -storepass allpassword 
        

4.	Send exported certificate in step 2 to MLOps platform operator (bkremer@ikerlan.es) and get TRueConnector public certificate from  MLOps cloud platform.

5.	Import in your truststore
    
    keytool -import -v -trustcacerts -alias ***xx-tc-mlops*** -file ***xx-tc-mlops***.cer -keystore truststoreEcc.jks -keypass changeit -storepass allpassword

#### MetadataBroker interaction certificate 

Needed when the interaction with the MetadaBroker is enabled.

1.	Open a Browser, go to https://broker.mvds-clarus.eu and download the certificate, then load this certificate into the connector Trustore.

2.	Import certificate in your truststore

    keytool -import -v -trustcacerts -alias broker.mvds-clarus.eu -file broker.mvds-clarus.eu.crt -keystore truststoreEcc.jks -keypass changeit -storepass allpassword

### Configuration
Several configuration files are needed to adjust the behaviour of the various TrueConnector components.  In addition, an environment variables file eases this configuration.

#### Environment variables configuration
The .env file contains the enviromental variables needed both for the TRueConnector & clarus agent.
Only the sections regarding with TLS certificates, DAPS certiifcates, Connector identifier and agent configuration shall be modified.

- TLS settings. Only the alias for the TrueConnector certificate needs to be set. See [TRue Connector certificate generation](#true-connector-certificate-generation) section
 ````
#TLS settings
KEYSTORE_NAME=ssl-server.jks
KEY_PASSWORD=changeit
KEYSTORE_PASSWORD=changeit
ALIAS=<<ALIAS>>
 ````

- DAPS settings. Name, password and alias for the certificate used to register in DAPS. See [DAPS certificate generation](#daps-certificate-generation) section. The DAPS CERTIFICATE ALIAS shall be the ***preferred_name*** used in step 3 of the section.

````
#DAPS certificate configuration
#When DAPS enabled, set next variables with DAPS certificate. AWS edge machine as an example
PROVIDER_DAPS_KEYSTORE_NAME=<<DAPS CERTIFICATE>>
PROVIDER_DAPS_KEYSTORE_PASSWORD=<<DAPS CERTIFICATE PASSWORD>>
PROVIDER_DAPS_KEYSTORE_ALIAS=<<DAPS CERTIFICATE ALIAS>>

 ````

- Connector Identifier. The connector identifier must be modified. This identifier will be used to uniquely register the connector's self-description in the MetadataBroker. Only the PROVIDER_ISSUER_CONNECTOR_URI property should be updated. The identifier value must follow the URI format. For example, http://w3id.org/engrd/connector/MyProvider.
  
````
# In case of WSS configuration
PROVIDER_DATA_APP_ENDPOINT=https://be-dataapp-provider:9000/incoming-data-app/routerBodyBinary
PROVIDER_WS_EDGE=true
PROVIDER_ISSUER_CONNECTOR_URI=<<Connector_ID>>
PROVIDER_DATA_APP_FIREWALL=false
PROVIDER_ECC_FIREWALL=false

 ````



- Agent settings. The agent needs to know how to reach the TRue Connector. While the agent is deployed in the same docker network as the TrueConnector the TRueConnector agent configuration variables don´t need to be modified. Endpoint, username and password for the MinIO server where datasets are stored have to be set.

````
#TRue Connector agent Configuration
ECC_PROVIDER_IP=ecc-provider  
ECC_PROVIDER_PORT=8449
PROXY_CONSUMER_IP=be-dataapp-consumer
PROXY_CONSUMER_PORT=8183
ECC_CONSUMER_IP=ecc-consumer
ECC_CONSUMER_PORT=8887
ECC_PROVIDER_EXTERNAL_PORT=8086

#MinIO agent Configuration
MINIO_ENDPOINT=<<MinIO endpont>>
MINIO_USERNAME=<<MinIO username>>
MINIO_PASSWORD=<<MinIO password>>

 ````


#### Ecc properties configuration
The ecc configuration files can be found in the ecc_resources_provider folder (application-docker-properties).  This TRueConnector execution core (ecc) is configured to use the DAPS of the Clarus dataspace (mvds-clarus.eu) as identity provider. This ecc is also configured to use the web sockets protocol as ids protocol. This TRueConnector is also configured as a provider connector. The default values of these files are fine and no modification is required.

Although it is not mandatory, it is recommended to modify some of the attributes that describe the connector to facilitate its recognition when querying the MetadataBroker.

```
application.selfdescription.description=Data Provider Connector description
application.selfdescription.title=Data Provider Connector title
application.selfdescription.curator=http://provider.curatorURI.com
application.selfdescription.maintainer=http://provider.maintainerURI.com
application.selfdescription.filelocation=/home/nobody/data/sd
application.selfdescription.inboundModelVersion=4.0.0,4.1.0,4.1.2,4.2.0,4.2.1,4.2.2,4.2.3,4.2.4,4.2.5,4.2.6,4.2.7
application.selfdescription.defaultEndpoint=
   ```

It is possible to configure this TRueConnector as a consumer connector. To do that it is only needed to modify a parameter in the configuration file  as below.
````
#Define if the connector is used as receiver or sender
application.isReceiver=false
````

It is not possible to update in the MetadataBroker the connector self-description using the API provided by the TrueConnector proxy because in Clarus the connector is using wss protocol. The option is to enable the interaction with the MetadaBroker by setting the broker parameter "registrateOnStartup" to true. This means that every time the ecc starts up, the self description of the connector will be updated in the Metadabroker. This means that whenever resources are updated in the connector, the ecc must be relaunched in order to have the Metadabroker updated as well. 

```
# BROKER
application.selfdescription.registrateOnStartup=true
application.selfdescription.brokerURL=${BROKER_URL}
   ```

By default use of Clearing House is not enabled. Ecc version v1.14.3 has problems when interacting with Clearing House. If the Clearing House needs to be enabled in the configuration 
```
# Clearing House
application.clearinghouse.isEnabledClearingHouse=true
```
Once enabled, it is mandatory to modify the ecc image version to v1.14.8 in the compose file before launching clarus ids services

```
version: '3.1'
services:
  ecc-provider:
    #image: rdlabengpa/ids_execution_core_container:v1.14.3
    image: rdlabengpa/ids_execution_core_container:v1.14.8
```



#### Datapp properties configuration
The dataapp configuration files can be found in the be-dataapp_resources folder. The default values are fine and only the settings regarding the SFTP server need to be set in the file application-docker.properties.
  - The public IP where the SFTP server is available needs to be set (public IP of the machine where the conector is deployed). 
  
   ```
    #SFTP settings
    application.sftp.host=<<IP Host>>
   ```




### Start services
Move to the folder where the repo has been cloned.
- Login in Dockerhub using the clarusproject credentials provided in the project
    ```
    docker login -username=clarusproject
    ```
There are three compose files in the project: docker-compose-basic.yml, docker-compose-minio.yml and docker-compose.yml. The file docker-compose-basic.yml is the basic version and in this case minio server is not installed. The file docker-compose-minio.yml is the  version that also installs minio server. Be sure that the version you want to deploy is copied in the file docker-compose.yml. By default the file docker-compose.yml contains the basic version.

- Execute docker-compose file
    ```
    docker-compose up -d
    ```

- Once docker-compose is finished, all the services shall be up and running. To check it, write in terminal type in terminal
    ```
    docker ps -a
    ```
You shall see next services up:

![clarus_ids_kit_services](images/clarus_ids_kit_services.png)

## How to share datasets within Clarus Data Space

Once the services are up and running clarus-hmi frontend is avilable in port 3000. Use an internet browser and navigate to:

    ```
    http://<<IP where clarus_ids_kit has been deployed>>:3000
    ```

Next screen will be shown:

![hmi_01](images/HMI_01.png)

This screen will show your experiments (datasets) already registered wthin the Clarus DatSpace. 

You can use the REGISTER menu to register a new dataset in the ids connector. Click in the menu and the next screen will appear
![hmi_02](images/HMI_02.png)

- Experiment ID: Unique identifier for the experiment(dataset).It should be the same as the one used as experimentID in the dag configuration.
- Description: Description for the dataset. 
- Type: Choose dataset from the combobox
- MinioEndpoint: IP and port of the MiniIO server where the datasets are saved (<<IP>>:<<port>>)
- Bucket: Bucket where the dataset is saved. (i.e datasets)
- Path: path of the dataset. (i.e usecase01/mydataset.csv)

When click in an ids resource, it is posible to stop sharing the dataset through ids just by clicking on the DELETE button
![hmi_03](images/HMI_03.png)

## How to Query MetadataBroker 

To query the Metadata Broker using the UI, open a browser and visit https://broker.mvds-clarus.eu/fuseki , move to “dataset” page where it’s possible to write a SPARQL query and fetch results.

It is possible to get:
1. List of all registered connectors. Use next query:

````
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX ids: <https://w3id.org/idsa/core/>
SELECT ?s ?p ?o WHERE { GRAPH ?o { ?s ?p ids:BaseConnector } }
````
The result of this query will be a list of connectors and their registered ID

2. Explore the high level nodes of a specific connector self description looking for the description of a concrete resource. Use next query:
   
````
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX ids: <https://w3id.org/idsa/core/>
SELECT DISTINCT ?s ?p ?o WHERE { GRAPH ?s { <CONNECTOR ID> ?p ?o } }
````
The result will show a list of object related to the self description of the selected connector.

As an example once the connector with ID -444341879 is dicovered in step 1, a query to explore its self-description is requested
````
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX ids: <https://w3id.org/idsa/core/>
SELECT DISTINCT ?s ?p ?o WHERE { GRAPH ?s { <https://broker.mvds-clarus.eu/connectors/-444341879> ?p ?o } }
````
The result will show a list of object related to the self description of the selected connector, in this case, the image below highlight the object "ids:resourceCatalog" which have the ID <https://broker.mvds-clarus.eu/connectors/-444341879/-2565144>. 

![meta1](images/Meta1.png)

Next step will be to explore the content of the catalog looking for the  offered resources
````
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX ids: <https://w3id.org/idsa/core/>
SELECT DISTINCT ?s ?p ?o WHERE { GRAPH ?s { <https://broker.mvds-clarus.eu/connectors/-444341879/-2565144> ?p ?o } }
````
The result will be a list of Offered resources that are contained inside the catalog.
![meta2](images/Meta2.png)

Finally the offered resources description can be explored looking for one specific resource ID
![meta3](images/Meta3.png)