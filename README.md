# Sample local deployment for EDC Version 0.6.4

This repo shows an example deployment for edc with kafka extension to publish data with a kafka broker and again consume it with another kafka broker on a different topic.

## Prerequisites

You need to have __jq__ installed on your system for pretty json outputs. Additionally, you need to have __docker__ and __docker-compose__ installed to use the sample deployment for the kafka broker.

You need to configure dns resolution for the following hostnames:
- __kafka__: 127.0.0.1
- __provider__: 127.0.0.1
- __consumer__: 127.0.0.1

### Build connector.jar

Run the following command to build the edc connector in version 0.6.4:
```
./run.sh build
```

## Starting Services
You need to open a new terminal tab for each service, to start all components in parallel and see the logs.

### Start Kafka Broker
Starts the kafka broker as docker containers from the docker-compose configuration located in the __docker-compose-kafka.yml__ file.
```
./run.sh kafka
```

### Start Provider Connector

Starts the provider edc connector with provider configurations from the __connector/resources__ directory.
```
./run.sh provider
```

### Start Consumer Connector

Starts the consumer edc connector with consumer configurations from the __connector/resources__ directory.
```
./run.sh consumer
```


## Run Messages

The following command will run all necessary commands to create an asset, which provides every data send to the ```provider``` topic of the kafka service. The data will be processed through the connectors and pushed to the ```consumer``` topic in the kafka service.

All rest message bodies are located in the __messages__ directory.

```
./run.sh messages
```