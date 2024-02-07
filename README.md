Based on: https://industry40.systems/8

# Remote Access Gateway

Primero instalamos lo necesario

```
sudo apt-get update -y
sudo apt-get install bridge-utils -y
sudo apt-get install netplan.io -y
sudo apt-get install curl -y

```

INstalamos zerotier

```
sudo su
sudo curl -s https://install.zerotier.com | sudo bash

```

Nos conectamos al network de zerotier

```
zerotier-cli join 0cccb752f7ffd0ce
```

Desde el zerotier se tiene que aceptar y marcar los dos checkboxes de configuración de bridging y auto assign IP

Tambien se tiene que acceder al archivo `/var/lib/zerotier-one/network.d/0cccb752f7ffd0ce.local.conf `

```
nano /var/lib/zerotier-one/networks.d/0cccb752f7ffd0ce.local.conf
```

y colocar el contenido

```
allowManaged=0
allowGlobal=0
allowDefault=0
allowDNS=0
```

Luego crear el archivo `/etc/netplan/50-cloud-init.yaml` con el siguiente contenido (La IP es la que asigna el zerotier)

```yaml
# This file is generated from information provided by
# the datasource.  Changes to it will not persist across an instance.
# To disable cloud-init's network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
  version: 2
  ethernets:
    eth0:
      addresses: []
      dhcp4: false
      optional: true
  bridges:
    br0:
      addresses: [192.168.192.XX/24]
      dhcp4: false
      interfaces:
        - eth0
      gateway4: 192.168.192.1
      nameservers:
        addresses: [8.8.8.8]
```

Aca es importante verificar que la interfaz eth0 sea correcta y asi se llame cuando ejecutamos `ifconfig`

Luego ejecutamos

```
sudo netplan apply
```

Luego de aplicar el netplan, no se podrá acceder por ethernet con la IP conocide,a mejor acceeder por la IP que asigna el zerotier

Luego creamos la carpeta y archivo

```
sudo mkdir /opt/network
sudo nano /opt/network/bridge.sh
```

Y colocamos el siguiente contenido

```bash
#!/bin/bash
PATH="/bin:/sbin:/usr/bin:/usr/sbin"
export PATH

LOCAL_IF="eth0"
VPN_IF="ztly5urarz"
INTER_IF="ppp0"

BR_IP="192.168.192.XX/24"
BR_NET="192.168.192.0/24"

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
#brctl addif br0 $LOCAL_IF
brctl addif br0 $VPN_IF
brctl setfd br0 0
#brctl setmaxage br0 0

# ip
#ifconfig $LOCAL_IF 0.0.0.0
#ifconfig $VPN_IF 0.0.0.0
#ifconfig br0 $BR_IP
#ifconfig $LOCAL_IF up
#ifconfig $VPN_IF up
#ifconfig br0 up

# route
#ip route add $BR_NET dev br0

# iptables
iptables -I FORWARD -i $VPN_IF -j ACCEPT
iptables -I FORWARD -o $VPN_IF -j ACCEPT
iptables -I FORWARD -i br0 -j ACCEPT
iptables -I FORWARD -o br0 -j ACCEPT
iptables -I FORWARD -i $LOCAL_IF -j ACCEPT
iptables -I FORWARD -o $LOCAL_IF -j ACCEPT



```

Por último reiniciamos y ejecutamos el script

```bash
sudo reboot
sudo bash /opt/network/bridge.sh
```

Por último verificamos que aparezca el bridge con

```
sudo brctl show
sudo iptables -L -n -v
```

Debería salir br0 y las dos interfaces para el puente

Ahora, todos los que estan conectados por ethernet tiene que tener la red 192.168.192.XX, la cual es la misma que la del zerotier, luego cualquier cliente que tenga esto, se puede conectar a la red zerotier y acceder a los dispositivos que estan conectados por ethernet.

Verificar los XX

## Creación de servicio

Para que el bridge se ejecute siempre que encienda el sistema se tiene que crear un servicio

```
sudo nano /etc/systemd/system/bridge-start.service
```

```bash
[Unit]
Description=Script de puente de red
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /opt/network/bridge.sh

[Install]
WantedBy=default.target
```

```
sudo systemctl enable bridge-start.service
sudo systemctl start bridge-start.service
```
