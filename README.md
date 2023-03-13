# Ejercicio Practico Equifax
## _Teodoro Hochfärber_


## Supuestos

Se presupone lo siguiente:

- Que existe un proyecto creado en GCP con una cuenta de billing activa
- Que existe una service account con los permisos necesarios para el manejo de los recursos, con una llave creada y descargada en el computador en el cual se correra terraform
- Que el computador tiene instalado terraform, docker y la CLI de google
- Que en la CLI de google esta autenticado un usuario (gcloud auth login) que tenga permisos suficientes para manejar cluster GKE
- Que las siguientes APIs estan activadas en el proyecto google:
    - Cloud Monitoring API
    - Compute Engine API
    - Cloud Logging API
    - Cloud Autoscaling API	
    - Artifact Registry API
    - sqladmin API (prod)
    - Kubernetes Engine API
    - Identity and Access Management (IAM) API	


## Consideraciones

Puesto que este sistema no entrara nunca en produccion, y es solamente un ejercicio, se han tomado ciertos atajos. Tener en cuenta que estos no son detalles que se pasaron por alto, sino que fueron considerados y se decidio concientemente realizarlo asi.

- Comunicacion con la base de datos a traves de IP publica
- Cluster K8 no privado
- Utilizacion de namespaces y usuarios por defecto en cluster K8
- No uso de modulos para mantener las configuraciones limpias
- Dejar la aplicacion demo en modo de desarrollo, en lugar de modo produccion.
- Uso de backend local
- Uso de autenticacion ssh para el bastion, en lugar de implementaciones mas seguras como IAP
- Se expone la app sin SSL
- La llave secreta de la app, utilizada para firmar las cookies, esta directamente en la configuracion y no en un vault.

Todas estos atajos no van en contra de lo pedido en el ejercicio, pero se quiere dejar en claro que no se consideran buenas practicas.

El unico detalle que no se implemento, y que aparece en el diagrama de lo pedido es Cloud DNS, puesto que en la hoja del ejercicio no se explica que se requiere, y no se recibio respuesta cuando se pidio aclaracion.

## Generacion de imagen de la aplicacion demo

La applicacion demo es una simple aplicacion rails, que permite hacer login/logout, y crear/ver/editar comentarios. Todo esto conectado a una base de datos Postgres 15.

Para generar y subir la imagen al Google Container Registry, ejecutar el script build_image.sh. El script recibe un solo parametro que es el id del projecto al cual se subira la imagen.

```./build_image.sh <project_id>```

El script automaticamente generara las credenciales y configuraciones necesarias en docker para poder subir la imagen. Recordar que el debe haber un usuario autenticado en la cli de google para que esto funcione.

## Terraform

Para el uso de la configuracion de terraform, se debe obtener primero una llave para la cuenta de servicio que se va a utilizar. Se debe tambien generar una llave ssh, la cual sera utilizada para acceder al bastion. Como tercer paso, se debe rellenar el archivo terraform.tfvars el cual contiene lo siguiente:
```
project_id = # ID del projecto google
region     = "us-central1" # Region del projecto
zone       = "us-central1-c" # Zona del projecto
sql_user   = "equifax" # Nombre de usuario que utilizara la app para conectarse a la Base de datos
sql_pass   =  # Contraseña que utilizara la app para conectarse a la Base de datos
sql_root_pass   = # Contraseña Inicial de la cuenta postgres
sql_db_name   = "demo_db" # Nombre de la base de datos que utilizara la APP en la base de datos
app_password = # Contraseña para la primera cuenta de usuario de la Aplicacion. el usuario es "equifax@demo.cl"
bastion_user = # Nombre de usuario que se utilizara en el bastion
bastion_ssh_location = # Ubicacion de la llave publica ssh que se agregara al bastion
service_account_key_location = # Ubicacion de la llave de la cuenta de servicio google a utlizar.
```

Se deben rellenar los campos vacios para que la configuracion funcione. Se han dejado algunos campos prepoblados puesto que no son campos sensibles, pero si se quiere se pueden cambiar sin problemas.

## Applicacion en funcionamiento

Se puede visitar la applicacion funcionando en la siguiente URL http://34.134.217.52/ el usuario es "equifax@demo.cl". La contraseña sera enviada por otro canal.


