# Guía de Despliegue con Helm Chart

## ✅ Verificación de Requisitos Completados

### a. Helm Chart Creada
✅ **Completado**: Helm Chart creada en `./helm-chart/`

### b. Plantillas Mínimas Requeridas
✅ **Completado**: La chart contiene todas las plantillas necesarias:
- ✅ `templates/deployment-backend.yaml` - Deployment del backend
- ✅ `templates/deployment-frontend.yaml` - Deployment del frontend  
- ✅ `templates/deployment-postgresql.yaml` - Deployment de la base de datos
- ✅ `templates/service.yaml` - Services para todos los componentes
- ✅ `templates/configmap.yaml` - ConfigMaps para configuración
- ✅ `templates/ingress.yaml` - Ingress para acceso externo
- ✅ `templates/secret.yaml` - Secrets para credenciales
- ✅ `templates/pvc.yaml` - PersistentVolumeClaim para la base de datos
- ✅ `templates/_helpers.tpl` - Helpers para reutilización

### b. Archivo values.yaml
✅ **Completado**: El archivo `values.yaml` contiene parámetros configurables:
- ✅ Puerto del backend (3000)
- ✅ Puerto del frontend (5173)
- ✅ Imagen del backend y frontend con tags
- ✅ Número de réplicas (2 por defecto)
- ✅ Recursos (CPU y memoria - límites y requests)
- ✅ Configuración de health checks (liveness/readiness probes)
- ✅ Configuración de PostgreSQL
- ✅ Configuración de Ingress
- ✅ NodeSelector, tolerations y affinity

### c. Comando de Despliegue
✅ **Completado**: El despliegue se puede realizar con:
```bash
helm install stock-management ./helm-chart
```

### d. Archivos de Entorno
✅ **Completado**: Existen archivos diferenciados por entorno:
- ✅ `values-dev.yaml` - Configuración para desarrollo
- ✅ `values-prod.yaml` - Configuración para producción

### e. Verificación de Pods y Servicios
✅ **Preparado**: Scripts y comandos de verificación disponibles

---

## 📋 Prerequisitos

Antes de desplegar, asegúrate de tener:

1. **Helm instalado** (v3+)
   ```powershell
   helm version
   ```

2. **Cluster de Kubernetes** (Minikube, Docker Desktop, o cloud)
   ```powershell
   kubectl cluster-info
   ```

3. **Imágenes Docker construidas**
   ```powershell
   docker-compose build
   ```

4. **Cargar imágenes en Minikube** (si usas Minikube)
   ```powershell
   minikube image load entregable4devops-backend:1.0
   minikube image load entregable4devops-frontend:1.0
   ```

---

## 🚀 Instalación del Chart

### Opción 1: Instalación con Valores por Defecto

```powershell
helm install stock-management ./helm-chart
```

### Opción 2: Instalación para Desarrollo

```powershell
helm install stock-management ./helm-chart `
  --values ./helm-chart/values-dev.yaml `
  --namespace development `
  --create-namespace
```

### Opción 3: Instalación para Producción

```powershell
helm install stock-management ./helm-chart `
  --values ./helm-chart/values-prod.yaml `
  --namespace production `
  --create-namespace `
  --set postgresql.auth.password=SECURE_PASSWORD_HERE
```

### Opción 4: Instalación Customizada

```powershell
helm install stock-management ./helm-chart `
  --set backend.replicaCount=3 `
  --set frontend.replicaCount=2 `
  --set postgresql.persistence.size=5Gi
```

---

## 🔍 Verificación del Despliegue

### 1. Validar la Chart antes de instalar

```powershell
# Validar sintaxis
helm lint ./helm-chart

# Ver templates generados (dry-run)
helm template stock-management ./helm-chart --values ./helm-chart/values-dev.yaml

# Instalar en modo dry-run
helm install stock-management ./helm-chart --dry-run --debug
```

### 2. Verificar el Estado del Release

```powershell
# Ver status del release
helm status stock-management

# Listar todos los releases
helm list

# Ver historial de releases
helm history stock-management
```

### 3. Verificar que los Pods Inicien Correctamente

