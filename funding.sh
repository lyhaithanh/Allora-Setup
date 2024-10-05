#!/bin/bash

echo "Kiem tra vi funding"
funding=$(allorad keys show fundingWl -a --keyring-backend test 2>/dev/null)
if [ -z "$funding" ]; then
    echo "Import vi funding:"
    allorad keys add fundingWl --recover --keyring-backend test
    wait
else
    echo "Vi funding da ton tai: $funding"
fi

RPC_LIST=(
    "http://66.70.177.125:27657"
    "http://147.135.140.50:26657"
    "http://103.88.234.61:26657"
    "http://34.69.129.28:26657"
    "http://65.108.126.188:22657"
    "http://162.55.245.254:30657"
    "http://46.4.225.243:26657"
    "http://23.88.66.141:22657"
    "http://88.99.90.44:31657"
    "http://65.108.6.41:42657"
    "http://88.198.66.137:21657"
    "http://65.108.196.139:26657"
    "http://168.119.91.28:62657"
    "http://78.46.69.209:26657"
    "http://116.202.115.87:33657"
    "http://144.76.32.69:13657"
    "http://95.216.244.226:58657"
    "http://176.9.149.220:47657"
    "http://136.243.149.244:23657"
    "http://49.12.121.25:26657"
    "http://176.9.22.213:31657"
    "http://167.235.178.174:59657"
    "http://116.202.174.53:52657"
    "http://65.109.30.35:51657"
    "http://162.55.20.234:26657"
    "http://65.108.40.108:11657"
    "http://95.217.61.32:26657"
    "http://65.108.104.231:54657"
    "http://195.201.12.22:17657"
    "http://65.108.233.225:38657"
)

# Chon ngau nhien 1 RPC tu danh sach
NODE_URL=${RPC_LIST[$RANDOM % ${#RPC_LIST[@]}]}


while IFS="|" read -r wallet mnemonic
do
    echo "========Checking $wallet========="
    echo "Using $NODE_URL"

    BAL=$(allorad q bank balances $wallet --node $NODE_URL -o json | jq -r '.balances[] | select(.denom=="uallo") | .amount')
    sleep 1
    echo "Balance: $BAL"
    if [ -z "$BAL" ]; then
        echo "Sending..."
        allorad tx bank send fundingWl $wallet 10000000000000000uallo --chain-id allora-testnet-1 --keyring-backend test --node $NODE_URL --gas-prices 1000000uallo --gas 100000 -y
        sleep 5
    else
        echo "No need to send"
    fi

done < "$HOME/wl_formated.txt"
