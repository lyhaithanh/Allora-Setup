from flask import Flask, Response
import requests
import json
import random

# create our Flask app
app = Flask(__name__)

CG_Keys = [
    "CG-uKcYkypYQ2toUYg8XSDkZZGQ",
    "CG-r7vNF4Edc3SwwKArrTVgsSUj",
    "CG-n715kFUzxzwimnwv5bcUWYSA",
    "CG-3w7kD2tbWxR6VqwLyYQP11nL",
    "CG-rWhjoS5YQkAmyC4JLfSdUQLg",
    "CG-2ZqHMNu8LJhxKeexeh3Ms1eY",
    "CG-A7D2gXiie4dTnEDuudpn5KJw",
    "CG-FwfH3c3AM5quYShhZnBPREfN",
    "CG-4uhriPpH6bkAWRJ5tmqRKts1",
    "CG-CHi9ArZHNzjfQQk7nPNwonJ4",
    "CG-jpBdHSbwcrJQ3MqSjBqePjdL",
    "CG-3njo2XquKKST3hKRYu9qwdqj",
    "CG-HmhdZy1qr5uhfJz3hbaD4G2p",
    "CG-GYaXKyG2jA7YKYqGgkiQtHQs",
    "CG-d9qnroRMT6a3QHZRpAKtXA25",
    "CG-x1FuKMZFU4NqkjFEKpAj7weo",
    "CG-Xs7Aazo4ebNkgXr21DhQq2Ze",
    "CG-xy49uDA5MKAfaiNFYPanUAEJ",
    "CG-VbwAp9cVGPRWLMyJRGahtT3C",
    "CG-MGtWN3YL7N8bCS7CxgtgRWDN",
    "CG-EB7NZ2odgKm4CdT5J2v3MEEh",
    "CG-S8DKSgwz4oCtanrhC8U2MnZ6"
]

UP_Keys = [
    "UP-863ab9041e474196bcc5e7bb",
    "UP-3856b30421ac4192a67be52b",
    "UP-90d9b5d530934152af043435",
    "UP-d83d62325ee641d39590b8b6",
    "UP-a72ed227f6d5459ba01dec52",
    "UP-e3234634253b4b54b3a57cd3",
    "UP-3f4148a780c946f1b39b06c2",
    "UP-63acc5b094064e4bbe53a9c6",
    "UP-778e32eccc7642bbb71c5adc",
    "UP-3cad6b706ab545d58e89b001",
    "UP-8e5640422d004e65af1c9831"
]

def get_memecoin_token(blockheight):
    UP_Key = random.choice(UP_Keys)
    
    upshot_url = f"https://api.upshot.xyz/v2/allora/tokens-oracle/token/{blockheight}"
    headers = {
        'accept': 'application/json',
        'x-api-key': UP_Key
    }
    response = requests.get(upshot_url, headers=headers)
        
    if response.status_code == 200:
        data = response.json()
        name_token = str(data["data"]["token_id"]) #return "boshi"
        return name_token
    else:
        raise ValueError("Unsupported token") 

def get_meme_price(token):
    CG_Key = random.choice(CG_Keys)
    base_url = "https://api.coingecko.com/api/v3/simple/price?ids="
    token_map = {
        'ETH': 'ethereum',
        'SOL': 'solana',
        'BTC': 'bitcoin',
        'BNB': 'binancecoin',
        'ARB': 'arbitrum'
    }
    token = token.upper()
    print(CG_Key)
    if token in token_map:
        url = f"{base_url}{token_map[token]}&vs_currencies=usd"
        headers = {
            "accept": "application/json",
            "x-cg-demo-api-key": CG_Key
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            price = data[token_map[token]]["usd"]
            print(price)
            return price
    else:
        raise ValueError("Unsupported token") 
    return

def get_simple_price(token):
    CG_Key = random.choice(CG_Keys)
    base_url = "https://api.coingecko.com/api/v3/simple/price?ids="
    token_map = {
        'ETH': 'ethereum',
        'SOL': 'solana',
        'BTC': 'bitcoin',
        'BNB': 'binancecoin',
        'ARB': 'arbitrum'
    }
    token = token.upper()
    headers = {
        "accept": "application/json",
        "x-cg-demo-api-key": CG_Key
    }
    if token in token_map:
        url = f"{base_url}{token_map[token]}&vs_currencies=usd"
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            price = data[token_map[token]]["usd"]
            return price
        
    elif token not in token_map:
        token = token.lower()
        url = f"{base_url}{token}&vs_currencies=usd"
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            return data[token]["usd"]
        
    else:
        raise ValueError("Unsupported token") 

@app.route("/collect-price")
def collect_price():
    tokens = [ 'ETH', 'SOL', 'BTC', 'BNB', 'ARB']
    for token in tokens:
        price = get_simple_price(token)
        with open(token + ".txt", "w") as file:
            file.write(str(price))
        
    return Response("Success", status=200, mimetype='application/json')

# define our endpoint
@app.route("/inference/<string:tokenorblockheightorparty>")
def get_inference(tokenorblockheightorparty):
    if tokenorblockheightorparty.isnumeric():
        namecoin = get_memecoin_token(tokenorblockheightorparty)
        price = get_simple_price(namecoin)
        price1 = price + price*0.3/100
        price2 = price - price*0.3/100
        predict_result = str(round(random.uniform(price1, price2), 8))
    elif len(tokenorblockheightorparty) == 3 and tokenorblockheightorparty.isalpha(): 
        try:
            with open(tokenorblockheightorparty + ".txt", "r") as file:
                content = file.read().strip()
            price = float(content)
            price1 = price + price*0.3/100
            price2 = price - price*0.3/100
            predict_result = str(round(random.uniform(price1, price2), 8))
        except Exception as e:
            return Response(json.dumps({"pipeline error": str(e)}), status=500, mimetype='application/json')
        
    else:
        predict_result = str(round(random.uniform(44, 51), 8))
    
    return predict_result

# define predict party
@app.route("/inference/topic11/<string:team>")
def guestTeam(team):
    lowest = 44
    highest = 51
    random_float = str(round(random.uniform(lowest, highest), 3))
    return Response(random_float, status=200)

# run our Flask app
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8000, debug=True)
