echo "==========Building...============"
sudo apt update
sudo apt install docker.io
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
cd allora-huggingface-walkthrough
docker-compose up --build -d

curl -s http://127.0.0.1:8000/collect-price

cron_command="*/10 * * * * /usr/bin/curl -s http://127.0.0.1:8000/collect-price"

crontab -l | grep -qF "$cron_command"

if [ $? -ne 0 ]; then
    (crontab -l 2>/dev/null; echo "$cron_command") | crontab -
    echo "Collect price cron job added."
else
    echo "Collect price cron job is exists. Skip"
fi

echo "Done!"
