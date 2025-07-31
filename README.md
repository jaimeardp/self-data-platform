# Repositorio de Infraestructura - Plataforma de Datos

Bienvenido al repositorio de la plataforma de datos. Este proyecto de Terraform es el **núcleo** de nuestra infraestructura en Google Cloud. Su responsabilidad es provisionar y gestionar todos los recursos base compartidos que las aplicaciones y los pipelines de datos consumirán.

La filosofía de este repositorio es proporcionar una base segura, consistente y escalable, permitiendo que los equipos de aplicación trabajen de forma autónoma sin preocuparse por la infraestructura subyacente.

## Arquitectura

La gestión de nuestra infraestructura sigue un modelo de **separación de responsabilidades** a través de múltiples repositorios:

1.  **Este Repositorio (Plataforma - `self-data-platform`):**
    * **Qué hace:** Gestiona la infraestructura fundamental y compartida. Es el "sistema operativo" de nuestra nube.
    * **Por qué:** Centraliza el control sobre la seguridad, las redes y los costos. Asegura que todos los componentes base sean consistentes.
    * **Quién lo gestiona:** El equipo de plataforma, DevOps o arquitectos de la nube.

2.  **Repositorios de Aplicación (ej. `self-data-platform-functions`, `self-data-platform-dags`):**
    * **Qué hacen:** Contienen el código de la aplicación (Python, SQL) y el Terraform específico para desplegar *esa* aplicación (ej. una Cloud Function o un conjunto de DAGs).
    * **Por qué:** Otorga autonomía a los equipos de desarrollo. Pueden desplegar y gestionar el ciclo de vida de sus aplicaciones de forma independiente.
    * **Cómo se conectan:** Utilizan un `data source` de Terraform para leer los outputs (como nombres de buckets o cuentas de servicio) de este repositorio de plataforma.

## Recursos Gestionados

Este repositorio provisiona los siguientes recursos clave:

* **Redes (`network.tf`):** Una VPC dedicada para aislar los recursos de la plataforma.
* **Almacenamiento (`gcs.tf`):**
    * Bucket de **Landing Zone**: Para la ingesta de archivos crudos.
    * Bucket de **Raw Zone**: Para almacenar los datos transformados a Parquet.
* **Data Warehouse (`bigquery.tf`):** Datasets de BigQuery para las capas de datos procesados.
* **Orquestación (`composer.tf`):** El entorno de Cloud Composer para los pipelines de Airflow.
* **Identidad y Permisos (`iam.tf`, `cicd.tf`):**
    * Cuentas de servicio dedicadas para las aplicaciones (funciones, Composer).
    * La configuración completa de **Workload Identity Federation** para la integración segura con CI/CD de GitHub.
    * Roles IAM personalizados para seguir el principio de mínimo privilegio.

---

## Configuración para Despliegue Local

Antes de poder ejecutar `terraform apply` desde tu máquina local, necesitas realizar una configuración inicial única.

### 1. Crear el Bucket para el Backend de Terraform

Terraform necesita un bucket en GCS para almacenar su archivo de estado. Este bucket debe ser creado manualmente una sola vez y su nombre debe coincidir con el definido en `backend.tf` (`self-tfstate-bkt`).

```bash
# Reemplaza 'tu-gcp-project-id-aqui' con tu Project ID
gcloud storage buckets create gs://self-tfstate-bkt --project=tu-gcp-project-id-aqui --location=us-central1 --uniform-bucket-level-access
```

### 2. Permisos de Usuario Local

Tu cuenta de usuario de Google Cloud (con la que te autenticas a través de `gcloud`) necesita tener permisos elevados para gestionar la infraestructura de la plataforma. Para un entorno de desarrollo, los siguientes roles son un buen punto de partida:

* `Project Owner` o `Editor`
* `Project IAM Admin` (`roles/resourcemanager.projectIamAdmin`)

### 3. Archivo de Variables Locales (`terraform.tfvars`)

Crea un archivo llamado `terraform.tfvars` en la raíz de este repositorio. Este archivo te permitirá definir los nombres de los repositorios de aplicación que se conectarán a esta plataforma. **No subas este archivo a Git.**

```terraform
# terraform.tfvars

gcp_project_id = "tu-gcp-project-id-aqui"
gcp_region     = "us-central1"

# Reemplaza con el nombre de tu repositorio de funciones en formato "owner/repo"
github_functions_repository_name = "tu-usuario-o-org/self-data-platform-functions"

# Reemplaza con el nombre de tu repositorio de DAGs en formato "owner/repo"
github_dags_repository_name = "tu-usuario-o-org/self-data-platform-dags"
```

---

### Despliegue

Una vez completada la configuración local, el despliegue es estándar.

1.  **Autenticación:**
    ```bash
    gcloud auth application-default login
    ```
2.  **Inicializar Terraform:**
    ```bash
    terraform init
    ```
3.  **Planificar y Aplicar:**
    ```bash
    terraform plan -var-file="terraform.tfvars"
    terraform apply -var-file="terraform.tfvars"
    ```

## Outputs de la Plataforma

Después de un `apply` exitoso, este repositorio generará varios **outputs**. Estos outputs son los puntos de conexión para los repositorios de aplicación. Por ejemplo, el repositorio de funciones leerá el output `function_service_account_email` para saber qué cuenta de servicio utilizar.
