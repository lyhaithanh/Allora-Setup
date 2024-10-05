#!/bin/bash

# Dinh nghia cac bien
ALLORA="$HOME/allora-huggingface-walkthrough"
WORKERDIE_FILE="$HOME/workerdie.txt"
NUMWORKERDIE_FILE="$HOME/numworkerdie.txt"
LOG_FILE="$HOME/logs.txt"
WORKER_DIR="$HOME/allora-huggingface-walkthrough/worker-data"
RPC_LIST="/root/rpc_list.txt"

# Ham kiem tra va tai danh sach RPC moi moi 5 phut
check_and_update_rpc_list() {
    echo "Dang tai danh sach RPC moi..."

    # Tai danh sach RPC tu URL va loc cac endpoint phu hop
    json_data=$(curl -s https://server-3.itrocket.net/testnet/allora/.rpc_combined.json)

    endpoints=$(echo "$json_data" | jq -r '
      to_entries 
      | map(select(.value.tx_index == "on")) 
      | sort_by(.value.latest_block_height | tonumber) 
      | reverse 
      | .[:100] 
      | .[].key
      | "http://" + .
    ')

    # Them 10 dong "https://allora-testnet-rpc.itrocket.net" vao cuoi danh sach
    fixed_endpoints=$(for i in {1..9}; do echo "https://testnet-allora-rpc.rhino-apis.com"; done)

    # Ghi danh sach moi vao tep RPC_LIST
    echo "$endpoints" > "$RPC_LIST"
    echo "$fixed_endpoints" >> "$RPC_LIST"

    echo "Danh sach RPC moi da duoc cap nhat vao $RPC_LIST."
}

# Di chuyen vao thu muc ALLORA
echo "Chuyen thu muc sang $ALLORA..."
cd "$ALLORA" || { echo "Khong the chuyen thu muc sang $ALLORA. Tap lenh dung."; exit 1; }

# Quet Docker logs moi 5 phut va kiem tra danh sach RPC
while true; do
    # Kiem tra va cap nhat danh sach RPC moi
    check_and_update_rpc_list

    echo "Bat dau ghi logs Docker Compose vao logs.txt..."
    
    # Ghi toan bo log cua Docker Compose vao logs.txt (log 1000 dong)
    docker-compose logs -n 1000 > "$LOG_FILE"

    # Dem so lan loi "post failed" xuat hien trong log va loc ten container bi loi tren 10 lan
    echo "Quet loi 'post failed' trong logs.txt va tim cac container bi loi tren 10 lan..."
    grep "post failed" "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | while read count container; do
        if (( count > 10 )); then
            echo "Container $container gap loi 'post failed' hon 10 lan ($count lan)."
            echo "$container" >> "$WORKERDIE_FILE"
        fi
    done

    # Xoa toan bo logs.txt sau khi xu ly
    echo "Xoa toan bo logs.txt sau khi xu ly..."
    > "$LOG_FILE"

    # Quet cac container co trang thai exited, them vao WORKERDIE_FILE
    echo "Quet cac container co trang thai exited..."
    docker ps -a --filter "status=exited" --format "{{.Names}}" >> "$WORKERDIE_FILE"

    if [[ -s "$WORKERDIE_FILE" ]]; then
        echo "Loi hoac container exited duoc phat hien. Dang ghi ten container gap loi vao $WORKERDIE_FILE."
        
        # Trich xuat cac chu so tu ten container va luu vao NUMWORKERDIE_FILE
        grep -o '[0-9]\+' "$WORKERDIE_FILE" | tr '\n' ',' | sed 's/,$//' > "$NUMWORKERDIE_FILE"
        echo "Cac container gap loi da duoc luu vao $NUMWORKERDIE_FILE voi dinh dang: $(cat $NUMWORKERDIE_FILE)"
        
        # Xoa cac container da doc khoi WORKERDIE_FILE
        echo "Xoa cac container da doc khoi $WORKERDIE_FILE."
        > "$WORKERDIE_FILE"

        # Goi logic thay doi RPC cho cac worker gap loi
        if [[ ! -s "$RPC_LIST" ]]; then
            echo "Tep $RPC_LIST khong ton tai hoac rong. Tap lenh dung."
            exit 1
        fi

        if [[ -s "$NUMWORKERDIE_FILE" ]]; then
            # Doc tung so tu numworkerdie.txt, tach bang dau phay va xu ly chung
            IFS=',' read -ra NUM_ARRAY <<< "$(cat "$NUMWORKERDIE_FILE")"
            for NUM in "${NUM_ARRAY[@]}"; do
                echo "Bat dau xu ly worker: $NUM"

                # Di chuyen vao thu muc worker-data
                cd "$WORKER_DIR" || { echo "Khong the chuyen thu muc den $WORKER_DIR. Tap lenh dung."; exit 1; }

                # Lay ngau nhien 1 dong tu rpc_list.txt cho moi worker va gan vao bien RPC
                RPC=$(shuf -n 1 "$RPC_LIST")
                echo "Gia tri RPC duoc chon ngau nhien cho worker $NUM: $RPC"

                # Thay the gia tri "nodeRpc" trong env_file_$NUM
                sed -i "s|\"nodeRpc\":\"[^\"]*\"|\"nodeRpc\":\"$RPC\"|" "env_file_$NUM"

                # Kiem tra thanh cong cua lenh sed
                if [[ $? -eq 0 ]]; then
                    echo "Cap nhat thanh cong nodeRpc cho worker$NUM trong env_file_$NUM"
                else
                    echo "Cap nhat that bai nodeRpc cho worker$NUM trong env_file_$NUM"
                    continue
                fi

                # Xoa dong da su dung tu rpc_list.txt
                echo "Xoa gia tri RPC da su dung khoi $RPC_LIST..."
                sed -i "\|$RPC|d" "$RPC_LIST"

                # Kiem tra va xoa container neu no dang ton tai
                echo "Kiem tra neu container worker$NUM da ton tai..."
                if [[ $(docker ps -a --filter "name=worker$NUM" --format "{{.ID}}") ]]; then
                    echo "Container worker$NUM da ton tai, dang xoa container cu..."
                    docker rm -f "worker$NUM"
                fi

                # Khoi dong lai Docker container tuong ung ma khong dung cac dependencies
                echo "Khoi dong lai Docker container worker$NUM..."
                docker-compose up -d --no-deps "worker$NUM"

                # Kiem tra neu khoi dong lai thanh cong
                if [[ $? -eq 0 ]]; then
                    echo "Worker$NUM da duoc cap nhat va khoi dong lai thanh cong."
                else
                    echo "Khoi dong lai worker$NUM that bai."
                    continue
                fi

                # Xoa so da xu ly khoi NUMWORKERDIE_FILE
                echo "Xoa worker$NUM khoi $NUMWORKERDIE_FILE."
                sed -i "/\b$NUM\b/d" "$NUMWORKERDIE_FILE"
            done
        else
            echo "Khong tim thay bat ky worker nao gap loi trong $NUMWORKERDIE_FILE."
        fi
    else
        echo "Khong co container loi hoac exited nao duoc phat hien."
    fi

    # Doi 5 phut truoc khi lap lai
    echo "Cho 5 phut truoc lan quet tiep theo..."
    sleep 300
done
