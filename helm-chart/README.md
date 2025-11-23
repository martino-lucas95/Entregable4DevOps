# Stock Management Helm Chart

Helm Chart para desplegar el sistema de gestión de stock completo en Kubernetes.

## Componentes

Este chart despliega:

- **Backend API** (NestJS + Prisma)
- **Frontend Web** (React + Vite)
- **PostgreSQL Database** (v16-alpine)

## Inicio Rápido

### Instalación Básica

```bash
# Instalar con valores por defecto
helm install stock-management ./helm-chart

# Instalar en namespace específico
helm install stock-management ./helm-chart --namespace myapp --create-namespace
```

### Instalación para Desarrollo

```bash
helm install stock-management ./helm-chart \
  --values values-dev.yaml \
  --namespace development \
  --create-namespace
```

### Instalación para Producción

```bash
helm install stock-management ./helm-chart \
  --values values-prod.yaml \
  --namespace production \
  --create-namespace \
  --set postgresql.auth.password=SECURE_PASSWORD
```

## Parámetros de Configuración

### Parámetros Globales

| Parámetro | Descripción | Default |
|-----------|-------------|---------|
| `environment` | Entorno (development/production) | `development` |
| `nameOverride` | Override del nombre | `""` |
| `fullnameOverride` | Override del nombre completo | `""` |

### Backend

| Parámetro | Descripción | Default |
|-----------|-------------|---------|
| `backend.replicaCount` | Número de réplicas | `2` |
| `backend.image.repository` | Repositorio de imagen | `entregable4devops-backend` |
| `backend.image.tag` | Tag de imagen | `1.0` |
| `backend.image.pullPolicy` | Pull policy | `IfNotPresent` |
| `backend.service.type` | Tipo de servicio | `ClusterIP` |
| `backend.service.port` | Puerto del servicio | `3000` |
| `backend.resources.limits.cpu` | Límite CPU | `500m` |
| `backend.resources.limits.memory` | Límite memoria | `512Mi` |
| `backend.resources.requests.cpu` | Request CPU | `250m` |
| `backend.resources.requests.memory` | Request memoria | `256Mi` |

### Frontend

| Parámetro | Descripción | Default |
|-----------|-------------|---------|
| `frontend.replicaCount` | Número de réplicas | `2` |
| `frontend.image.repository` | Repositorio de imagen | `entregable4devops-frontend` |
| `frontend.image.tag` | Tag de imagen | `1.0` |
| `frontend.image.pullPolicy` | Pull policy | `IfNotPresent` |
| `frontend.service.type` | Tipo de servicio | `ClusterIP` |
| `frontend.service.port` | Puerto del servicio | `5173` |
| `frontend.apiUrl` | URL del backend | `http://localhost:3000` |
| `frontend.resources.limits.cpu` | Límite CPU | `200m` |
| `frontend.resources.limits.memory` | Límite memoria | `256Mi` |

### PostgreSQL

| Parámetro | Descripción | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Habilitar PostgreSQL | `true` |
| `postgresql.image.repository` | Repositorio de imagen | `postgres` |
| `postgresql.image.tag` | Tag de imagen | `16-alpine` |
| `postgresql.auth.username` | Usuario de BD | `postgres` |
| `postgresql.auth.password` | Contraseña de BD | `postgres` |
| `postgresql.auth.database` | Nombre de BD | `stock` |
| `postgresql.service.port` | Puerto del servicio | `5432` |
| `postgresql.persistence.enabled` | Habilitar persistencia | `true` |
| `postgresql.persistence.size` | Tamaño del volumen | `2Gi` |
| `postgresql.resources.limits.cpu` | Límite CPU | `500m` |
| `postgresql.resources.limits.memory` | Límite memoria | `512Mi` |

### Ingress

| Parámetro | Descripción | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Habilitar Ingress | `false` |
| `ingress.className` | Ingress class | `nginx` |
| `ingress.hosts[0].host` | Hostname | `stock-management.local` |
| `ingress.tls` | Configuración TLS | `[]` |

## Ejemplos de Uso

### Cambiar número de réplicas

```bash
helm upgrade stock-management ./helm-chart \
  --set backend.replicaCount=5 \
  --set frontend.replicaCount=3
```

### Usar imagen desde registry privado

```bash
helm upgrade stock-management ./helm-chart \
  --set backend.image.repository=myregistry.com/backend \
  --set backend.image.tag=v2.0.0 \
  --set backend.image.pullSecrets[0].name=regcred
```

### Habilitar Ingress

```bash
helm upgrade stock-management ./helm-chart \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=myapp.example.com
```

### Deshabilitar PostgreSQL (usar BD externa)

```bash
helm upgrade stock-management ./helm-chart \
  --set postgresql.enabled=false \
  --set backend.env.DATABASE_URL="postgresql://user:pass@external-db:5432/dbname"
```

## Verificación

Después de instalar, verificar:

```bash
# Ver pods
kubectl get pods

# Ver servicios
kubectl get svc

# Ver ingress (si está habilitado)
kubectl get ingress

# Acceder a la aplicación
kubectl port-forward svc/stock-management-frontend 5173:5173
# Abrir http://localhost:5173
```

## Actualización

```bash
# Actualizar chart
helm upgrade stock-management ./helm-chart

# Actualizar con nuevos valores
helm upgrade stock-management ./helm-chart -f new-values.yaml
```

## Desinstalación

```bash
helm uninstall stock-management
```

## Estructura de Archivos

```
helm-chart/
├── Chart.yaml                      # Metadata del chart
├── values.yaml                     # Valores por defecto
├── values-dev.yaml                 # Valores para desarrollo
├── values-prod.yaml                # Valores para producción
└── templates/
    ├── _helpers.tpl                # Template helpers
    ├── configmap.yaml              # ConfigMaps
    ├── secret.yaml                 # Secrets
    ├── pvc.yaml                    # PersistentVolumeClaim
    ├── deployment-backend.yaml     # Backend Deployment
    ├── deployment-frontend.yaml    # Frontend Deployment
    ├── deployment-postgresql.yaml  # PostgreSQL Deployment
    ├── service.yaml                # Services
    └── ingress.yaml                # Ingress
```

## Requisitos

- Kubernetes 1.20+
- Helm 3.0+
- PV provisioner support en cluster (para persistencia)

## Mantenimiento

Ver historial de releases:
```bash
helm history stock-management
```

Hacer rollback:
```bash
helm rollback stock-management [REVISION]
```

## Soporte

Para más información, ver [DEPLOYMENT.md](../DEPLOYMENT.md)
