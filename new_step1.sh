#!/bin/bash

BOLD="\033[1m"
UNDERLINE="\033[4m"
DARK_YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RESET="\033[0;32m"

NODE_URL="http://45.76.154.161:56657"

echo "NODE_URL: $NODE_URL"

# Kiểm tra cài đặt binary "allorad"
if ! command -v allorad &> /dev/null; then
    echo "Allorad not found. Installing allorad..."
    read -p "Enter version to install (ex: 0.5.0): " version
    curl -sSL https://raw.githubusercontent.com/allora-network/allora-chain/main/install.sh | bash -s -- v$version
    echo "export PATH=$PATH:$HOME/.local/bin" >> ~/.bash_profile
    source ~/.bash_profile
else
    echo "Allorad already installed."
fi

# Tải về repository allora-huggingface-walkthrough
echo "Cloning allora-huggingface-walkthrough repository..."
cd $HOME
rm -rf allora-huggingface-walkthrough
git clone https://github.com/allora-network/allora-huggingface-walkthrough.git
cd allora-huggingface-walkthrough

# Tải về các file cần thiết
cd $HOME/allora-huggingface-walkthrough
rm -f requirements.txt && wget https://raw.githubusercontent.com/lyhaithanh/Allora-Setup/master/requirements.txt
rm -f app.py && wget https://raw.githubusercontent.com/lyhaithanh/Allora-Setup/master/app.py
mkdir -p wl_backup
backup_wl_file="wl_formated_$(date +'%Y%m%d_%H%M%S').txt"
mv $HOME/wl_formated.txt $HOME/wl_backup/$backup_wl_file
echo "DA BACK UP FILE VAO $HOME/wl_backup"

echo -e "${BOLD}${DARK_YELLOW}Tao vi funding${RESET}"
funding=$(allorad keys show fundingWl -a --keyring-backend test 2>/dev/null)
if [ -z "$funding" ]; then
    echo "Import vi funding:"
    allorad keys add fundingWl --recover --keyring-backend test
    wait
else
    echo "Vi funding da ton tai: $funding"
fi


i=1
read -p "Nhap so luong vi muon khoi tao: " quantities
while [ $i -le $quantities ]
do
    echo "=====Config Wallet $i======"
    echo "Xoa vi cu neu co"
    echo y | allorad keys delete wl$i --keyring-backend test  2>/dev/null
    wallet_info=$(allorad keys add wl$i --keyring-backend test --output json | jq)
    echo $wallet_info >> $HOME/wl.txt
    name=$(echo "$wallet_info" | jq -r '.name')
    address=$(echo "$wallet_info" | jq -r '.address')
    mnemonic=$(echo "$wallet_info" | jq -r '.mnemonic')
    echo "$address|$mnemonic" >> $HOME/wl_formated.txt
    echo "WalletName: $name"
    echo "Address: $address"
    sleep 2
    allorad tx bank send fundingWl $(allorad keys show wl$i -a --keyring-backend test) 10000000000000000uallo --chain-id allora-testnet-1 --keyring-backend test --node $NODE_URL --gas-prices 1000000uallo --gas 1000000 -y
    sleep 5
    if [ -f config.json ]; then
        rm config.json
        echo "Removed existing config.json file."
    fi
    cat <<EOF > wl_${i}_config.json
{
    "wallet": {
        "addressKeyName": "$name",
        "addressRestoreMnemonic": "$mnemonic",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.5,
        "nodeRpc": "$NODE_URL",
        "maxRetries": 2,
        "delay": 1,
        "submitTx": true
    },
    "worker": [
        {
            "topicId": 1,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 15,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 3,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 15,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BTC"
            }
        },
        {
            "topicId": 5,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 15,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "SOL"
            }
        },
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 15,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 8,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 15,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BNB"
            }
        },
        {
            "topicId": 9,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 15,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ARB"
            }
        },
        {
            "topicId": 10,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{BlockHeight}",
                "BlockHeight": "sys.argv[2]"
            }
        }
    ]
}
EOF
    sleep 1
    ((i++))
done
