# Sample local deployment for EDC Version 0.6.4

This repo shows an example deployment for edc with kafka extension to publish data with a kafka broker and again consume it with another kafka broker on a different topic.

## Prerequisites

You need to have __jq__ installed on your system for pretty json outputs. Additionally, you need to have __docker__ and __docker-compose__ installed to use the sample deployment for the kafka broker.

### Build connector.jar

Run the following command to build the edc connector in version 0.6.4:
```
./run.sh build
```

### Changing urls for requests

You can change the urls for the requests based on the deployment of the connectors and kafka-brokers.
Just call:
```
./setup.sh  --kafka kafka:29092 \
  --provider-management http://localhost:19193/management \
  --provider-control http://localhost:19192/control \
  --provider-public http://localhost:19291/api \
  --provider-protocol http://localhost:19194/protocol \
  --consumer-management http://localhost:29193/management \
  --consumer-control http://localhost:29192/control \
  --consumer-public http://localhost:29291/api
```

## Starting Services
You need to open a new terminal tab for each service, to start all components in parallel and see the logs.

### Start Kafka Broker
Starts the kafka broker as docker containers from the docker-compose configuration located in the __docker-compose.yml__ file.
```
./run.sh kafka
```

### Start Provider and Consumer Connector inside Docker
Will start the provider and consumer connector inside of the same docker-network, as the kafka service is deployed.
```
./run.sh docker-connectors
```

### Start Provider Connector
As alternative to the docker-deployment, you can also start the connectors simply from the jar file.
To do so, the provider edc connector with provider configurations from the __connector/resources__ directory is started by:
```
./run.sh provider
```

### Start Consumer Connector
As alternative to the docker-deployment, you can also start the connectors simply from the jar file.
To do so, the consumer edc connector with consumer configurations from the __connector/resources__ directory is started by:
```
./run.sh consumer
```


## Run Messages

The following command will run all necessary commands to create an asset, which provides every data send to the ```provider``` topic of the kafka service. The data will be processed through the connectors and pushed to the ```consumer``` topic in the kafka service.

All rest message bodies are located in the __messages__ directory.

```
./run.sh messages
```