#!/bin/bash -xe

export DEBIAN_FRONTEND=noninteractive
export HOMEDIR=/home/ubuntu/mount
sleep 5
sudo mkfs -t ext4 /dev/xvdh
sudo mkdir $HOMEDIR
sudo mount /dev/xvdh $HOMEDIR
cd $HOMEDIR
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
wget -qO- https://get.docker.com/ | sh
sleep 5
sudo curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
# !Sub "NETWORK_ID=${NetworkId}"
# !Sub "export INITIAL_BALANCE=${InitialBalance}"
printenv
printf -v INITIAL_BALANCE_HEX \"%x\" \"$INITIAL_BALANCE\"
printf -v CURRENT_TS_HEX \"%x\" $(date +%s)
date +%s | sha256sum | base64 | head -c 32 > password.txt
curl -L https://raw.githubusercontent.com/gochain-io/aws/master/genesis.json -o $HOMEDIR/genesis.json
curl -L https://raw.githubusercontent.com/gochain-io/aws/master/docker-compose.yml -o $HOMEDIR/docker-compose.yml
export ACCOUNT_ID=$(sudo docker run -v $PWD:/root gochain/gochain gochain --datadir /root/node --password /root/password.txt account new | awk -F '[{}]' '{print $2}')
echo \"GOCHAIN_ACCT=0x$ACCOUNT_ID\" > $HOMEDIR/.env
echo \"GOCHAIN_NETWORK=$NETWORK_ID\" >> $HOMEDIR/.env
sed -i \"s/<network_id>/$NETWORK_ID/\" $HOMEDIR/genesis.json
sed -i \"s/<current_ts_hex>/$CURRENT_TS_HEX/\" $HOMEDIR/genesis.json
sed -i \"s/<signer_address>/$ACCOUNT_ID/\" $HOMEDIR/genesis.json
sed -i \"s/<voter_address>/$ACCOUNT_ID/\" $HOMEDIR/genesis.json
sed -i \"s/<address>/$ACCOUNT_ID/\" $HOMEDIR/genesis.json
sed -i \"s/<hex>/$INITIAL_BALANCE_HEX/\" $HOMEDIR/genesis.json
sudo sudo rm -rf $PWD/node/GoChain
sudo docker run --rm -v $PWD:/gochain -w /gochain gochain/gochain gochain --datadir /gochain/node init genesis.json
sudo docker-compose up -d       
