echo "-------------------------------------------------------------"
echo "Configurando Zerotier"
echo "-------------------------------------------------------------"

# Solicitar el networi ID de zerotier
read -p "Introduzca el network ID de zerotier: " ZEROTIER_NETWORK

echo "-------------------------------------------------------------"
echo "Solicitando acceso a la red ${ZEROTIER_NETWORK}"
echo "-------------------------------------------------------------"

sudo zerotier-cli join ${ZEROTIER_NETWORK}

echo "-------------------------------------------------------------"
echo Conectando ${ZEROTIER_NETWORK}, solicite al administrador que le permita acceder

echo "In case the admin accepted but dont get IP, execute this command: sudo systemctl restart zerotier-one.service"

echo "-------------------------------------------------------------"
echo "EL ADMINISTRADOR DEBE HABILITAR LOS BOXES BRIDGING Y DO NOT AUTOASIGN IP EN ZEROTIER"
echo "-------------------------------------------------------------"


echo "------------------------------------------------------------------------------------"
echo "Zerotier parte 1 configurado, si se tiene la IP asignada, continue con la parte 2"
echo "------------------------------------------------------------------------------------"



