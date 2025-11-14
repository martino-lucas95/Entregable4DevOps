# Sistema de Gestión de Stock

Sistema completo para gestionar movimientos de stock, permitiendo registrar entradas y salidas de productos y calcular en tiempo real el inventario disponible. Incluye una API REST con NestJS y un frontend con React.

## Características

- ✅ Creación y actualización de productos
- ✅ Registro de movimientos de stock (entradas y salidas)
- ✅ Cálculo de stock en tiempo real
- ✅ Base de datos PostgreSQL con Prisma ORM
- ✅ API REST con documentación Swagger
- ✅ Frontend React con interfaz moderna
- ✅ Docker y Docker Compose para fácil despliegue

## Requisitos Previos

- Docker
- Docker Compose

## Instalación y Ejecución

### Paso 1: Clonar el repositorio (si aplica)

```bash
git clone <url-del-repositorio>
cd Entregable4DevOps
```

### Paso 2: Construir las imágenes Docker

```bash
docker compose build
```

Este comando construye las imágenes para:
- **Base de datos**: PostgreSQL 16
- **API**: Backend NestJS con Prisma
- **Frontend**: Aplicación React con Vite

### Paso 3: Levantar todos los servicios

```bash
docker compose up -d
```

Este comando levanta todos los contenedores en segundo plano:
- **PostgreSQL** en el puerto `5432`
- **API Backend** en el puerto `3000`
- **Frontend** en el puerto `5173`

**Nota**: El Dockerfile de la API ejecuta las migraciones automáticamente antes de iniciar la aplicación usando el comando:
```bash
prisma migrate deploy --schema=./prisma/schema.prisma || prisma db push --schema=./prisma/schema.prisma --accept-data-loss
```

Si no hay migraciones creadas, usa `prisma db push` para sincronizar el schema directamente.

### Paso 4: Verificar que todo esté funcionando

Puedes verificar el estado de los contenedores con:

```bash
docker compose ps
```

Deberías ver tres contenedores corriendo:
- `stock_db` (PostgreSQL)
- `stock_api` (Backend NestJS)
- `stock_frontend` (Frontend React)

### Paso 5: Acceder a los servicios

Una vez que todos los contenedores estén corriendo:

- **Frontend**: `http://localhost:5173` - Interfaz web para gestionar productos y movimientos
- **API Backend**: `http://localhost:3000` - API REST
- **Documentación Swagger**: `http://localhost:3000/api` - Documentación interactiva de la API
- **Base de datos**: `localhost:5432` (usuario: `postgres`, contraseña: `postgres`, base: `stock`)

### Comandos útiles

```bash
# Ver logs de todos los servicios
docker compose logs

# Ver logs de un servicio específico
docker compose logs frontend
docker compose logs api
docker compose logs db

# Ver logs en tiempo real
docker compose logs -f

# Detener todos los servicios
docker compose down

# Detener y eliminar volúmenes (incluyendo la base de datos)
docker compose down -v

# Reconstruir solo un servicio específico
docker compose build frontend
docker compose up -d frontend
```

### Paso 6: Probar la API

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

## Estructura del Proyecto

```
.
├── docker-compose.yml          # Configuración de Docker Compose (db, api, frontend)
├── backend/                   # Backend (NestJS)
│   ├── Dockerfile             # Imagen Docker de la API (incluye migraciones)
│   ├── prisma/
│   │   └── schema.prisma      # Schema de la base de datos
│   └── src/
│       ├── products/          # Módulo de productos
│       ├── movements/         # Módulo de movimientos
│       ├── stock/             # Módulo de stock
│       └── prisma/            # Servicio de Prisma
├── frontend/                  # Frontend (React + Vite)
│   ├── Dockerfile             # Imagen Docker del frontend
│   ├── src/
│   │   ├── components/        # Componentes React
│   │   ├── App.tsx            # Componente principal
│   │   └── api.ts             # Cliente API para comunicarse con el backend
│   └── package.json
└── reports/                   # Reportes de seguridad
    └── security/
        ├── backend/           # Reportes de seguridad del backend
        │   ├── backend_dependencies.md
        │   ├── backend_dockerfile.md
        │   └── backend_trivy.md
        ├── db/                # Reportes de seguridad de la base de datos
        │   └── postgres_trivy.md
        └── frontend/          # Reportes de seguridad del frontend
            ├── frontend_dependencies.md
            ├── frontend_dockerfile.md
            └── frontend_trivy.md
```

## Tecnologías Utilizadas

### Backend
- **NestJS** - Framework de Node.js
- **PostgreSQL** - Base de datos relacional
- **Prisma** - ORM para Node.js
- **Swagger** - Documentación de API

### Frontend
- **React** - Biblioteca de JavaScript para interfaces de usuario
- **TypeScript** - Superset tipado de JavaScript
- **Vite** - Build tool y servidor de desarrollo
- **Tailwind CSS** - Framework CSS utility-first

### DevOps
- **Docker**
- **Docker Compose**

## Notas Importantes

- **Base de datos**: Se inicializa automáticamente al levantar los contenedores
- **Migraciones**: Las migraciones de Prisma se ejecutan automáticamente en el `CMD` del Dockerfile antes de iniciar la API
- **Dependencias**: Docker Compose espera a que la base de datos esté lista (healthcheck) antes de iniciar el contenedor de la API
- **Persistencia**: Los datos persisten en un volumen de Docker llamado `postgres_data`
- **Cálculo de stock**: El stock se calcula en tiempo real basándose en los movimientos (entradas - salidas)
- **CORS**: El backend tiene CORS habilitado para permitir peticiones del frontend
- **Variables de entorno**: El frontend usa `VITE_API_URL` (por defecto `http://localhost:3000`) para conectarse al backend

### Ejecutar migraciones manualmente

Si necesitas ejecutar migraciones manualmente:

```bash
docker compose exec api npx prisma migrate deploy --schema=./prisma/schema.prisma
```

### Solución de problemas

Si el frontend muestra datos antiguos o no se conecta al backend:

1. Verifica que todos los contenedores estén corriendo: `docker compose ps`
2. Reconstruye el frontend: `docker compose build frontend && docker compose up -d frontend`
3. Revisa los logs: `docker compose logs frontend` y `docker compose logs api`
4. Abre la consola del navegador (F12) para ver errores de conexión
5. Verifica que la API esté respondiendo: `curl http://localhost:3000/products`
