# BetStudios - Confluent Cloud

Short guide provisioned a Confluent Cloud cluster using Terraform and using CDC Source Connector to replicate data from a MySQL database to a Kafka Topic

## Terraform

Latest documentation about **Confluent Terraform Provider** con be found here [aquí](https://docs.confluent.io/cloud/current/get-started/terraform-provider.html). The [Terraform Registry](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs) include examples and details for each resource and datasource.

Latest source code version **1.51.0** is available at the following Github [repository](https://github.com/confluentinc/terraform-provider-confluent).

### Pre-Requisites

Have a CCloud org created and provided login to the Console.

Instanll Confluent CLI follow the steps in the [documentation](https://docs.confluent.io/confluent-cli/current/install.html)

```shell
# Assuming orgId - 8d5dc71f-47d2-4f02-8a6b-7b65ebbfed81

confluent login \
  --organization-id 8d5dc71f-47d2-4f02-8a6b-7b65ebbfed81 \
  --prompt \
  --save
```

Once logged a Confluent CLI context is created, if you handle more that one CCloud account, it is recommended that you rename the context to something meaningful and short that you can use later to switch between contexts easily.

```shell
## TO LIST CONTEXTS
confluent context list

## Rename the context, new context have a naming conventios as "login-<EMAIL>-https://confluent.cloud"
confluent context update login-dfederico+betstudios@confluent.io-https://confluent.cloud --name "PS_BetStudios"
```

Confirm that you are using the correct context and continue with the next steps

```shell
confluent context use PS_BetStudios
```

## Create CLOUD API-KEY for Terraform

It is recommended to create a Service Account (SA) for Terraform and use the API-KEY for the SA to provision resources in CCloud. The SA can be created using the CLI and must have `OrganizationAdmin` role assigned so it can create other Service Accounts, API-Keys and provision environment resources.

See. [create service-account command](https://docs.confluent.io/confluent-cli/current/command-reference/iam/service-account/confluent_iam_service-account_create.html#confluent-iam-service-account-create)

```shell
## CREATE SERVICE ACCOUNT

# Creacion Usuario
confluent iam service-account create cloud-sa --description "Cloud SA BetStudios"

# OUTPUT EXAMPLE
# +-------------+---------------------+
# | ID          | sa-151wdv           |
# | Name        | cloud-sa            |
# | Description | Cloud SA BetStudios |
# +-------------+---------------------+
```

Add the `OrganizationAdmin` role to the SA and Create an API-KEY for the cloud resource

```shell
## ADD ROLE TO SERVICE ACCOUNT
confluent iam rbac role-binding create --role OrganizationAdmin --principal User:sa-151wdv

## CREATE API-KEY FOR CLOUD RESOURCE
confluent api-key create --service-account sa-151wdv  --resource cloud  --description "Cloud Key para Cloud-sa"

# OUTPUT EXAMPLE
# +------------+------------------------------------------------------------------+
# | API Key    | 4QCEWBDSV3ZRHF5D                                                 |
# | API Secret | opJHgdR2A4ND4Htu1EITH/TjjNpr89OJvXWOFxsANyRuXQbgCMntRxdTfrauJB7E |
# +------------+------------------------------------------------------------------+
```

## Terraform to provision a Standard Cluster

See. folder [Terraform/01.cluster](./terraform/01.cluster/), which creates an Environment called `Sandbox` and a STANDARD cluster called `Playground`

We can use environment variables to specify the API-KEYs

```shell
export TF_VAR_confluent_cloud_api_key="4QCEWBDSV3ZRHF5D"
export TF_VAR_confluent_cloud_api_secret="opJHgdR2A4ND4Htu1EITH/TjjNpr89OJvXWOFxsANyRuXQbgCMntRxdTfrauJB7E"
```

Init and Apply will crate the Environment, Kafka Cluster and a Service Account to "admin" the cluster

```shell
terraform init
terraform apply -var-file=standard-cluster.tfvars -state=standard-cluster.state
```

To check the output use `terraform output -state=standard-cluster.state`, it should display something like the below

```text
resource-ids = <<EOT
Environment ID:   env-zg2ok3
Kafka Cluster ID: lkc-o2mgmo
Kafka Cluster Bootstrap Servers: SASL_SSL://pkc-l6wr6.europe-west2.gcp.confluent.cloud:9092

Cluster Service Accounts and their Kafka API Keys:
Playground-cluster-sa:                     sa-959zq5
Playground-cluster-sa's Kafka API Key:     "IKOKGRBIFWR224ST"
Playground-cluster-sa's Kafka API Secret:  "J9kk/w+sSfuLmVLs1kwbSBNtk5DibWYQezYNnQcTGp6UkP2FlsP0ZQ6MAOb2j7xJ"

EOT
```

## Terraform to provision Project Resources (Service Account, Topics, RBAC, Connector, etc...)

See. folder [Terraform/02.project](./terraform/02.project/), which creates Application resources in the `Sandbox` environment and `Playground` cluster

**NOTE:** You need to use the API-KEY for the `Playground-cluster-sa` from the previous step to provision resources in the cluster, since the cloud-sa can only manage "cloud" resources.

```shell
export TF_VAR_cluster_owner_api_key="IKOKGRBIFWR224ST"
export TF_VAR_cluster_owner_api_secret="J9kk/w+sSfuLmVLs1kwbSBNtk5DibWYQezYNnQcTGp6UkP2FlsP0ZQ6MAOb2j7xJ"
```

```shell
terraform init
terraform apply -var-file=application.tfvars -state=application.state
```

This should produce an output similar to the below

```text
resource-ids = <<EOT
Environment ID:   Sandbox (env-zg2ok3)
Kafka Cluster ID: Playground (lkc-o2mgmo)
Kafka Bootstrap: 'SASL_SSL://pkc-l6wr6.europe-west2.gcp.confluent.cloud:9092'
Application: managed-connect
Service Account: managed-connect-sa (sa-v8jnvn)
managed-connect-sa's Kafka API Key:     "GOUCHUID44SSUFCE"
managed-connect-sa's Kafka API Secret:  "tRJYrd0s8GlZzCbxiaprIMvjYoaPq2zTv3VjePb7FYqg9xmnlp4nAc+/yIIYZKeS"
---
In order to use the Confluent CLI v2 to produce and consume messages from topic 'pizza.orders' using Kafka API Keys of managed-connect-sa service account
run the following commands:
# 1. Log in to Confluent Cloud
$ confluent login

# 2. Produce key-value records to topic 'pizza.orders':
$ confluent kafka topic produce pizza.orders --environment env-zg2ok3 --cluster lkc-o2mgmo \
  --api-key "GOUCHUID44SSUFCE" --api-secret "tRJYrd0s8GlZzCbxiaprIMvjYoaPq2zTv3VjePb7FYqg9xmnlp4nAc+/yIIYZKeS"
# Enter a few records and then press 'Ctrl-C' when you're done.
# Sample records:
# {"number":1,"date":18500,"shipping_address":"899 W Evelyn Ave, Mountain View, CA 94041, USA","cost":15.00}
# {"number":2,"date":18501,"shipping_address":"1 Bedford St, London WC2E 9HG, United Kingdom","cost":5.00}
# {"number":3,"date":18502,"shipping_address":"3307 Northland Dr Suite 400, Austin, TX 78731, USA","cost":10.00}

# 3. Consume records from topic 'pizza.orders':
$ confluent kafka topic consume pizza.orders --from-beginning --environment env-zg2ok3 --cluster lkc-o2mgmo \
  --api-key "GOUCHUID44SSUFCE" --api-secret "tRJYrd0s8GlZzCbxiaprIMvjYoaPq2zTv3VjePb7FYqg9xmnlp4nAc+/yIIYZKeS"
# When you are done, press 'Ctrl-C'.

EOT
topics = [
  "pizza.orders",
  "test.topic",
  "bet.transactions",
]
```

## (Optional) Context to Produce Consume using API-KEY

Associate the API-KEY to a context in the CLI using the `confluent context create`

Create a CLI context for service account using the API-KEY

```shell
confluent context create "Betstudios-client" \
  --bootstrap SASL_SSL://pkc-l6wr6.europe-west2.gcp.confluent.cloud:9092 \
  --api-key GOUCHUID44SSUFCE \
  --api-secret tRJYrd0s8GlZzCbxiaprIMvjYoaPq2zTv3VjePb7FYqg9xmnlp4nAc+/yIIYZKeS
```

Switch Context

```shell
confluent context use Betstudios-client
```

Produce

```shell
confluent kafka topic produce test.topic
```

Consume

```shell
confluent kafka topic consume test.topic -b --group managed-connect-cg_1
```

**NOTE**: The `-b` flag is to consume from the beginning of the topic. And permission for the consumer group as a `prefix` is added via terraform with the name composed by the applicationId followed by `-cg` suffix (e.g. `managed-connect-cg_1`)

## Using the Connect API

> **IMPORTANT** You must create a Confluent Cloud API key for --resource cloud to interact with the Confluent Cloud API. Using the Kafka cluster API key created for your Confluent Cloud cluster (that is, --resource <cluster-ID>) results in an authentication error when running the API request.

Given the above statement, we can use the API-KEY for the `cloud-sa` to interact with the Connect API, but we need to give enough privileges to the `cloud-sa` to be able to create and manage connectors in the cluster.

```shell
confluent iam rbac role-binding create \
  --principal User:sa-151wdv \
  --role CloudClusterAdmin \
  --environment env-zg2ok3 \
  --cloud-cluster lkc-o2mgmo
```

Then encode the Clud API-Key of the Cloud Service Account to use as header when calling the endpoint. `echo -n "<api-key>:<secret>" | base64`

```shell
export CONNECT_AUTH=$(echo -n "$TF_VAR_confluent_cloud_api_key:$TF_VAR_confluent_cloud_api_secret" | base64)
```

Calls to the API via curl: The url of the connect API is componsed with the environmentId and clusterId, see. Cloud Connect API Documentation [here](https://docs.confluent.io/cloud/current/connectors/connect-api-section.html)

```shell
## THE URL SHOULD CONTAIN THE ENVIRONMENT AND CLUSTER ID
## 'https://api.confluent.cloud/connect/v1/environments/<my-environment-ID>/clusters/<my-cluster-ID>/connector-plugins'

## THE FOLLOWING WILL LIST ALL THE AVAILABLE CONNECTOR PLUGINS

curl -X GET 'https://api.confluent.cloud/connect/v1/environments/env-zg2ok3/clusters/lkc-o2mgmo/connector-plugins' \
-H "authorization: Basic $CONNECT_AUTH" | jq
```

### Deploy a DATA-GEN Connector using the REST API

Create a JSON file with the configuration of the connector, including the Application sa API-KEY

```json
{
  "name": "DatagenSourceConnector_Pizza",
  "config": {
    "connector.class": "DatagenSource",
    "name": "PizzaOrderGenerator",
    "kafka.auth.mode": "KAFKA_API_KEY",
    "kafka.api.key": "GOUCHUID44SSUFCE",
    "kafka.api.secret": "tRJYrd0s8GlZzCbxiaprIMvjYoaPq2zTv3VjePb7FYqg9xmnlp4nAc+/yIIYZKeS",
    "kafka.topic": "pizza.orders",
    "schema.context.name": "default",
    "output.data.format": "JSON",
    "json.output.decimal.format": "BASE64",
    "quickstart": "PIZZA_ORDERS",
    "max.interval": "1000",
    "tasks.max": "1"
  }
}
```

```shell
## Assuming a file called "datagen-config.json" with the connector configuration
curl -X POST 'https://api.confluent.cloud/connect/v1/environments/env-zg2ok3/clusters/lkc-o2mgmo/connectors' \
-H "authorization: Basic $CONNECT_AUTH" \
-H 'Content-Type: application/json' \
-d "@datagen-config.json" | jq
```

**NOTE:** file provided in the resources folder [datagen-config.json](./resources/datagen-config.json)

You can query the status using
  
```shell
curl -X GET 'https://api.confluent.cloud/connect/v1/environments/env-zg2ok3/clusters/lkc-o2mgmo/connectors/DatagenSourceConnector_Pizza/status' \
-H "authorization: Basic $CONNECT_AUTH" | jq
```


## Check the connector using Confluent CLI

It is also possible to use the Confluent CLI to deploy and manage connectors.

```shell
## LIST AVAILABLE CONNECTOR PLUGINS
confluent connect plugin list --environment env-zg2ok3 --cluster lkc-o2mgmo

## SWITCH TO THE ENVIRONMENT AND CLUSTER
confluent environment use env-zg2ok3
confluent cluster use lkc-o2mgmo

## LIST CONNECTORS
confluent connect cluster list

## DESCRIBE THE CONNECTOR - ASSUME ID lcc-o2mw3x
confluent connect cluster describe lcc-o2mw3x
```

## Check the connector cluster events log

Fetch the coordinates of the audit log cluster, switch to it and create an API-KEY for the service account.
**NOTE:** You must be OrganizationAdmin to be able to create the API-KEY

```shell
confluent connect event describe
# +-----------------+------------------------------+
# | Cluster         | lkc-8m9pg0                   |
# | Environment     | env-ymz0rj                   |
# | Service Account | sa-y2vvpo                    |
# | Topic Name      | confluent-connect-log-events |
# +-----------------+------------------------------+

confluent environment use env-ymz0rj
confluent kafka cluster use lkc-8m9pg0

confluent api-key create --service-account sa-y2vvpo --resource lkc-8m9pg0
# +------------+------------------------------------------------------------------+
# | API Key    | EU75DOO6OKHHDQXL                                                 |
# | API Secret | ECHB2/HfO0j9dl7ALilXWSDDEEfoUlXwy/M7ohtVORRrGH+y2TJgNo7NcMK+113Y |
# +------------+------------------------------------------------------------------+

confluent api-key use EU75DOO6OKHHDQXL --resource lkc-8m9pg0

## CONFIRM BY LISTING THE API KEYS (IN YOUR CLI CONTEXT) FOR THE RESOURCE
confluent api-key list --resource lkc-8m9pg0
```

Finally consume from the log events topic using the CLI (you could use a Kafka Consumer as well)

```shell
confluent kafka topic consume -b confluent-connect-log-events
```

Events logged in the Connect events topic follow the [cloudevents schema](https://cloudevents.io/). The types of events logged in the topic are currently limited to io.confluent.logevents.connect.TaskFailed and io.confluent.logevents.connect.ConnectorFailed.

## Debezium MySQL (MariaDB) CDC Source Connector

### Provision a MariaDB Intance usign Terraform

See [terraform/03.mariadb](./terraform/03.mariadb/)
In this example we use GCP, make sure you have the GCP credentials file pointed by the environment variable GOOGLE_APPLICATION_CREDENTIALS

```shell
# FROM the folder terraform/03.mariadb
terraform init
terraform apply -var-file=mariadb.tfvars -state=mariadb.state
```

See. [Debezium Connector](https://docs.confluent.io/cloud/current/connectors/cc-mysql-source.html)

Enable external access

```shell
sudo mysql
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '12345' WITH GRANT OPTION;
FLUSH Privileges;

SELECT User, Host FROM mysql.user;
```

```sql
CREATE DATABASE betstudios;
USE betstudios;
CREATE TABLE BETS (
    ID int NOT NULL,
    UserEmail varchar(255) NOT NULL,
    Amount double NOT NULL,
    PRIMARY KEY (ID)
);


INSERT INTO BETS (id, useremail, amount) VALUES(1,"dfederico@confluent.io",123.45);
INSERT INTO BETS (id, useremail, amount) VALUES(2,"pepe@confluent.io",999.99);
INSERT INTO BETS (id, useremail, amount) VALUES(3,"betstudio@bets.io",4567.99);
UPDATE BETS SET useremail = "test@test.com" WHERE id=2;
DELETE FROM BETS WHERE id=3;
INSERT INTO BETS (id, useremail, amount) VALUES(3,"new@bets.io",1234.99);

```

CONNECTOR EXAMPLE
```json
{
  "connector.class": "MySqlCdcSource",
  "name": "mariadb_cdc_source",
  "kafka.auth.mode": "KAFKA_API_KEY",
  "kafka.api.key": "GOUCHUID44SSUFCE",
  "kafka.api.secret": "****************************************************************",
  "schema.context.name": "default",
  "database.hostname": "34.147.189.16",
  "database.port": "3306",
  "database.user": "root",
  "database.password": "*****",
  "database.server.name": "betstudios",
  "database.ssl.mode": "preferred",
  "database.include.list": "betstudios",
  "database.connectionTimeZone": "Europe/London",
  "snapshot.mode": "initial",
  "snapshot.locking.mode": "minimal",
  "tombstones.on.delete": "true",
  "poll.interval.ms": "1000",
  "max.batch.size": "1000",
  "event.processing.failure.handling.mode": "fail",
  "heartbeat.interval.ms": "0",
  "database.history.skip.unparseable.ddl": "false",
  "event.deserialization.failure.handling.mode": "fail",
  "inconsistent.schema.handling.mode": "fail",
  "provide.transaction.metadata": "false",
  "decimal.handling.mode": "precise",
  "binary.handling.mode": "bytes",
  "time.precision.mode": "connect",
  "cleanup.policy": "delete",
  "bigint.unsigned.handling.mode": "long",
  "enable.time.adjuster": "true",
  "output.data.format": "JSON",
  "after.state.only": "true",
  "output.key.format": "JSON",
  "json.output.decimal.format": "BASE64",
  "tasks.max": "1"
}
```


## References

[Configure BinLog](https://mariadb.com/kb/en/binary-log-formats/#configuring-the-binary-log-format)
