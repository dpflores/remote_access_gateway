Based on: https://industry40.systems/8

# Remote Access Gateway

Instalar dependencias

```
sudo apt-get update -y
sudo apt-get install bridge-utils -y
sudo apt-get install netplan.io -y
sudo apt-get install curl -y

```

Instalar zerotier

```
curl -k https://install.zerotier.com | sudo bash

```

Conectar el host al network de zerotier

```
sudo zerotier-cli join (id de la red)
```

Desde el zerotier se tiene que aceptar y marcar los dos checkboxes de configuración de bridging y auto assign IP

Por defecto, luego de que el host logre conectarse a la VPN, Zerotier creará dos archivos de configuración en la ruta `/var/lib/zerotier-one/networks.d` Tambien se tiene que acceder al archivo `/var/lib/zerotier-one/network.d/(id autogenerado por zerotier).local.conf`

```
nano /var/lib/zerotier-one/networks.d/(id autogenerado por zerotier).local.conf
```

y modificar el contenido a 0 (desactivar todas las opciones)

```
allowManaged=0
allowGlobal=0
allowDefault=0
allowDNS=0
```

Primera configuración del bridge. Para este paso es necesario determinar el nombre de la interfaz ethernet (apoyarse de `ip a` o `ifconfig`), el prefijo de la red que se tiene en zerotier además de la IP que le asignó a la interfaz de zerotier.
Crear el archivo `/etc/netplan/50-cloud-init.yaml` con el siguiente contenido (leer comentarios en el código para mayor información)

```yaml
# This file is generated from information provided by
# the datasource.  Changes to it will not persist across an instance.
# To disable cloud-init's network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
  version: 2
  ethernets:
    (ethernet interface):
      addresses: []
      dhcp4: false
      optional: true
  bridges:
    br0:
      # Colocar aquí la ip asignada a la interfaz de zerotier seguida de la máscara de red Ej. 192.168.192.5/24
      addresses: [(ip address)]
      dhcp4: false
      interfaces:
        - (ethernet interface)
      # Colocar aquí la IP del gateway de la red Ej. 192.168.192.1
      gateway4: (ip gateway)
      nameservers:
        addresses: [8.8.8.8]
```

Para proceder a la creación del bridge, ejecutar:

```
sudo netplan apply
```

Luego de aplicar el netplan, la IP de la interfaz ethernet se modificará por lo tanto se debe acceeder a través de la IP que asignó zerotier
Es necesario crear un script para continuar con la configuración del bridge en la ruta `/opt/network`

```
sudo mkdir /opt/network
sudo nano /opt/network/bridge.sh
```

Es necesario nuevamente, el nombre asignado a la interfaz ethernet, el nombre de la interfaz creada por zerotier y el nombre de una interfaz con acceso a internet para permitir la conexión con los servidores de zerotier. Los dispositivos owasys, luego de haberse configurado la conexión celular, cuentan con una interfaz llamada ppp0 que es la que se utiliza en el script.

```bash
#!/bin/bash
PATH="/bin:/sbin:/usr/bin:/usr/sbin"
export PATH

LOCAL_IF="(ethernet interface)"
# No confundir con el nombre de la red en el panel de zerotier
VPN_IF="(zerotier interface)"
# Interfaz cin acceso a internet Ej. ppp0
INTER_IF="(nat interface)"

# IP anteriormente asignada por zerotier al host, la misma que se configuró en un inicio en el bridge Ej. 192.168.192.5/24
BR_IP="(ip address)"
# IP de la red de zerotier seguida del prefijo Ej. 192.168.192.0/24
BR_NET="(ip address)"

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

Por último reiniciar el sistema y ejecutar el script

```bash
sudo reboot
sudo bash /opt/network/bridge.sh
```

Por último se verifica que aparezca el bridge con

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

Es necesario activar e iniciar el servicio

```
sudo systemctl enable bridge-start.service
sudo systemctl start bridge-start.service
```