```powershell
# Ver todos los pods
kubectl get pods

# Ver pods en tiempo real
kubectl get pods -w

# Ver detalles de un pod específico
kubectl describe pod <pod-name>

# Ver logs del backend
kubectl logs -f deployment/stock-management-backend

# Ver logs del frontend
kubectl logs -f deployment/stock-management-frontend

# Ver logs de PostgreSQL
kubectl logs -f deployment/stock-management-postgresql
```

**Estado esperado**: Todos los pods deben estar en estado `Running` con `READY 1/1`

```
NAME                                          READY   STATUS    RESTARTS   AGE
stock-management-backend-xxxxxxxxxx-xxxxx     1/1     Running   0          2m
stock-management-backend-xxxxxxxxxx-xxxxx     1/1     Running   0          2m
stock-management-frontend-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
stock-management-frontend-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
stock-management-postgresql-xxxxxxxxxx-xxxxx  1/1     Running   0          2m
```

### 4. Verificar que los Servicios sean Accesibles

```powershell
# Ver todos los servicios
kubectl get services

# Ver endpoints
kubectl get endpoints
```

**Servicios esperados**:
```
NAME                          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
stock-management-backend      ClusterIP   10.x.x.x        <none>        3000/TCP   2m
stock-management-frontend     ClusterIP   10.x.x.x        <none>        5173/TCP   2m
stock-management-postgresql   ClusterIP   10.x.x.x        <none>        5432/TCP   2m
```

### 5. Probar Acceso al Backend

```powershell
# Port-forward para acceder al backend
kubectl port-forward service/stock-management-backend 3000:3000
```

Luego abre en el navegador: http://localhost:3000

### 6. Probar Acceso al Frontend

```powershell
# Port-forward para acceder al frontend
kubectl port-forward service/stock-management-frontend 5173:5173
```

Luego abre en el navegador: http://localhost:5173

### 7. Verificar ConfigMaps y Secrets

```powershell
# Ver ConfigMaps
kubectl get configmaps

# Ver contenido del ConfigMap
kubectl describe configmap stock-management-backend-config
kubectl describe configmap stock-management-frontend-config

# Ver Secrets
kubectl get secrets

# Ver contenido del Secret (base64 encoded)
kubectl get secret stock-management-backend-secret -o yaml
```

### 8. Verificar Persistencia de Datos

```powershell
# Ver PersistentVolumeClaims
kubectl get pvc

# Ver PersistentVolumes
kubectl get pv

# Ver detalles del PVC
kubectl describe pvc stock-management-postgresql-data
```

---

## 🧪 Testing Completo

### Script de Validación Automática

Ejecuta el script de validación completo:

```powershell
.\validate-helm.ps1
```

Este script realiza:
1. ✅ Validación de sintaxis (`helm lint`)
2. ✅ Generación de templates (`helm template`)
3. ✅ Verificación del cluster de Kubernetes
4. ✅ Verificación de imágenes Docker
5. ✅ Instalación en modo dry-run
6. ✅ Validación de recursos creados

---

## 📊 Monitoreo y Debug

### Ver Recursos Creados por el Release

```powershell
# Ver todos los recursos del release
kubectl get all -l app.kubernetes.io/instance=stock-management

# Ver deployments
kubectl get deployments

# Ver replicasets
kubectl get replicasets

# Ver eventos
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Debug de Pods Problemáticos

```powershell
# Si un pod no arranca, ver detalles
kubectl describe pod <pod-name>

# Ver logs con timestamps
kubectl logs <pod-name> --timestamps

# Ver logs del contenedor anterior (si reinició)
kubectl logs <pod-name> --previous

# Entrar al pod para debugging
kubectl exec -it <pod-name> -- /bin/sh
```

### Verificar Health Checks

```powershell
# Los health checks están configurados:
# Liveness Probe: Verifica que el pod esté vivo
# Readiness Probe: Verifica que el pod esté listo para recibir tráfico

# Ver estado de los probes
kubectl describe pod <pod-name> | Select-String -Pattern "Liveness|Readiness"
```

---

## 🔄 Gestión del Release

### Actualizar el Release

```powershell
# Actualizar con nuevos valores
helm upgrade stock-management ./helm-chart `
  --values ./helm-chart/values-dev.yaml `
  --set backend.image.tag=1.1

