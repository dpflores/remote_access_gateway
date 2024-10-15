Based on: https://industry40.systems/8

# Remote Access Gateway

Para crear la imagen primero enviar los scripts al owasys que tenga imagen base del proveedor

```
scp -r remote_access_gateway/ debian@192.168.10.1:/home/debian
```

ejecutar los scripts ubicados en la carpeta `installation_scripts` en el owasys.

Si ya tienes la imagen, entrar al dispositivo y ejecutar los scripts `01_setup_zerotier_bridge.sh` y `02_setup_zerotier_bridge.sh`.
