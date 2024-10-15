echo "-------------------------------------------------------------"
echo "Configurando Zerotier"
echo "-------------------------------------------------------------"

# Solicitar el networi ID de zerotier
read -p "Introduzca el network ID de zerotier: " ZEROTIER_NETWORK

echo "-------------------------------------------------------------"
echo "Modificamos el archivo /var/lib/zerotier-one/networks.d/${ZEROTIER_NETWORK}.local.conf "
echo "-------------------------------------------------------------"

cat <<EOF > /var/lib/zerotier-one/networks.d/${ZEROTIER_NETWORK}.local.conf
allowManaged=0
allowGlobal=0
allowDefault=0
allowDNS=0

EOF


echo "-------------------------------------------------------------"
echo "Ahora requerimos la IP de la interfaz de zerotier, para ver la ip ejecutaremos ifconfig y veremos la ip asignada"
echo "-------------------------------------------------------------"

sudo ifconfig

echo "-------------------------------------------------------------"
echo "Introduzca la IP asociada a la interfaz ztxxxxxxx"
echo "-------------------------------------------------------------"

read -p "Introduzca la IP asignada: " ZEROTIER_IP

echo "-------------------------------------------------------------"
echo "Introduzca el nombre de la interfaz ztxxxxxxx"
echo "-------------------------------------------------------------"

read -p "Introduzca el nombre de la interfaz zerotier: " ZEROTIER_INTERFACE

echo "-------------------------------------------------------------"
echo "Introduzca el nombre de la interfaz con salida a internet (puede ser ppp0 o mlan0)"
echo "-------------------------------------------------------------"

read -p "Introduzca el nombre de la interfaz con salida a internet: " INTERNET_INTERFACE


# Obtener el gateway IP, que será la IP de la interfaz zerotier con el último octeto 1

GATEWAY_IP=$(echo $ZEROTIER_IP | cut -d. -f1-3).1

# Obtener la red de zerotier, que será la IP de la interfaz zerotier con el último octeto 0/24

ZT_NETWORK_INTERFACE=$(echo $ZEROTIER_IP | cut -d. -f1-3).0/24

echo "-------------------------------------------------------------"
echo "También se requiere el nombre de la interfaz a hacer bridge, normalmente es eth0 o enp0s3"
echo "-------------------------------------------------------------"

read -p "Introduzca el nombre de la interfaz a hacer bridge: " INTERFACE_NAME

# Muestra la IP que se acaba de introducir 

echo "-------------------------------------------------------------"
echo "La IP introducida es ${ZEROTIER_IP} y la interfaz es ${INTERFACE_NAME}, configurando..."
echo "-------------------------------------------------------------"

cat <<EOF > /etc/netplan/50-cloud-init.yaml

# This file is generated from information provided by
# the datasource.  Changes to it will not persist across an instance.
# To disable cloud-init's network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
  version: 2
  ethernets:
    ${INTERFACE_NAME}:
      addresses: []
      dhcp4: false
      optional: true
  bridges:
    br0:
      # Colocar aquí la ip asignada a la interfaz seguida de la máscara de red Ej. 192.168.192.5/24
      addresses: [${ZEROTIER_IP}/24]
      dhcp4: false
      interfaces:
        - ${INTERFACE_NAME}
      # Colocar aquí la IP del gateway de la red Ej. 192.168.192.1
      gateway4: ${GATEWAY_IP}
      nameservers:
        addresses: [8.8.8.8]

EOF


sudo netplan apply


sudo mkdir /opt/network

LOCAL_IF="${INTERFACE_NAME}"
VPN_IF="${ZEROTIER_INTERFACE}"
INTER_IF="${INTERNET_INTERFACE}"
BR_IP="${ZEROTIER_IP}"
BR_NET="${ZT_NETWORK_INTERFACE}"

cat <<EOF > /opt/network/bridge.sh
#!/bin/bash
PATH="/bin:/sbin:/usr/bin:/usr/sbin"
export PATH

LOCAL_IF="${LOCAL_IF}"
# No confundir con el nombre de la red en el panel de zerotier
VPN_IF="${LOCAL_IF}"
# Interfaz cin acceso a internet Ej. ppp0
INTER_IF="${LOCAL_IF}"

# IP anteriormente asignada por zerotier al host, la misma que se configuró en un inicio en el bridge Ej. 192.168.192.5/24
BR_IP="${ZEROTIER_IP}"
# IP de la red de zerotier seguida del prefijo Ej. 192.168.192.0/24
BR_NET="${ZT_NETWORK_INTERFACE}"

date

# esperem fins que la interficie existeixi
while [ ! -e "/sys/class/net/$VPN_IF" ];
do
  sleep 2;
done

# Para esperar el internet del chip
while [ ! -e "/sys/class/net/$INTER_IF" ];
do
  sleep 2;
done

# Esto lo estoy agregando para poder tener acceso a internet correctamente
# Cuando el sistema se reinicia, el ppp0 se demora en cargar y se utiliza el br0
# como salida de internet. Entonces para que use el ppp0 ejecutamos

ip route del default

# bridge
#brctl addbr br0
#brctl addif br0 ${LOCAL_IF}
brctl addif br0 ${VPN_IF}
brctl setfd br0 0
#brctl setmaxage br0 0

# ip
#ifconfig ${LOCAL_IF} 0.0.0.0
#ifconfig ${VPN_IF} 0.0.0.0
#ifconfig br0 ${BR_IP}
#ifconfig ${LOCAL_IF} up
#ifconfig ${VPN_IF} up
#ifconfig br0 up

# route
#ip route add ${BR_NET} dev br0

# iptables
iptables -I FORWARD -i ${VPN_IF} -j ACCEPT
iptables -I FORWARD -o ${VPN_IF} -j ACCEPT
iptables -I FORWARD -i br0 -j ACCEPT
iptables -I FORWARD -o br0 -j ACCEPT
iptables -I FORWARD -i ${LOCAL_IF} -j ACCEPT
iptables -I FORWARD -o ${LOCAL_IF} -j ACCEPT

EOF


cat <<EOF > /etc/systemd/system/bridge-start.service

[Unit]
Description=Script de puente de red
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /opt/network/bridge.sh

[Install]
WantedBy=default.target

EOF

echo "------------------------------------------------------------------------------------"
echo "Zerotier como bridge fue configurado correctamente, reiniciando el sistema"
echo "------------------------------------------------------------------------------------"

echo "------------------------------------------------------------------------------------"
echo "Para ingresar a este dispositivo utiliza la IP ${ZEROTIER_IP} y el puerto 22)"
echo "Puedes acceder tanto desde ethernet como cliente de zerotier usando la misma IP."
echo "------------------------------------------------------------------------------------"


sudo systemctl enable bridge-start.service
sudo systemctl start bridge-start.service


# Sleep 5 seconds
sleep 5

sudo reboot



