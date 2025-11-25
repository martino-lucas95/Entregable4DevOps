# Guía de Instalación y Configuración Completa

Esta guía proporciona instrucciones paso a paso para inicializar, configurar y utilizar todo el entorno del proyecto Stock Management System.

## 📋 Tabla de Contenidos

- [Prerequisitos](#prerequisitos)
- [Inicialización Completa del Entorno](#inicialización-completa-del-entorno)
- [Populando Dashboards con Datos](#populando-dashboards-con-datos)
- [Acceso a Componentes](#acceso-a-componentes)
- [Limpieza del Entorno](#limpieza-del-entorno)
- [Troubleshooting](#troubleshooting)

## 🔧 Prerequisitos

Antes de comenzar, asegúrate de tener instaladas las siguientes herramientas:

### Herramientas Requeridas

1. **kubectl** (v1.20+)
   ```bash
   # Verificar instalación
   kubectl version --client
   ```

2. **Helm** (v3.0+)
   ```bash
   # Verificar instalación
   helm version
   ```

3. **Docker** (v20.10+)
   ```bash
   # Verificar instalación
   docker --version
   ```

4. **Minikube** (o cualquier cluster de Kubernetes)
   ```bash
   # Verificar que Minikube esté corriendo
   minikube status
   
   # Si no está corriendo, iniciarlo:
   minikube start
   ```

### Verificación de Conexión al Cluster

```bash
# Verificar conexión al cluster
kubectl cluster-info

# Verificar que puedes listar nodos
kubectl get nodes
```

**Resultado esperado:**
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   5m    v1.28.0
```

## 🚀 Inicialización Completa del Entorno

El script `setup-environment.sh` automatiza toda la inicialización del entorno.

### Paso 1: Ejecutar Script de Inicialización

```bash
./setup-environment.sh
```

### ¿Qué hace este script?

El script realiza las siguientes acciones en orden:

1. **Verificación de Prerequisitos**
   - Verifica que `kubectl`, `helm` y `docker` estén instalados
   - Verifica conexión al cluster de Kubernetes

2. **Instalación de Operadores**
   - Verifica si se requieren operadores adicionales
   - En este proyecto usamos deployments directos, no operadores

3. **Construcción de Imágenes Docker**
   - Construye `entregable4devops-backend:1.0`
   - Construye `entregable4devops-frontend:1.0`

4. **Instalación de Kyverno**
   - Instala Kyverno usando Helm
   - Verifica que los pods estén listos

5. **Aplicación de Políticas de Kyverno**
   - Aplica las 4 políticas de seguridad:
     - `disallow-latest-tag`
     - `require-resource-limits`
     - `disallow-root-containers`
     - `require-labels`

6. **Instalación de Falco**
   - Instala Falco para monitoreo de seguridad en tiempo de ejecución

7. **Instalación de Jenkins**
   - Instala Jenkins usando Helm Chart oficial
   - Configura Jenkins para cumplir con políticas de Kyverno
   - Expone Jenkins en NodePort 30080
   - Obtiene y muestra la contraseña inicial

8. **Despliegue de la Aplicación**
   - Crea el namespace `development`
   - Despliega la aplicación usando Helm Chart
   - Espera a que todos los pods estén listos

8. **Verificación de Servicios**
   - Muestra el estado de todos los servicios
   - Proporciona URLs de acceso

### Resultado Esperado

Al finalizar, deberías ver:

```
✓ Inicialización Completada
==========================================

Próximos pasos:
1. Ejecuta './populate-dashboards.sh' para generar datos y popular dashboards
2. Accede a Grafana para ver las métricas
3. Usa './cleanup-environment.sh' para limpiar todos los recursos

Log completo guardado en: setup-environment.log
```

### Verificación Manual

Después de la inicialización, verifica que todo esté funcionando:

```bash
# Ver todos los pods en el namespace development
kubectl get pods -n development

# Resultado esperado:
# NAME                                          READY   STATUS    RESTARTS   AGE
# stock-management-backend-xxx                  1/1     Running   0          2m
# stock-management-frontend-xxx                  1/1     Running   0          2m
# stock-management-postgresql-xxx                1/1     Running   0          2m
# stock-management-prometheus-xxx                1/1     Running   0          2m
# stock-management-grafana-xxx                  1/1     Running   0          2m

# Ver servicios
kubectl get svc -n development

# Verificar políticas de Kyverno
kubectl get clusterpolicies

# Verificar Falco
kubectl get pods -n falco

# Verificar Kyverno
kubectl get pods -n kyverno

# Verificar Jenkins
kubectl get pods -n jenkins
kubectl get svc -n jenkins
```

## 📊 Populando Dashboards con Datos

Para que los dashboards de Grafana muestren datos reales, necesitas generar tráfico y crear datos en la aplicación.

### Paso 1: Ejecutar Script de Populación

```bash
./populate-dashboards.sh
```

### ¿Qué hace este script?

1. **Configuración de Port-Forward**
   - Configura port-forward automático para el backend si es necesario
   - Verifica que el backend esté accesible

2. **Creación de Productos**
   - Crea 5 productos de ejemplo:
     - Laptop Dell XPS 15
     - Mouse Logitech MX Master
     - Teclado Mecánico Keychron
     - Monitor LG 27 pulgadas
     - Webcam Logitech C920

3. **Creación de Movimientos de Stock**
   - Crea movimientos de entrada (IN) para cada producto
   - Crea movimientos de salida (OUT) para generar historial
   - Esto genera métricas de negocio (productos totales, movimientos)

4. **Generación de Tráfico HTTP**
   - Hace múltiples requests GET a los endpoints de la API
   - Esto genera métricas HTTP (requests por segundo, latencia)

### Resultado Esperado

```
✓ Dashboards Populados
==========================================

Los dashboards de Grafana ahora deberían mostrar:
  - Productos en inventario
  - Movimientos de stock (IN/OUT)
  - Métricas HTTP (requests, latencia)
  - Métricas de CPU y memoria

Accede a Grafana para ver los dashboards:
  kubectl port-forward svc/stock-management-grafana 3000:80 -n development
```

### Verificación de Datos Creados

Puedes verificar que los datos se crearon correctamente:

```bash
# Obtener puerto del backend
BACKEND_PORT=$(kubectl get svc -n development -l app.kubernetes.io/component=backend -o jsonpath='{.items[0].spec.ports[0].nodePort}')

# Configurar port-forward si es necesario
kubectl port-forward svc/stock-management-backend $BACKEND_PORT:3000 -n development &

# Ver productos creados
curl http://localhost:$BACKEND_PORT/products | jq

# Ver stock
curl http://localhost:$BACKEND_PORT/stock | jq

# Ver movimientos
curl http://localhost:$BACKEND_PORT/movements | jq
```

## 🌐 Acceso a Componentes

### Backend API

```bash
# Obtener puerto
BACKEND_PORT=$(kubectl get svc -n development -l app.kubernetes.io/component=backend -o jsonpath='{.items[0].spec.ports[0].nodePort}')

# Configurar port-forward
kubectl port-forward svc/stock-management-backend $BACKEND_PORT:3000 -n development

# Acceder en otro terminal
curl http://localhost:$BACKEND_PORT/products
```

**URLs disponibles:**
- `GET /products` - Listar productos
- `POST /products` - Crear producto
- `GET /stock` - Obtener stock de todos los productos
- `GET /movements` - Listar movimientos
- `POST /movements` - Crear movimiento
- `GET /metrics` - Métricas de Prometheus

### Frontend Web

```bash
# Obtener puerto
FRONTEND_PORT=$(kubectl get svc -n development -l app.kubernetes.io/component=frontend -o jsonpath='{.items[0].spec.ports[0].nodePort}')

# Configurar port-forward
kubectl port-forward svc/stock-management-frontend $FRONTEND_PORT:5173 -n development

# Acceder en navegador
# http://localhost:$FRONTEND_PORT
```

### Grafana

```bash
# Configurar port-forward
kubectl port-forward svc/stock-management-grafana 3000:80 -n development

# Acceder en navegador
# http://localhost:3000
# Usuario: admin
# Contraseña: admin (cambiar al primer login)
```

**Dashboards disponibles:**
- **Stock Management Monitoring**: Dashboard principal con todas las métricas

**Métricas visibles:**
- Requests por segundo (RPS)
- Latencia promedio
- Uso de CPU por pod
- Uso de memoria por pod
- Total de productos en inventario
- Movimientos de stock por tipo (IN/OUT)
- Log de movimientos recientes

### Prometheus

```bash
# Configurar port-forward
kubectl port-forward svc/stock-management-prometheus 9090:9090 -n development

# Acceder en navegador
# http://localhost:9090
```

### Jenkins

```bash
# Obtener puerto (NodePort 30080 por defecto)
JENKINS_PORT=$(kubectl get svc -n jenkins -l app.kubernetes.io/component=jenkins-controller -o jsonpath='{.items[0].spec.ports[0].nodePort}')

# Acceder directamente (si NodePort está configurado)
# http://localhost:$JENKINS_PORT

# O usar port-forward
kubectl port-forward svc/jenkins 8080:8080 -n jenkins

# Acceder en navegador
# http://localhost:8080
# Usuario: admin
# Contraseña: (obtener con el comando siguiente)
```

**Obtener contraseña inicial de Jenkins:**

```bash
# Obtener contraseña del pod de Jenkins
kubectl exec -n jenkins \
  $(kubectl get pod -n jenkins -l app.kubernetes.io/component=jenkins-controller -o jsonpath='{.items[0].metadata.name}') \
  -- cat /run/secrets/additional/chart-admin-password
```

**Configuración inicial de Jenkins:**

1. Acceder a Jenkins con usuario `admin` y la contraseña obtenida
2. Instalar plugins recomendados (opcional)
3. Crear usuario administrador (opcional)
4. Configurar credenciales necesarias para el pipeline:
   - `docker-registry-url`: URL del registro Docker
   - `docker-credentials`: Credenciales de Docker
   - `kubeconfig`: Configuración de Kubernetes
   - `checkmarx-one-api-key`: API Key de Checkmarx One
   - `checkmarx-one-base-uri`: URL base de Checkmarx One
5. Crear un nuevo pipeline desde el Jenkinsfile del repositorio

**Consultas útiles en Prometheus:**
```
# Requests por segundo
sum(rate(http_requests_total{job="nestjs-backend"}[1m])) by (pod)

# Latencia promedio
sum(rate(http_request_duration_seconds_sum[5m])) by (pod) / sum(rate(http_request_duration_seconds_count[5m])) by (pod) * 1000

# Total de productos
max(stock_products_total)

# Movimientos por tipo
sum(stock_movements_total) by (type)
```

## 🧹 Limpieza del Entorno

Para eliminar todos los recursos y limpiar el entorno:

### Paso 1: Ejecutar Script de Limpieza

```bash
./cleanup-environment.sh
```

### ¿Qué hace este script?

1. **Confirmación de Acción Destructiva**
   - Solicita confirmación antes de eliminar recursos
   - Debes escribir `yes` para continuar

2. **Detención de Port-Forwards**
   - Detiene todos los port-forwards activos
   - Libera los puertos

3. **Desinstalación de la Aplicación**
   - Desinstala el Helm release
   - Elimina el namespace `development` (y todos sus recursos)

4. **Eliminación de Políticas de Kyverno**
   - Elimina todas las ClusterPolicies
   - Elimina PolicyExceptions

5. **Desinstalación de Falco**
   - Desinstala Falco usando Helm
   - Elimina el namespace `falco`

6. **Desinstalación de Jenkins**
   - Desinstala Jenkins usando Helm
   - Elimina el namespace `jenkins`

7. **Desinstalación de Kyverno**
   - Desinstala Kyverno usando Helm
   - Elimina el namespace `kyverno`

7. **Limpieza de Imágenes Docker (Opcional)**
   - Pregunta si deseas eliminar las imágenes Docker locales
   - Elimina `entregable4devops-backend:1.0` y `entregable4devops-frontend:1.0`

### Resultado Esperado

```
✓ Limpieza Completada
==========================================

Recursos eliminados:
  ✓ Aplicación y namespace development
  ✓ Políticas de Kyverno
  ✓ Falco
  ✓ Jenkins
  ✓ Kyverno
  ✓ Port-forwards

Para volver a inicializar el entorno, ejecuta:
  ./setup-environment.sh
```

### Verificación de Limpieza

```bash
# Verificar que el namespace fue eliminado
kubectl get namespace development
# Error esperado: Error from server (NotFound): namespaces "development" not found

# Verificar que Kyverno fue eliminado
kubectl get namespace kyverno
# Error esperado: Error from server (NotFound): namespaces "kyverno" not found

# Verificar que Falco fue eliminado
kubectl get namespace falco
# Error esperado: Error from server (NotFound): namespaces "falco" not found

# Verificar que Jenkins fue eliminado
kubectl get namespace jenkins
# Error esperado: Error from server (NotFound): namespaces "jenkins" not found

# Verificar políticas de Kyverno
kubectl get clusterpolicies
# No debe mostrar políticas relacionadas con el proyecto
```

## 🔍 Troubleshooting

### Problema: Backend no está accesible

**Síntomas:**
- El script `populate-dashboards.sh` falla al conectar con el backend
- Error: "Connection refused" o "No se pudo obtener el puerto del backend"

**Solución:**
```bash
# Verificar que el pod del backend esté corriendo
kubectl get pods -n development -l app.kubernetes.io/component=backend

# Ver logs del backend
kubectl logs -n development -l app.kubernetes.io/component=backend --tail=50

# Verificar el servicio
kubectl get svc -n development -l app.kubernetes.io/component=backend

# Reiniciar el pod si es necesario
kubectl delete pod -n development -l app.kubernetes.io/component=backend
```

### Problema: Port-forward no funciona

**Síntomas:**
- Error: "Address already in use"
- El port-forward se cierra inmediatamente

**Solución:**
```bash
# Verificar qué proceso está usando el puerto
lsof -i :30001
lsof -i :30002
lsof -i :9090
lsof -i :3000

# Matar procesos si es necesario
kill -9 <PID>

# O usar un puerto diferente
kubectl port-forward svc/stock-management-backend 30001:3000 -n development
```

### Problema: Helm deployment falla

**Síntomas:**
- Error: "UPGRADE FAILED" o "release not found"
- Los pods no se crean

**Solución:**
```bash
# Ver el estado del release
helm status stock-management -n development

# Ver el historial
helm history stock-management -n development

# Ver eventos de Kubernetes
kubectl get events -n development --sort-by='.lastTimestamp'

# Desinstalar y volver a instalar
helm uninstall stock-management -n development
./setup-environment.sh
```

### Problema: Políticas de Kyverno bloquean recursos

**Síntomas:**
- Error: "admission webhook validate.kyverno.svc-fail denied the request"
- Los pods no se pueden crear

**Solución:**
```bash
# Ver qué políticas están bloqueando
kubectl describe pod <pod-name> -n development

# Verificar políticas aplicadas
kubectl get clusterpolicies

# Temporalmente deshabilitar una política (solo para debugging)
kubectl patch clusterpolicy <policy-name> --type='json' -p='[{"op": "replace", "path": "/spec/validationFailureAction", "value": "audit"}]'

# O excluir el namespace de las políticas (ver kyverno/policies/*.yaml)
```

### Problema: Falco no genera alertas

**Síntomas:**
- Falco está instalado pero no muestra alertas
- El script `generate-falco-alert.sh` no encuentra eventos

**Solución:**
```bash
# Verificar que Falco esté corriendo
kubectl get pods -n falco

# Ver logs de Falco
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100

# Verificar configuración
kubectl exec -n falco $(kubectl get pod -n falco -l app.kubernetes.io/name=falco -o jsonpath='{.items[0].metadata.name}') -- cat /etc/falco/falco.yaml

# Ejecutar script de generación de alertas
./generate-falco-alert.sh
```

### Problema: Grafana no muestra datos

**Síntomas:**
- Grafana está accesible pero los dashboards están vacíos
- No hay métricas en Prometheus

**Solución:**
```bash
# Verificar que Prometheus esté recolectando métricas
kubectl port-forward svc/stock-management-prometheus 9090:9090 -n development
# Acceder a http://localhost:9090 y buscar métricas: http_requests_total

# Verificar que el backend esté exponiendo métricas
BACKEND_PORT=$(kubectl get svc -n development -l app.kubernetes.io/component=backend -o jsonpath='{.items[0].spec.ports[0].nodePort}')
kubectl port-forward svc/stock-management-backend $BACKEND_PORT:3000 -n development
curl http://localhost:$BACKEND_PORT/metrics

# Verificar configuración de Prometheus
kubectl get configmap -n development stock-management-prometheus-config -o yaml

# Regenerar datos
./populate-dashboards.sh
```

## 📝 Comandos Útiles Adicionales

### Ver logs en tiempo real

```bash
# Backend
kubectl logs -f -n development -l app.kubernetes.io/component=backend

# Frontend
kubectl logs -f -n development -l app.kubernetes.io/component=frontend

# Prometheus
kubectl logs -f -n development -l app.kubernetes.io/component=prometheus

# Grafana
kubectl logs -f -n development -l app.kubernetes.io/component=grafana
```

### Reiniciar un componente

```bash
# Reiniciar backend
kubectl rollout restart deployment/stock-management-backend -n development

# Reiniciar frontend
kubectl rollout restart deployment/stock-management-frontend -n development
```

### Escalar componentes

```bash
# Escalar backend a 2 réplicas
kubectl scale deployment/stock-management-backend --replicas=2 -n development

# Ver estado de las réplicas
kubectl get pods -n development -l app.kubernetes.io/component=backend
```

### Acceder a un pod

```bash
# Acceder al pod del backend
kubectl exec -it -n development $(kubectl get pod -n development -l app.kubernetes.io/component=backend -o jsonpath='{.items[0].metadata.name}') -- /bin/sh

# Acceder a la base de datos
kubectl exec -it -n development $(kubectl get pod -n development -l app.kubernetes.io/component=postgresql -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres -d stockdb
```

## 📚 Referencias

- [Documentación de Kubernetes](https://kubernetes.io/docs/)
- [Documentación de Helm](https://helm.sh/docs/)
- [Documentación de Kyverno](https://kyverno.io/docs/)
- [Documentación de Falco](https://falco.org/docs/)
- [Documentación de Prometheus](https://prometheus.io/docs/)
- [Documentación de Grafana](https://grafana.com/docs/)

---

**Última actualización:** Noviembre 24, 2025

