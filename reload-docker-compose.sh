#!/bin/bash

dir_path="$HOME/allora-huggingface-walkthrough"
cd $dir_path

quantities=$(wc -l < $HOME/wl_formated.txt)

rm -f $dir_path/worker-data/env_file_*
i=1
while [ $i -le $quantities ]
do
    cp ./wl_${i}_config.json ./config.json
    ./init.config
    cp ./worker-data/env_file ./worker-data/env_file_${i}
    sleep 1
    ((i++))
done

output_file="docker-compose.yaml"
rm -f $output_file

cat <<EOF > "$output_file"
services:
    inference:
        container_name: inference-hf
        build:
            context: .
            dockerfile: Dockerfile
        command: python -u /app/app.py
        ports:
            - "8000:8000"

EOF

for env_file in ./worker-data/env_file_*; do

    base_name=$(basename "$env_file")
    number="${base_name#env_file_}"
    container_name="worker${number}"
    

    cat <<EOF >> "$output_file"
    $container_name:
        container_name: $container_name
        image: alloranetwork/allora-offchain-node:latest
        volumes:
            - ./worker-data:/data
        depends_on:
            - inference
        env_file:
            - $env_file

EOF
done

cat <<EOF >> "$output_file"
volumes:
    inference-data:
    worker-data:
EOF
echo "Done!"
