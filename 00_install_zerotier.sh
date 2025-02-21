source .env

echo "-------------------------------------------------------------"
echo "Installing Zerotier and dependencies"
echo "-------------------------------------------------------------"

chmod 777 /tmp/
sudo apt update -y

sudo apt-get install bridge-utils -y
sudo apt-get install netplan.io -y
sudo apt-get install curl -y
sudo apt-get install ca-certificates -y


# EL -k en el curl es para que no verifique el certificado SSL
curl -k https://install.zerotier.com | sudo bash

