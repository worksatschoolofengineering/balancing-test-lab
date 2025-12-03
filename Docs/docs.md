## Documentation

 El laboratorio consta de dos servidores balanceadores de cargar y uno confogurado como maquina cliente el cual va a levantar todo el laboratorio y ejecutará las pruebas de estres y balanceo de carga.

 El laboratorio esta simulado por contenedores como maquinas ubuntu de servidores que exponen un servicio a internet y de una cliente que usando apache benchmark lanza las peticiones.


 ### De que cosnta el laboratorio?

 - Configuracion del laboratorio, maquinas y servidores en general, usando ngnix, y configuracion del archivo de ngnix.conf usando contenedores de docker.

- Descripción para el documento:
    El archivo docker-compose.yml define la infraestructura completa del laboratorio mediante Infrastructure as Code (IaC). Esta configuración establece:

- Servicios definidos:
    backend1 y backend2: Utilizan la imagen oficial nginx:latest y montan volúmenes locales (./backend1 y ./backend2) en la ruta /usr/share/nginx/html del contenedor, permitiendo servir contenido HTML personalizado.

- loadbalancer: 
    También basado en nginx:latest, monta el archivo de configuración personalizado default.conf que contiene las reglas de balanceo. Se mapea el puerto 8080 del host al puerto 80 del contenedor para permitir acceso externo.

- Red definida:
    Se crea una red bridge personalizada llamada labnet que aísla la comunicación entre contenedores y permite la resolución de nombres por hostname (DNS interno de Docker).

Esta arquitectura permite alta disponibilidad y escalabilidad horizontal, ya que se pueden agregar más backends simplemente replicando la configuración.


### Que se vaa  evaluar?

 - configuracion del script que levantará todo el laboratorio.

 - La configuración de red y netwking interno con docker.

 - El archivo principal de configuración de ngnix.

 - La ejecución correcta del script que hace que se ejecuten las pruebas y muestre por consola las metricas y resultados.

 - Ejecución del script que documente paso a paso y explique en cada parte del proceso que es lo que ha sucedido.


### Que se va a Documentar?

📸 Screenshots recomendados para tu informe:

- 1️⃣ curl backend1 mostrando Backend 1
- 2️⃣ curl backend2 mostrando Backend 2
- 3️⃣ Resultado de curl localhost:8080 alternando
- 4️⃣ Navegador mostrando Backend 1
- 5️⃣ Navegador mostrando Backend 2
- 6️⃣ docker ps mostrando contenedores
- 7️⃣ docker stats durante pruebas
- 8️⃣ Pruebas de carga ab -n 1000 -c 10
- 9️⃣ Pruebas de carga ab -n 20000 -c 200 -k

Con eso cumples TODA la evidencia de la entrega.

📸 EL SCRIPT YA HACE TODO AUTOMÁTICO

Cuando termine podrás tomar screenshots de:

- ✔ docker ps
- ✔ docker stats
- ✔ Respuesta alternada del balanceador
- ✔ Pruebas de carga con ab
- ✔ Estructura del laboratorio en ~/lab-docker
- ✔ Configuración generada




### De cuantos scripts requiere? 

1. Un script para levantar todo el laboratorio, los contenedores y la instalción de aapche benchmark.

2. Un script para la ejecución de todos las pruebas y resultados de metricas. Paso a Paso.

3. Un script que documente todo el resultado optenido, y explique en cada paso que ha sucedido.
