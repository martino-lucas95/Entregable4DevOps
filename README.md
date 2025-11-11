# API de Gestión de Stock

API minimalista para gestionar movimientos de stock, permitiendo registrar entradas y salidas de productos y calcular en tiempo real el inventario disponible.

## Características

- ✅ Creación y actualización de productos
- ✅ Registro de movimientos de stock (entradas y salidas)
- ✅ Cálculo de stock en tiempo real
- ✅ Base de datos PostgreSQL con Prisma ORM
- ✅ Documentación Swagger
- ✅ Docker y Docker Compose

## Requisitos Previos

- Docker
- Docker Compose

## Instalación y Ejecución

### Paso 1: Clonar el repositorio (si aplica)

```bash
git clone <url-del-repositorio>
cd Entregable4DevOps
```

### Paso 2: Construir y levantar los contenedores

```bash
docker-compose up --build
```

Este comando:
- Construye la imagen de la API
- Levanta el contenedor de PostgreSQL
- Espera a que la base de datos esté lista (healthcheck)
- Ejecuta las migraciones de Prisma automáticamente al iniciar el contenedor
- Inicia la API

**Nota**: El Dockerfile ejecuta las migraciones automáticamente antes de iniciar la aplicación usando el comando:
```bash
prisma migrate deploy --schema=./prisma/schema.prisma || prisma db push --schema=./prisma/schema.prisma --accept-data-loss
```

Si no hay migraciones creadas, usa `prisma db push` para sincronizar el schema directamente.

### Paso 3: Verificar que todo esté funcionando

La API estará disponible en: `http://localhost:3000`

La documentación Swagger estará disponible en: `http://localhost:3000/api`

### Paso 4: Probar la API

Puedes usar la interfaz de Swagger en `http://localhost:3000/api` para probar todos los endpoints, o usar curl:

#### Crear un producto:
```bash
curl -X POST http://localhost:3000/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Producto Ejemplo",
    "cost": 10.5,
    "price": 15.99,
    "barcode": "1234567890123"
  }'
```

#### Crear un movimiento de entrada:
```bash
curl -X POST http://localhost:3000/movements \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 1,
    "type": "IN",
    "quantity": 100
  }'
```

#### Consultar stock:
```bash
curl http://localhost:3000/stock
```

## Endpoints Disponibles

### Productos
- `GET /products` - Obtener todos los productos
- `GET /products/:id` - Obtener un producto por ID
- `POST /products` - Crear un nuevo producto
- `PATCH /products/:id` - Actualizar un producto
- `DELETE /products/:id` - Eliminar un producto

### Movimientos
- `GET /movements` - Obtener todos los movimientos
- `GET /movements/:id` - Obtener un movimiento por ID
- `POST /movements` - Crear un nuevo movimiento (IN o OUT)

### Stock
- `GET /stock` - Obtener el stock de todos los productos
- `GET /stock/:productId` - Obtener el stock de un producto específico

## Detener los contenedores

```bash
docker-compose down
```

Para eliminar también los volúmenes (incluyendo la base de datos):

```bash
docker-compose down -v
```

## Estructura del Proyecto

```
.
├── docker-compose.yml          # Configuración de Docker Compose
├── Dockerfile                  # Imagen Docker de la API (incluye migraciones)
├── prisma/
│   └── schema.prisma          # Schema de la base de datos
└── entregable4-dev-ops/
    └── src/
        ├── products/          # Módulo de productos
        ├── movements/         # Módulo de movimientos
        ├── stock/             # Módulo de stock
        └── prisma/            # Servicio de Prisma
```

## Tecnologías Utilizadas

- **NestJS** - Framework de Node.js
- **PostgreSQL** - Base de datos
- **Prisma** - ORM
- **Swagger** - Documentación de API
- **Docker** - Contenedorización
- **Docker Compose** - Orquestación de contenedores

## Notas

- La base de datos se inicializa automáticamente al levantar los contenedores
- Las migraciones de Prisma se ejecutan automáticamente en el `CMD` del Dockerfile antes de iniciar la API
- Docker Compose espera a que la base de datos esté lista (healthcheck) antes de iniciar el contenedor de la API
- Los datos persisten en un volumen de Docker llamado `postgres_data`
- El stock se calcula en tiempo real basándose en los movimientos (entradas - salidas)
- Si necesitas ejecutar migraciones manualmente, puedes usar:
  ```bash
  docker-compose exec api npx prisma migrate deploy --schema=./prisma/schema.prisma
  ```
