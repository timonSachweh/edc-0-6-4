#!/bin/bash

export kafka=""
export providerManagement=""
export providerControl=""
export providerPublic=""
export providerProtocol=""
export consumerManagement=""
export consumerControl=""
export consumerPublic=""
export consumerProtocol=""


main() {
    #printVariables

    if [ -n "$kafka" ]; then
        setKafkaUrl $kafka
    fi
    if [ -n "$providerManagement" ]; then
        setProviderManagement $providerManagement
    fi
    if [ -n "$providerControl" ]; then
        setProviderControl $providerControl
    fi
    if [ -n "$providerPublic" ]; then
        setProviderPublic $providerPublic
    fi
    if [ -n "$providerProtocol" ]; then
        setProviderProtocol $providerProtocol
    fi
    if [ -n "$consumerManagement" ]; then
        setConsumerManagement $consumerManagement
    fi
    if [ -n "$consumerControl" ]; then
        setConsumerControl $consumerControl
    fi
    if [ -n "$consumerPublic" ]; then
        setConsumerPublic $consumerPublic
    fi
    if [ -n "$consumerProtocol" ]; then
        setConsumerProtocol $consumerProtocol
    fi
}

setKafkaUrl() {
    echo "Setting kafka url to $1"
    jq --arg k "$1" '."dataAddress"."kafka.bootstrap.servers" = $k' messages/1_asset_provider_topic.json > tmp.json && mv tmp.json messages/1_asset_provider_topic.json
    jq --arg k "$1" '."dataDestination"."kafka.bootstrap.servers" = $k' messages/7_start_transfer.json > tmp.json && mv tmp.json messages/7_start_transfer.json
}

setProviderManagement() {
    echo "Setting provider management url to $1"
    sed -i -r "s%^providerManagement=\"[^ ]*\"%providerManagement=\"${providerManagement}\"%" run.sh

}
setProviderControl() {
    echo "Setting provider control url to $1"
    jq --arg v "$1" '."url" = $v' messages/0_register_dataplane_provider.json > tmp.json && mv tmp.json messages/0_register_dataplane_provider.json
}
setProviderPublic() {
    echo "Setting provider public url to $1"
    jq --arg v "$1" '."properties"."https://w3id.org/edc/v0.0.1/ns/publicApiUrl/publicApiUrl" = $v' messages/0_register_dataplane_provider.json > tmp.json && mv tmp.json messages/0_register_dataplane_provider.json
}
setProviderProtocol() {
    echo "Setting provider protocol url to $1"
    jq --arg v "$1" '."counterPartyAddress" = $v' messages/4_fetch_catalog.json > tmp.json && mv tmp.json messages/4_fetch_catalog.json
    jq --arg v "$1" '."counterPartyAddress" = $v' messages/5_contract_negotiation.json > tmp.json && mv tmp.json messages/5_contract_negotiation.json
    jq --arg v "$1" '."counterPartyAddress" = $v' messages/7_start_transfer.json > tmp.json && mv tmp.json messages/7_start_transfer.json
}

setConsumerManagement() {
    echo "Setting consumer management url to $1"
    sed -i -r "s%^consumerManagement=\"[^ ]*\"%consumerManagement=\"${consumerManagement}\"%" run.sh
}
setConsumerControl() {
    echo "Setting consumer control url to $1"
    jq --arg v "$1" '."url" = $v' messages/0_register_dataplane_consumer.json > tmp.json && mv tmp.json messages/0_register_dataplane_consumer.json
}
setConsumerPublic() {
    echo "Setting consumer public url to $1"
    jq --arg v "$1" '."properties"."https://w3id.org/edc/v0.0.1/ns/publicApiUrl/publicApiUrl" = $v' messages/0_register_dataplane_consumer.json > tmp.json && mv tmp.json messages/0_register_dataplane_consumer.json
}


# Variable related commands ------------------------

printVariables() {
    echo "kafka: $kafka"
    echo "providerManagement: $providerManagement"
    echo "providerControl: $providerControl"
    echo "providerPublic: $providerPublic"
    echo "providerProtocol: $providerProtocol"
    echo "consumerManagement: $consumerManagement"
    echo "consumerControl: $consumerControl"
    echo "consumerPublic: $consumerPublic"
}

showHelp() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help                           Show this help message and exit"
    echo "  --kafka <url>                        Set the kafka url"
    echo "  --provider-management <url>          Set the provider management url"
    echo "  --provider-control <url>             Set the provider control url"
    echo "  --provider-public <url>              Set the provider public url"
    echo "  --provider-protocol <url>            Set the provider protocol url"
    echo "  --consumer-management <url>          Set the consumer management url"
    echo "  --consumer-control <url>             Set the consumer control url"
    echo "  --consumer-public <url>              Set the consumer public url"
}

# Call getopt to validate the provided input. 
options=$(getopt -o "h" --long "help,kafka:,provider-management:,provider-control:,provider-public:,provider-protocol:,consumer-management:,consumer-control:,consumer-public:" -- "$@")
[ $? -eq 0 ] || { 
    echo "Incorrect options provided"
    exit 1
}
eval set -- "$options"
while true; do
    case "$1" in
    -h|--help)
        showHelp
        exit 0
        ;;
    --kafka)
        shift;
        export kafka=$1
        ;;
    --provider-management)
        shift;
        export providerManagement=$1
        ;;
    --provider-control)
        shift;
        export providerControl=$1
        ;;
    --provider-public)
        shift;
        export providerPublic=$1
        ;;
    --provider-protocol)
        shift;
        export providerProtocol=$1
        ;;
    --consumer-management)
        shift;
        export consumerManagement=$1
        ;;
    --consumer-control)
        shift;
        export consumerControl=$1
        ;;
    --consumer-public)
        shift;
        export consumerPublic=$1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

main "$@"