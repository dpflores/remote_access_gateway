Based on: https://industry40.systems/8

# Remote Access Gateway

Para poder realizar la alternativa de instalación automatizada, necesitas un owasys con la imagen base realizada.

Luego de tener un Owasys con la imagen base, copiar esta carpeta al owasys

```
scp -r remote_access_gateway/ debian@192.168.10.1:/home/debian
```

Ejecutar el script `00_install_zerotier.sh` para que se instale automaticamente zerotier y sus dependencias

Se debe crear una red en `zerotier.com` con una cuenta, considerar que la red debe tener una máscara de `255.255.255.0`.

Una vez creada la red, entrar al dispositivo y ejecutar los scripts `01_setup_zerotier_bridge.sh` y `02_setup_zerotier_bridge.sh` repectivamente.

Seguir las instrucciones de los scripts y leer detalladamente.
