#!/bin/bash

contractId=""
transferProcessId=""

providerManagement="http://provider:19193/management"
consumerManagement="http://consumer:19193/management"

main() {
    if [ "$1" == "build" ]; then
        build_connector
    elif [ "$1" == "kafka" ]; then
        start_kafka
    elif [ "$1" == "provider" ]; then
        start_provider
    elif [ "$1" == "docker-connectors" ]; then
        start_docker_connectors
    elif [ "$1" == "consumer" ]; then
        start_consumer
    elif [ "$1" == "messages" ]; then
        message_dataplanes
        sleep 1
        message_asset
        sleep 1
        message_policy
        sleep 1
        message_contract_definition
        sleep 1
        message_fetch_catalog
        sleep 1
        message_negotiate_contract
        sleep 6
        message_contract_agreement $contractId
        sleep 6
        message_start_transfer
        sleep 4
        message_transfer_status $transferProcessId
    elif [ "$1" == "message" ]; then
        if [ "$2" == "0" ] || [ "$2" == "dataplanes" ]; then
            message_dataplanes
        elif [ "$2" == "1" ] || [ "$2" == "asset" ]; then
            message_asset
        elif [ "$2" == "2" ] || [ "$2" == "policy" ]; then
            message_policy
        elif [ "$2" == "3" ] || [ "$2" == "contract" ] || [ "$2" == "contractDefinition" ]; then
            message_contract_definition
        elif [ "$2" == "4" ] || [ "$2" == "catalog" ] || [ "$2" == "fetchCatalog" ]; then
            message_fetch_catalog
        elif [ "$2" == "5" ] || [ "$2" == "negotiate" ] || [ "$2" == "contractNegotiation" ]; then
            noResponse=""
            message_negotiate_contract $noResponse
        elif [ "$2" == "6" ] || [ "$2" == "agreement" ] || [ "$2" == "contractAgreement" ]; then
            message_contract_agreement $3
        elif [ "$2" == "7" ] || [ "$2" == "transfer" ] || [ "$2" == "startTransfer" ]; then
            noResponse=""
            message_start_transfer $noResponse
        elif [ "$2" == "8" ] || [ "$2" == "transferStatus" ]; then
            message_transfer_status $3
        else
            print_usage
        fi
    else
        print_usage
    fi
}

print_usage() {
    printf "Usage: \n$0 build\n$0 docker-connectors\n$0 provider\n$0 consumer\n$0 messages\n\n$0 message 0|dataplanes\n$0 message 1|asset\n$0 message 2|policy\n$0 message 3|contract|contractDefinition\n$0 message 4|catalog|fetchCatalog\n$0 message 5|negotiate|contractNegotiation\n$0 message 6|agreement|contractAgreement <agreementId>\n$0 message 7|transfer|startTransfer\n$0 message 8|transferStatus <transferProcessId>\n"
}

build_connector() {
    echo "Building connector"
    ./gradlew clean connector:build
}

start_kafka() {
    echo "Starting kafka"
    docker-compose -f docker-compose.yml up kafka zookeeper
}

start_provider() {
    echo "Starting provider"
    java -Dedc.keystore=connector/resources/certs/cert.pfx -Dedc.keystore.password=123456 -Dedc.vault=connector/resources/configuration/provider-vault.properties -Dedc.fs.config=connector/resources/configuration/provider.properties -jar connector/build/libs/roms-connector.jar
}

start_docker_connectors() {
    echo "Starting provider"
    docker-compose -f docker-compose.yml up provider consumer
}

start_consumer() {
    echo "Starting consumer"
    java -Dedc.keystore=connector/resources/certs/cert.pfx -Dedc.keystore.password=123456 -Dedc.vault=connector/resources/configuration/consumer-vault.properties -Dedc.fs.config=connector/resources/configuration/consumer.properties -jar connector/build/libs/roms-connector.jar
}

# Messages ---------------------------------------------------

message_dataplanes() {
    echo "Configuring dataplane endpoints"
    output=$(curl -H 'Content-Type: application/json' -d @messages/0_register_dataplane_provider.json -X POST "$providerManagement/v2/dataplanes" -s)
    pretty_print
    output=$(curl -H 'Content-Type: application/json' -d @messages/0_register_dataplane_consumer.json -X POST "$consumerManagement/v2/dataplanes" -s)
    pretty_print
}

message_asset() {
    echo "Creating kafka push asset"
    output=$(curl -H 'Content-Type: application/json' -d @messages/1_asset_provider_topic.json -X POST $providerManagement/v3/assets -s)
    pretty_print
}

message_policy() {
    echo "Creating policy"
    output=$(curl -H 'Content-Type: application/json' -d @messages/2_policy_definition.json -X POST $providerManagement/v2/policydefinitions -s)
    pretty_print
}

message_contract_definition() {
    echo "Creating contract definition"
    output=$(curl -H 'Content-Type: application/json' -d @messages/3_contract_definition.json -X POST $providerManagement/v2/contractdefinitions -s)
    pretty_print
}

message_fetch_catalog() {
    echo "Fetching catalog"
    output=$(curl -H 'Content-Type: application/json' -d @messages/4_fetch_catalog.json -X POST $consumerManagement/v2/catalog/request -s)
    pretty_print
    policyId=$(echo $output | jq -r '."dcat:dataset"."odrl:hasPolicy"."@id"')
    printf "Policy id: $policyId\n"
    setPolicyIdToContractNegotiation $policyId
}

message_negotiate_contract() {
    echo "Negotiating contract"
    output=$(curl -H 'Content-Type: application/json' -d @messages/5_contract_negotiation.json -X POST $consumerManagement/v2/contractnegotiations -s)
    pretty_print
    contractId=$(echo $output | jq -r '."@id"')
    printf "Contract id: $contractId\n"
}

message_contract_agreement() {
    echo "Get Contract Status"
    output=$(curl -H 'Content-Type: application/json' -X GET $consumerManagement/v2/contractnegotiations/$1 -s)
    pretty_print
    contractAgreementId=$(echo $output | jq -r '."contractAgreementId"')
    printf "Contract Agreement id: $contractAgreementId\n"
    setContractAgreementIdToStartTransfer $contractAgreementId
}

message_start_transfer() {
    echo "Starting transfer"
    output=$(curl -H 'Content-Type: application/json' -d @messages/7_start_transfer.json -X POST $consumerManagement/v2/transferprocesses -s)
    pretty_print
    transferProcessId=$(echo $output | jq -r '."@id"')
    printf "Transfer process id: $transferProcessId\n"
}

message_transfer_status() {
    echo "Get Transfer Status"
    output=$(curl -H 'Content-Type: application/json' -X GET $consumerManagement/v2/transferprocesses/$1 -s)
    pretty_print
}


# Utils ---------------------------------------------------
output=""
pretty_print() {
    echo $output | jq -R 'fromjson? | select(type == "object")' --color-output
}

setPolicyIdToContractNegotiation() {
    echo "Setting policy id to contract negotiation message"
    jq --arg i "$1" '."policy"."@id" = $i' messages/5_contract_negotiation.json > tmp.json && mv tmp.json messages/5_contract_negotiation.json
}

setContractAgreementIdToStartTransfer() {
    echo "Setting contract agreement id to start transfer message"
    jq --arg i "$1" '."contractId" = $i' messages/7_start_transfer.json > tmp.json && mv tmp.json messages/7_start_transfer.json
}

main "$@"   