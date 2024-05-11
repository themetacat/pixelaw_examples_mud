#!/bin/bash
set -e

SYSTEM_FILE_NAME=$(grep -E "^SYSTEM_FILE_NAME=" .env | cut -d '=' -f2-)
echo "SYSTEM_FILE_NAME: $SYSTEM_FILE_NAME"
SYSTEM_FILE_NAME=${SYSTEM_FILE_NAME:-'MyAppSystem'}
ABI_JSON_PATH="$(pwd)/out/${SYSTEM_FILE_NAME}.sol/${SYSTEM_FILE_NAME}.abi.json"

if [ ! -f "${ABI_JSON_PATH}" ]; then
    ABI_JSON_PATH=""
    echo "ABI_JSON not found: $ABI_JSON_PATH"
    exit 0
else
    echo "ABI_JSON: $ABI_JSON_PATH"
fi

COMMON_JSON_PATH="$(pwd)/out/common.sol/common.json"


cd ../../

if [ ! -d "./PixeLAW_game_contract_abi" ] || [ -z "$(ls -A ./PixeLAW_game_contract_abi)" ]; then
    echo "========= git clone ============"
    git clone https://github.com/themetacat/PixeLAW_game_contract_abi.git
fi


cd ./PixeLAW_game_contract_abi

echo "========= copy abi json: ${ABI_JSON_PATH} ============"
cp -f "$ABI_JSON_PATH" .

if [ -f "${COMMON_JSON_PATH}" ]; then
    echo "========= copy common json: ${COMMON_JSON_PATH} ============"
    cp -f "$COMMON_JSON_PATH" "./${SYSTEM_FILE_NAME}Common.json"
fi

echo "========= copy success ============"

git add .
git commit -m "add ${SYSTEM_FILE_NAME}.abi.json"
git pull origin main -v --no-rebase
git push origin main -v

echo "============ Upload success! ============"
