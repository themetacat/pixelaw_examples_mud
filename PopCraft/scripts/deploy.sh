#!/bin/bash

set -e

echo -e "Check if anvil is running('pnpm mud deploy' need this)."
anvil_p_total=`ps -ef | grep anvil | grep -v grep | wc -l`
if [ $anvil_p_total -eq 0 ]
then
    echo -e "Start anvil first!"
    exit 0
fi

RPC_URL="http://127.0.0.1:8545"
CHAIN_ID="31337"
INIT=true

for arg in "$@"; do
    # 使用等号分割键值对
    key=$(echo "$arg" | cut -d '=' -f1)
    value=$(echo "$arg" | cut -d '=' -f2-)
    
    # 根据键进行处理
    case $key in
        RPC_URL)
            RPC_URL=$value
            ;;
        CHAIN_ID)
            CHAIN_ID=$value
            ;;
        INIT)
            if [ "$value" == "false" ]; then
                INIT=false
            fi
            ;;
    esac
done
# WORLD_ADDRESS=$(cat ./worlds.json | jq -r --arg chain_id $CHAIN_ID '.[$chain_id].address')
WORLD_ADDRESS=$(grep -E "^WORLD_ADDRESS=" .env | cut -d '=' -f2-)
echo "WORLD_ADDRESS: $WORLD_ADDRESS"
SYSTEM_FILE_NAME=$(grep -E "^SYSTEM_FILE_NAME=" .env | cut -d '=' -f2-)
echo "SYSTEM_FILE_NAME: $SYSTEM_FILE_NAME"
SYSTEM_FILE_NAME=${SYSTEM_FILE_NAME:-'MyAppSystem'}
file_content=$(cat "./src/systems/${SYSTEM_FILE_NAME}.sol")
if [ -z "$file_content" ]; then
    echo "systems: $SYSTEM_FILE_NAME file content is null"
    exit 0
fi

EXETENSION_FILE=$(echo "$SYSTEM_FILE_NAME" | sed 's/System/Extension/')
if [ -z "$EXETENSION_FILE" ]; then
    echo "EXETENSION_FILE is null"
    exit 0
fi

echo -e "Register app to World contract."
forge script script/${EXETENSION_FILE}.s.sol --rpc-url $RPC_URL --broadcast
sleep 1

PRIVATE_KEY=$(grep -E "^PRIVATE_KEY=" .env | cut -d '=' -f2-)
PRIVATE_KEY=${PRIVATE_KEY:-'0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6'}
if [ $INIT != false ]; then
    echo -e "==== Init App ===="
    NAMESPACE=$(echo "$file_content" | grep -oE "string constant NAMESPACE = '[^']+'" | cut -d "'" -f2)
    if [ -z "$NAMESPACE" ]; then
        echo "NAMESPACE is empty"
        exit 0
    else
        echo "NAMESPACE: $NAMESPACE"
    fi

    SYSTEM_NAME=$(echo "$file_content" | grep -oE "string constant SYSTEM_NAME = '[^']+'" | cut -d "'" -f2)

    if [ -z "$SYSTEM_NAME" ]; then
        echo "SYSTEM_NAME is empty"
        exit 0
    else
        echo "SYSTEM_NAME: $SYSTEM_NAME"
    fi
    cast send $WORLD_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY "${NAMESPACE}_${SYSTEM_NAME}_init()" ""
else
    echo -e "==== Update App===="  
    APP_NAME=$(echo "$file_content" | grep -oE "string constant APP_NAME = '[^']+'" | cut -d "'" -f2)

    if [ -z "$APP_NAME" ]; then
        echo "APP_NAME is empty"
        exit 0
    else
        echo "APP_NAME: $APP_NAME"
    fi

    # echo "Please enter SYSTEM_ADDRESS(In the LOG item in the above output):"
    # regex="^0x[0-9a-fA-F]{40}$"
    # while true; do
    #     read SYSTEM_ADDRESS

    #     if [[ -z "$SYSTEM_ADDRESS" ]]; then
    #         echo "SYSTEM_ADDRESS not allowed null"
    #         continue
    #     fi
        
    #     if ! [[ $SYSTEM_ADDRESS =~ $regex ]]; then
    #         echo "The format of SYSTEM_ADDRESS is incorrect, it should be address, please re-enter it:"
    #         continue
    #     fi
    #     break
    # done
    CONTRACT_NAME=$(echo "$file_content" | grep -E 'contract [a-zA-Z0-9_]+ is System' )
    if [[ ! -z "$CONTRACT_NAME" ]]; then
        CONTRACT_NAME=$(echo "$CONTRACT_NAME" | awk '{print $2}')
        echo "CONTRACT_NAME: $CONTRACT_NAME"
    else
        echo "not found CONTRACT_NAME"
        exit 0
    fi

    SYSTEM_ADDRESS=$(cat "./broadcast/$EXETENSION_FILE.s.sol/$CHAIN_ID/run-latest.json" | jq -r --arg CONTRACT_NAME "$CONTRACT_NAME" '.transactions[] | select(.contractName == $CONTRACT_NAME) | .contractAddress')

    echo $SYSTEM_ADDRESS
    cast send $WORLD_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY "update_app_system(address, string)" $SYSTEM_ADDRESS $APP_NAME
fi
echo -e "Congratulations! Everything is ok! Just visit http://127.0.0.1:3000 to play."
