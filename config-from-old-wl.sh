#!/bin/bash

cd


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
cp $HOME/wl_formated.txt $HOME/wl_backup/$backup_wl_file
echo "ĐÃ SAO CHÉP FILE VÀO $HOME/wl_backup"

# Doc file wl_formated.txt va tao cac file cau hinh
i=1
while IFS='|' read -r address mnemonic; do
    mnemonic=$(echo "$mnemonic" | tr -cd 'a-z ')
    cat <<EOF > $HOME/allora-huggingface-walkthrough/wl_${i}_config.json
{
    "wallet": {
        "addressKeyName": "wl${i}",
        "addressRestoreMnemonic": "${mnemonic}",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.5,
        "nodeRpc": "https://allora-rpc.testnet.allora.network/",
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
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 8,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BNB"
            }
        },
        {
            "topicId": 9,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
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
        },
        {
            "topicId": 11,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/topic11/{Team}",
                "Team": "R"
            }
        }
    ]
}
EOF
    i=$((i+1))
done < $HOME/wl_formated.txt
