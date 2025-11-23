# Guía de Despliegue con Kubernetes y Helm

## Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Estructura del Helm Chart](#estructura-del-helm-chart)
3. [Configuración de Valores](#configuración-de-valores)
4. [Despliegue con Helm](#despliegue-con-helm)
5. [Verificación del Despliegue](#verificación-del-despliegue)
6. [Pipeline de Jenkins](#pipeline-de-jenkins)
7. [Comandos Útiles](#comandos-útiles)
8. [Troubleshooting](#troubleshooting)

---

## Requisitos Previos

### Software Necesario

```bash
# Kubernetes cluster (Minikube, Kind, EKS, GKE, AKS, etc.)
kubectl version --client

# Helm 3.x
helm version

# Docker
docker --version

# Opcional: Jenkins
java -version
```

### Configuración Inicial

1. **Cluster de Kubernetes activo:**
```bash
# Verificar conexión al cluster
kubectl cluster-info
kubectl get nodes
```

2. **Helm instalado:**
```bash
# Instalar Helm (si no está instalado)
# Windows (Chocolatey)
choco install kubernetes-helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# macOS
brew install helm
```

3. **Imágenes Docker construidas:**
```bash
# Construir imágenes localmente
docker-compose build

# O usar las imágenes ya construidas
docker images | grep entregable4devops
```

---

## Estructura del Helm Chart

```
helm-chart/
├── Chart.yaml                      # Metadata del chart
├── values.yaml                     # Valores por defecto
├── values-dev.yaml                 # Valores para desarrollo
├── values-prod.yaml                # Valores para producción
└── templates/
    ├── _helpers.tpl                # Funciones helper
    ├── configmap.yaml              # ConfigMaps para configuración
    ├── secret.yaml                 # Secrets para datos sensibles
    ├── pvc.yaml                    # PersistentVolumeClaim para PostgreSQL
    ├── deployment-backend.yaml     # Deployment del backend
    ├── deployment-frontend.yaml    # Deployment del frontend
    ├── deployment-postgresql.yaml  # Deployment de PostgreSQL
    ├── service.yaml                # Services para todos los componentes
    └── ingress.yaml                # Ingress (opcional)
```

---

## Configuración de Valores

### Archivo `values.yaml` (Valores por Defecto)

Parámetros configurables principales:

| Parámetro | Descripción | Valor por Defecto |
|-----------|-------------|-------------------|
| `environment` | Entorno de ejecución | `development` |
| `backend.replicaCount` | Número de réplicas del backend | `2` |
| `backend.image.repository` | Repositorio de imagen backend | `entregable4devops-backend` |
| `backend.image.tag` | Tag de la imagen backend | `1.0` |
| `backend.service.port` | Puerto del servicio backend | `3000` |
| `backend.resources.limits.cpu` | Límite CPU backend | `500m` |
| `backend.resources.limits.memory` | Límite memoria backend | `512Mi` |
| `frontend.replicaCount` | Número de réplicas del frontend | `2` |
| `frontend.image.repository` | Repositorio de imagen frontend | `entregable4devops-frontend` |
| `frontend.image.tag` | Tag de la imagen frontend | `1.0` |
| `frontend.service.port` | Puerto del servicio frontend | `5173` |
| `postgresql.enabled` | Habilitar PostgreSQL | `true` |
| `postgresql.auth.username` | Usuario de PostgreSQL | `postgres` |
| `postgresql.auth.password` | Contraseña de PostgreSQL | `postgres` |
| `postgresql.persistence.size` | Tamaño del volumen | `2Gi` |
| `ingress.enabled` | Habilitar Ingress | `false` |

### Valores por Entorno

**Desarrollo (`values-dev.yaml`):**
- 1 réplica por servicio
- NodePort para acceso directo
- Sin persistencia en BD (emptyDir)
- Recursos mínimos

**Producción (`values-prod.yaml`):**
- 3 réplicas por servicio
- ClusterIP + Ingress
- Persistencia habilitada (10Gi)
- Recursos optimizados
- TLS/SSL habilitado

---

## Despliegue con Helm

### Opción 1: Despliegue en Desarrollo

```bash
# Navegar al directorio del proyecto
cd Entregable4DevOps-main

# Instalar el chart con valores de desarrollo
helm install stock-management ./helm-chart \
  --values ./helm-chart/values-dev.yaml \
  --namespace development \
  --create-namespace

# Verificar el despliegue
kubectl get all -n development
```

### Opción 2: Despliegue en Producción

```bash
# Instalar el chart con valores de producción
helm install stock-management ./helm-chart \
  --values ./helm-chart/values-prod.yaml \
  --namespace production \
  --create-namespace \
  --set postgresql.auth.password=SECURE_PASSWORD_HERE

# Verificar el despliegue
kubectl get all -n production
```

### Opción 3: Despliegue Personalizado

```bash
# Instalar con valores personalizados inline
helm install stock-management ./helm-chart \
  --set backend.replicaCount=3 \
  --set backend.image.tag=1.0.1 \
  --set frontend.image.tag=1.0.1 \
  --set postgresql.auth.password=MySecurePassword123

# O usar un archivo de valores personalizado
helm install stock-management ./helm-chart \
  -f ./helm-chart/values-dev.yaml \
  -f ./my-custom-values.yaml
```

### Actualizar un Despliegue Existente

```bash
# Actualizar el release
helm upgrade stock-management ./helm-chart \
  --values ./helm-chart/values-dev.yaml \
  --set backend.image.tag=1.1.0

# Actualizar con recreación de pods
helm upgrade stock-management ./helm-chart \
  --values ./helm-chart/values-dev.yaml \
  --force \
  --recreate-pods
```

### Rollback

```bash
# Ver historial de releases
helm history stock-management

# Hacer rollback a versión anterior
helm rollback stock-management

# Rollback a versión específica
helm rollback stock-management 2
```

---

## Verificación del Despliegue

### 1. Verificar Pods

```bash
# Ver todos los pods
kubectl get pods -n development

# Ver pods con labels
kubectl get pods -l app.kubernetes.io/instance=stock-management -n development

# Ver logs de un pod
kubectl logs -f <pod-name> -n development

# Ver logs del backend
kubectl logs -f -l app.kubernetes.io/component=backend -n development
```

Salida esperada:
```
NAME                                           READY   STATUS    RESTARTS   AGE
stock-management-backend-xxxxxxxxx-xxxxx       1/1     Running   0          2m
stock-management-frontend-xxxxxxxxx-xxxxx      1/1     Running   0          2m
stock-management-postgresql-xxxxxxxxx-xxxxx    1/1     Running   0          2m
```

### 2. Verificar Services

```bash
# Ver servicios
kubectl get svc -n development

# Describir servicio backend
kubectl describe svc stock-management-backend -n development
```

### 3. Verificar ConfigMaps y Secrets

```bash
# Ver ConfigMaps
kubectl get configmap -n development

# Ver contenido de ConfigMap
kubectl describe configmap stock-management-backend-config -n development

# Ver Secrets (valores codificados)
kubectl get secrets -n development
```

### 4. Acceder a la Aplicación

**Desarrollo (NodePort):**
```bash
# Obtener el NodePort del frontend
kubectl get svc stock-management-frontend -n development

# Acceder via NodePort
# http://localhost:30002 (o IP del nodo)

# Si usas Minikube
minikube service stock-management-frontend -n development
```

**Producción (Ingress):**
```bash
# Ver el Ingress
kubectl get ingress -n production

# Acceder via dominio configurado
# https://stock-management.example.com
```

### 5. Port Forward (Para testing local)

```bash
# Forward backend port
kubectl port-forward svc/stock-management-backend 3000:3000 -n development

# Forward frontend port
kubectl port-forward svc/stock-management-frontend 5173:5173 -n development

# Forward PostgreSQL port
kubectl port-forward svc/stock-management-postgresql 5432:5432 -n development
```

Luego acceder:
- Backend: http://localhost:3000
- Frontend: http://localhost:5173
- PostgreSQL: localhost:5432

### 6. Health Checks

```bash
# Verificar liveness y readiness probes
kubectl describe pod <pod-name> -n development | grep -A 5 "Liveness\|Readiness"

# Test endpoint del backend
kubectl exec -it <backend-pod-name> -n development -- curl http://localhost:3000
```

---

## Pipeline de Jenkins

### Configuración de Jenkins

#### 1. Credenciales Necesarias

Configurar en Jenkins → Manage Credentials:

| ID | Tipo | Descripción |
|----|------|-------------|
| `docker-registry-url` | Secret text | URL del registry Docker |
| `docker-credentials` | Username/Password | Credenciales Docker registry |
| `kubeconfig` | Secret file | Archivo kubeconfig para Kubernetes |
| `snyk-token` | Secret text | Token de autenticación de Snyk |

#### 2. Plugins Requeridos

```
- Pipeline
- Docker Pipeline
- Kubernetes CLI
- Git
- Snyk Security Scanner
- JUnit
- HTML Publisher
```

#### 3. Crear Pipeline Job

1. New Item → Pipeline
2. Pipeline → Definition: Pipeline script from SCM
3. SCM: Git
4. Repository URL: [tu-repositorio]
5. Script Path: Jenkinsfile

### Etapas del Pipeline

El pipeline incluye las siguientes etapas:

1. **Checkout** - Clonación del repositorio
2. **Static Code Analysis** - Análisis con Semgrep
3. **Dependency Vulnerability Scan** - Escaneo con Snyk
4. **Build and Test Backend** - Construcción y tests del backend
5. **Build and Test Frontend** - Construcción y tests del frontend
6. **Build Docker Images** - Construcción de imágenes Docker
7. **Scan Docker Images** - Escaneo de imágenes con Trivy
8. **Push Docker Images** - Publicación a registry
9. **Deploy to Kubernetes** - Despliegue con Helm
10. **Verify Deployment** - Verificación del despliegue

### Ejecutar Pipeline

```bash
# Trigger manual desde Jenkins UI
# O trigger automático con webhook de Git

# Ver logs en tiempo real
# Jenkins → [Job Name] → Build #X → Console Output
```

### Política de Seguridad

El pipeline **se detendrá** si:
- Se encuentran vulnerabilidades críticas en dependencias (Snyk)
- Se encuentran issues críticos en análisis estático (Semgrep)
- Los tests fallan (si no se usa `SKIP_TESTS`)
- Las imágenes Docker tienen vulnerabilidades críticas (Trivy)

---

## Comandos Útiles

### Helm

```bash
# Listar releases
helm list -A

# Ver valores de un release
helm get values stock-management -n development

# Ver manifest completo generado
helm get manifest stock-management -n development

# Template sin instalar (dry-run)
helm template stock-management ./helm-chart \
  --values ./helm-chart/values-dev.yaml

# Validar chart
helm lint ./helm-chart

# Desinstalar release
helm uninstall stock-management -n development
```

### Kubectl

```bash
# Ver eventos del namespace
kubectl get events -n development --sort-by='.lastTimestamp'

# Ejecutar comando en pod
kubectl exec -it <pod-name> -n development -- /bin/sh

# Ver recursos consumidos
kubectl top pods -n development
kubectl top nodes

# Escalar deployment
kubectl scale deployment stock-management-backend --replicas=5 -n development

# Ver configuración actual
kubectl get deployment stock-management-backend -o yaml -n development
```

### Debugging

```bash
# Ver logs de todos los pods de un deployment
kubectl logs -f deployment/stock-management-backend -n development

# Ver logs anteriores (si el pod crasheó)
kubectl logs <pod-name> --previous -n development

# Describir pod para ver eventos
kubectl describe pod <pod-name> -n development

# Ver logs en tiempo real de múltiples pods
kubectl logs -f -l app.kubernetes.io/component=backend -n development --max-log-requests=10
```

---

## Troubleshooting

### Problema: Pods en estado CrashLoopBackOff

```bash
# Ver logs del pod
kubectl logs <pod-name> -n development

# Ver eventos
kubectl describe pod <pod-name> -n development

# Soluciones comunes:
# 1. Verificar que la base de datos esté lista
kubectl get pods -l app.kubernetes.io/component=database -n development

# 2. Verificar configuración
kubectl get configmap stock-management-backend-config -o yaml -n development

# 3. Verificar secrets
kubectl get secret stock-management-backend-secret -o yaml -n development
```

### Problema: Backend no puede conectarse a PostgreSQL

```bash
# Verificar que PostgreSQL esté corriendo
kubectl get pods -l app.kubernetes.io/component=database -n development

# Verificar servicio de PostgreSQL
kubectl get svc stock-management-postgresql -n development

# Verificar DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup stock-management-postgresql

# Verificar DATABASE_URL
kubectl exec <backend-pod> -n development -- env | grep DATABASE_URL
```

### Problema: Imágenes no se pueden descargar

```bash
# Verificar que las imágenes existan localmente
docker images | grep entregable4devops

# Si usas Minikube, cargar imágenes al cache de Minikube
minikube image load entregable4devops-backend:1.0
minikube image load entregable4devops-frontend:1.0

# O configurar imagePullPolicy
# En values.yaml: image.pullPolicy: Never (solo para desarrollo)
```

### Problema: Servicios no son accesibles

```bash
# Verificar endpoints
kubectl get endpoints -n development

# Verificar que los pods estén listos
kubectl get pods -n development

# Para NodePort, obtener URL
minikube service stock-management-frontend -n development --url

# Para ClusterIP, usar port-forward
kubectl port-forward svc/stock-management-frontend 5173:5173 -n development
```

### Problema: Helm upgrade falla

```bash
# Ver el error detallado
helm upgrade stock-management ./helm-chart --values ./helm-chart/values-dev.yaml --debug

# Hacer rollback
helm rollback stock-management

# Desinstalar y reinstalar
helm uninstall stock-management -n development
helm install stock-management ./helm-chart --values ./helm-chart/values-dev.yaml -n development
```

---

## Mejores Prácticas

### 1. Gestión de Secrets

**NO** guardar contraseñas en values.yaml. Usar:

```bash
# Opción 1: --set en línea de comandos
helm install stock-management ./helm-chart \
  --set postgresql.auth.password=SecurePassword123

# Opción 2: Archivo de secrets (no versionado)
# secrets.yaml (añadir a .gitignore)
postgresql:
  auth:
    password: SecurePassword123

helm install stock-management ./helm-chart \
  -f values-prod.yaml \
  -f secrets.yaml

# Opción 3: Usar Kubernetes Secrets externos
# O herramientas como Sealed Secrets, Vault, etc.
```

### 2. Versionado de Imágenes

```bash
# NUNCA usar :latest en producción
# Usar tags específicos
helm install stock-management ./helm-chart \
  --set backend.image.tag=1.0.5 \
  --set frontend.image.tag=1.0.5
```

### 3. Monitoreo del Despliegue

```bash
# Siempre usar --wait para esperar que los pods estén listos
helm upgrade stock-management ./helm-chart --wait --timeout 5m

# Verificar después del deploy
kubectl rollout status deployment/stock-management-backend -n development
```

### 4. Backups

```bash
# Backup de la base de datos PostgreSQL
kubectl exec stock-management-postgresql-xxx -n production -- \
  pg_dump -U postgres stock_prod > backup.sql

# Restaurar
kubectl exec -i stock-management-postgresql-xxx -n production -- \
  psql -U postgres stock_prod < backup.sql
```

---

## Recursos Adicionales

- [Documentación de Helm](https://helm.sh/docs/)
- [Documentación de Kubernetes](https://kubernetes.io/docs/)
- [Mejores Prácticas de Helm](https://helm.sh/docs/chart_best_practices/)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**Última actualización:** 18 de noviembre de 2025