# Ver diferencias antes de aplicar
helm diff upgrade stock-management ./helm-chart --values ./helm-chart/values-dev.yaml
```

### Rollback

```powershell
# Ver historial
helm history stock-management

# Hacer rollback a la versión anterior
helm rollback stock-management

# Rollback a una versión específica
helm rollback stock-management 1
```

### Desinstalar

```powershell
# Desinstalar el release
helm uninstall stock-management

# Desinstalar y eliminar el namespace
helm uninstall stock-management --namespace development
kubectl delete namespace development
```

---

## 🌍 Entornos: Dev vs Prod

### Diferencias Principales

| Aspecto | Development (`values-dev.yaml`) | Production (`values-prod.yaml`) |
|---------|----------------------------------|----------------------------------|
| **Réplicas Backend** | 1 | 3 |
| **Réplicas Frontend** | 1 | 3 |
| **Service Type** | NodePort (30001, 30002) | ClusterIP |
| **Image Tag** | latest | 1.0.0 (versión específica) |
| **Image Pull Policy** | Always | IfNotPresent |
| **CPU Request** | 100m (backend) | 500m (backend) |
| **Memory Request** | 128Mi (backend) | 512Mi (backend) |
| **Storage** | 1Gi | 10Gi |
| **Ingress** | Deshabilitado | Habilitado con TLS |
| **PostgreSQL Réplicas** | 1 | 3 (con replicación) |

### Acceso en Desarrollo (NodePort)

```powershell
# Con values-dev.yaml, los servicios usan NodePort
# Backend: http://localhost:30001
# Frontend: http://localhost:30002

# Si usas Minikube
minikube service stock-management-backend --namespace development
minikube service stock-management-frontend --namespace development
```

### Acceso en Producción (Ingress)

```powershell
# Con values-prod.yaml, el acceso es mediante Ingress
# Requiere configurar DNS o /etc/hosts

# Ejemplo de configuración:
# stock.example.com -> Frontend
# api.stock.example.com -> Backend
```

---

## ✅ Checklist de Verificación Final

Después del despliegue, verifica:

- [ ] Todos los pods están en estado `Running`
- [ ] Todos los pods tienen `READY 1/1`
- [ ] No hay pods con `CrashLoopBackOff` o `Error`
- [ ] Los servicios tienen endpoints asignados
- [ ] El PVC está bound a un PV
- [ ] El backend responde en http://localhost:3000 (port-forward)
- [ ] El frontend responde en http://localhost:5173 (port-forward)
- [ ] Las migraciones de base de datos se ejecutaron correctamente
- [ ] Los health checks (liveness/readiness) están pasando
- [ ] Los logs no muestran errores críticos

---

## 📚 Comandos de Referencia Rápida

```powershell
# Validación
helm lint ./helm-chart

# Instalación
helm install stock-management ./helm-chart --values ./helm-chart/values-dev.yaml

# Verificación
kubectl get pods
kubectl get services
kubectl get pvc

# Logs
kubectl logs -f deployment/stock-management-backend

# Port-Forward
kubectl port-forward service/stock-management-frontend 5173:5173

# Actualización
helm upgrade stock-management ./helm-chart --values ./helm-chart/values-dev.yaml

# Desinstalación
helm uninstall stock-management
```

---

## 🎯 Resumen

✅ **Todos los requisitos del proyecto están completados**:

- [x] **a.** Helm Chart creada para despliegue en Kubernetes
- [x] **b.** Plantillas incluidas: Deployment, Service, ConfigMap, Ingress, Secret, PVC
- [x] **b.** Archivo `values.yaml` con parámetros configurables (puerto, imagen, réplicas, recursos)
- [x] **c.** Comando de instalación: `helm install stock-management ./helm-chart`
- [x] **d.** Archivos `values-dev.yaml` y `values-prod.yaml` diferenciados por entorno
- [x] **e.** Instrucciones de verificación de pods y servicios

La Helm Chart está **lista para producción** y puede ser desplegada en cualquier cluster de Kubernetes siguiendo las instrucciones de esta guía.
