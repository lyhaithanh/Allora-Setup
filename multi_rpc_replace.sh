#!/bin/bash

dir_path="$HOME/allora-huggingface-walkthrough"

rpc_file="$HOME/allora-huggingface-walkthrough/rpc_list.txt"

if [ ! -f "$rpc_file" ]; then
    echo "File rpc_list.txt không tồn tại!"
    exit 1
fi
mapfile -t rpc_list < "$rpc_file"
num_files=$(ls "$dir_path"/wl_*.json | wc -l)
num_rpcs=${#rpc_list[@]}

if [ "$num_files" -gt "$num_rpcs" ]; then
    echo "Không đủ RPC trong rpc_list.txt để thay thế tất cả các file config!"
    exit 1
fi
get_random_rpc() {
    local rpc_index=$((RANDOM % ${#rpc_list[@]}))
    local rpc_value=${rpc_list[$rpc_index]}
    unset rpc_list[$rpc_index]
    rpc_list=("${rpc_list[@]}")
    echo "$rpc_value"
}
for file in "$dir_path"/wl_*.json; do
    echo "Updating file $file..."
    
    new_nodeRpc=$(get_random_rpc)
    
    jq --arg new_nodeRpc "$new_nodeRpc" '.wallet.nodeRpc = $new_nodeRpc' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

    if [ $? -eq 0 ]; then
        echo "Successfully updated $file with new RPC: $new_nodeRpc"
    else
        echo "Failed to update $file"
        exit 1
    fi
done

echo "All config files have been updated."
