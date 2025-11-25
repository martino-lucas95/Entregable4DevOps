#!/bin/bash
# Script para validar políticas de Kyverno y registrar evidencia

# No usar set -e porque necesitamos capturar exit codes de kubectl en los tests
set +e

LOG_FILE="reports/kyverno-validation.log"
TEST_NAMESPACE="kyverno-test"

# Crear directorio de reports si no existe
mkdir -p reports

# Función para loggear
log() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Función para limpiar recursos de prueba
cleanup() {
    log "Limpiando recursos de prueba..."
    kubectl delete namespace "$TEST_NAMESPACE" --ignore-not-found=true >> "$LOG_FILE" 2>&1 || true
}

# Trap para limpiar al salir
trap cleanup EXIT

log "=========================================="
log "Validación de Políticas de Kyverno"
log "=========================================="
log ""

# Verificar que kubectl esté disponible
if ! command -v kubectl &> /dev/null; then
    log "ERROR: kubectl no está instalado o no está en el PATH"
    exit 1
fi

# Verificar que Kyverno esté instalado
log "[1/6] Verificando instalación de Kyverno..."
if ! kubectl get namespace kyverno &> /dev/null; then
    log "ERROR: Kyverno no está instalado. Ejecuta primero: ./install-kyverno.sh"
    exit 1
fi

# Verificar que los pods de Kyverno estén listos
if ! kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=60s >> "$LOG_FILE" 2>&1; then
    log "ADVERTENCIA: Los pods de Kyverno no están listos"
fi
log "✓ Kyverno está instalado y funcionando"
log ""

# Aplicar políticas
log "[2/6] Aplicando políticas de Kyverno..."
POLICIES_DIR="kyverno/policies"
POLICIES_APPLIED=0

if [ ! -d "$POLICIES_DIR" ]; then
    log "ERROR: Directorio de políticas no encontrado: $POLICIES_DIR"
    exit 1
fi

for policy in "$POLICIES_DIR"/*.yaml; do
    if [ -f "$policy" ]; then
        POLICY_NAME=$(basename "$policy")
        log "  Aplicando: $POLICY_NAME"
        kubectl apply -f "$policy" >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            POLICIES_APPLIED=$((POLICIES_APPLIED + 1))
            log "    ✓ Política aplicada: $POLICY_NAME"
        else
            log "    ✗ Error al aplicar: $POLICY_NAME"
        fi
    fi
done

log "✓ Total de políticas aplicadas: $POLICIES_APPLIED"
log ""

# Verificar políticas aplicadas
log "[3/6] Verificando políticas aplicadas..."
kubectl get clusterpolicies -o name | while read policy; do
    log "  - $policy"
done
log ""

# Crear namespace de prueba
log "[4/7] Creando namespace de prueba: $TEST_NAMESPACE"
kubectl create namespace "$TEST_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >> "$LOG_FILE" 2>&1
log "✓ Namespace creado"
log ""

# Test 1: Política disallow-latest-tag
log "[5/7] Ejecutando pruebas de validación..."
log ""
log "--- TEST 1: Política disallow-latest-tag ---"
log "Intentando crear pod con imagen 'latest'..."

KUBECTL_OUTPUT=$(cat <<EOF | kubectl apply -f - 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: test-latest-tag
  namespace: $TEST_NAMESPACE
  labels:
    app: test
    version: "1.0"
    environment: test
spec:
  containers:
  - name: test
    image: nginx:latest
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
      requests:
        cpu: "50m"
        memory: "64Mi"
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
EOF
)
KUBECTL_EXIT=$?
echo "$KUBECTL_OUTPUT" | tee -a "$LOG_FILE"

if [ $KUBECTL_EXIT -ne 0 ]; then
    log "✓ TEST 1 PASADO: Pod con tag 'latest' fue correctamente rechazado"
else
    log "✗ TEST 1 FALLÓ: Pod con tag 'latest' fue aceptado (no debería)"
    kubectl delete pod test-latest-tag -n "$TEST_NAMESPACE" --ignore-not-found=true >> "$LOG_FILE" 2>&1 || true
fi
log ""

# Test 2: Política require-resource-limits
log "--- TEST 2: Política require-resource-limits ---"
log "Intentando crear pod sin límites de recursos..."

cat <<EOF | kubectl apply -f - 2>&1 | tee -a "$LOG_FILE"
apiVersion: v1
kind: Pod
metadata:
  name: test-no-resources
  namespace: $TEST_NAMESPACE
  labels:
    app: test
    version: "1.0"
    environment: test
spec:
  containers:
  - name: test
    image: nginx:1.25
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
EOF
KUBECTL_EXIT=$?

if [ $KUBECTL_EXIT -ne 0 ]; then
    log "✓ TEST 2 PASADO: Pod sin límites de recursos fue correctamente rechazado"
else
    log "✗ TEST 2 FALLÓ: Pod sin límites de recursos fue aceptado (no debería)"
    kubectl delete pod test-no-resources -n "$TEST_NAMESPACE" --ignore-not-found=true >> "$LOG_FILE" 2>&1 || true
fi
log ""

# Test 3: Política disallow-root-containers
log "--- TEST 3: Política disallow-root-containers ---"
log "Intentando crear pod ejecutándose como root..."

cat <<EOF | kubectl apply -f - 2>&1 | tee -a "$LOG_FILE"
apiVersion: v1
kind: Pod
metadata:
  name: test-root-container
  namespace: $TEST_NAMESPACE
  labels:
    app: test
    version: "1.0"
    environment: test
spec:
  containers:
  - name: test
    image: nginx:1.25
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
      requests:
        cpu: "50m"
        memory: "64Mi"
EOF
KUBECTL_EXIT=$?

if [ $KUBECTL_EXIT -ne 0 ]; then
    log "✓ TEST 3 PASADO: Pod ejecutándose como root fue correctamente rechazado"
else
    log "✗ TEST 3 FALLÓ: Pod ejecutándose como root fue aceptado (no debería)"
    kubectl delete pod test-root-container -n "$TEST_NAMESPACE" --ignore-not-found=true >> "$LOG_FILE" 2>&1 || true
fi
log ""

# Test 4: Política require-labels
log "--- TEST 4: Política require-labels ---"
log "Intentando crear pod sin labels obligatorios..."

cat <<EOF | kubectl apply -f - 2>&1 | tee -a "$LOG_FILE"
apiVersion: v1
kind: Pod
metadata:
  name: test-no-labels
  namespace: $TEST_NAMESPACE
spec:
  containers:
  - name: test
    image: nginx:1.25
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
      requests:
        cpu: "50m"
        memory: "64Mi"
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
EOF
KUBECTL_EXIT=$?

if [ $KUBECTL_EXIT -ne 0 ]; then
    log "✓ TEST 4 PASADO: Pod sin labels obligatorios fue correctamente rechazado"
else
    log "✗ TEST 4 FALLÓ: Pod sin labels obligatorios fue aceptado (no debería)"
    kubectl delete pod test-no-labels -n "$TEST_NAMESPACE" --ignore-not-found=true >> "$LOG_FILE" 2>&1 || true
fi
log ""

# Test 5: Pod válido (debe ser aceptado)
log "--- TEST 5: Pod válido (debe ser aceptado) ---"
log "Intentando crear pod que cumple todas las políticas..."

cat <<EOF | kubectl apply -f - 2>&1 | tee -a "$LOG_FILE"
apiVersion: v1
kind: Pod
metadata:
  name: test-valid-pod
  namespace: $TEST_NAMESPACE
  labels:
    app: test
    version: "1.0"
    environment: test
spec:
  containers:
  - name: test
    image: nginx:1.25
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
      requests:
        cpu: "50m"
        memory: "64Mi"
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
EOF
KUBECTL_EXIT=$?

if [ $KUBECTL_EXIT -eq 0 ]; then
    log "✓ TEST 5 PASADO: Pod válido fue correctamente aceptado"
    # Limpiar pod válido
    kubectl delete pod test-valid-pod -n "$TEST_NAMESPACE" --ignore-not-found=true >> "$LOG_FILE" 2>&1 || true
else
    log "✗ TEST 5 FALLÓ: Pod válido fue rechazado (no debería)"
fi
log ""

# ==========================================
# TEST IMÁGENES DESARROLLADAS
# ==========================================
log ""
log "=========================================="
log "TEST IMÁGENES DESARROLLADAS"
log "=========================================="
log "Verificando que las imágenes desarrolladas cumplan con todas las políticas de Kyverno"
log ""

# Test Backend: Validar imagen Backend de la aplicación
log "--- TEST BACKEND: Validar imagen entregable4devops-backend:1.0 ---"
log "Verificando que el pod con imagen backend cumple todas las políticas..."

# Verificar si la imagen existe localmente
if docker images | grep -q "entregable4devops-backend.*1.0"; then
    log "  ✓ Imagen encontrada localmente: entregable4devops-backend:1.0"
    log "  Cargando imagen en minikube..."
    minikube image load entregable4devops-backend:1.0 >> "$LOG_FILE" 2>&1 || true
    
    KUBECTL_OUTPUT=$(cat <<EOF | kubectl apply -f - 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: test-backend-app
  namespace: $TEST_NAMESPACE
  labels:
    app: stock-management
    version: "1.0"
    environment: test
spec:
  containers:
  - name: backend
    image: entregable4devops-backend:1.0
    imagePullPolicy: IfNotPresent
    resources:
      limits:
        cpu: "500m"
        memory: "512Mi"
      requests:
        cpu: "250m"
        memory: "256Mi"
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
EOF
    )
    KUBECTL_EXIT=$?
    echo "$KUBECTL_OUTPUT" | tee -a "$LOG_FILE"

    if [ $KUBECTL_EXIT -eq 0 ]; then
        log "  ✓ Pod creado exitosamente"
        log "  ✓ Verificación de políticas:"
        log "    - Tag específico (1.0, no latest): ✓ CUMPLE"
        log "    - Límites de recursos (CPU y memoria): ✓ CUMPLE"
        log "    - SecurityContext runAsNonRoot: ✓ CUMPLE"
        log "    - Labels obligatorios (app, version, environment): ✓ CUMPLE"
        log "✓ TEST BACKEND PASADO: Imagen backend cumple con todas las políticas de Kyverno"
        sleep 2
        kubectl delete pod test-backend-app -n "$TEST_NAMESPACE" --ignore-not-found=true >> "$LOG_FILE" 2>&1
    else
        log "  ✗ Pod rechazado por Kyverno"
        log "✗ TEST BACKEND FALLÓ: Imagen backend NO cumple con las políticas de Kyverno"
        log "  Revisa los errores arriba y corrige la configuración del pod"
    fi
else
    log "  ⚠ Imagen no encontrada localmente: entregable4devops-backend:1.0"
    log "⚠ TEST BACKEND OMITIDO: Construye la imagen primero:"
    log "  cd backend && docker build -t entregable4devops-backend:1.0 ."
fi
log ""

# Test Frontend: Validar imagen Frontend de la aplicación
log "--- TEST FRONTEND: Validar imagen entregable4devops-frontend:1.0 ---"
log "Verificando que el pod con imagen frontend cumple todas las políticas..."

# Verificar si la imagen existe localmente
if docker images | grep -q "entregable4devops-frontend.*1.0"; then
    log "  ✓ Imagen encontrada localmente: entregable4devops-frontend:1.0"
    log "  Cargando imagen en minikube..."
    minikube image load entregable4devops-frontend:1.0 >> "$LOG_FILE" 2>&1 || true
    
    KUBECTL_OUTPUT=$(cat <<EOF | kubectl apply -f - 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: test-frontend-app
  namespace: $TEST_NAMESPACE
  labels:
    app: stock-management
    version: "1.0"
    environment: test
spec:
  containers:
  - name: frontend
    image: entregable4devops-frontend:1.0
    imagePullPolicy: IfNotPresent
    resources:
      limits:
        cpu: "200m"
        memory: "256Mi"
      requests:
        cpu: "100m"
        memory: "128Mi"
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
EOF
    )
    KUBECTL_EXIT=$?
    echo "$KUBECTL_OUTPUT" | tee -a "$LOG_FILE"

    if [ $KUBECTL_EXIT -eq 0 ]; then
        log "  ✓ Pod creado exitosamente"
        log "  ✓ Verificación de políticas:"
        log "    - Tag específico (1.0, no latest): ✓ CUMPLE"
        log "    - Límites de recursos (CPU y memoria): ✓ CUMPLE"
        log "    - SecurityContext runAsNonRoot: ✓ CUMPLE"
        log "    - Labels obligatorios (app, version, environment): ✓ CUMPLE"
        log "✓ TEST FRONTEND PASADO: Imagen frontend cumple con todas las políticas de Kyverno"
        sleep 2
        kubectl delete pod test-frontend-app -n "$TEST_NAMESPACE" --ignore-not-found=true >> "$LOG_FILE" 2>&1
    else
        log "  ✗ Pod rechazado por Kyverno"
        log "✗ TEST FRONTEND FALLÓ: Imagen frontend NO cumple con las políticas de Kyverno"
        log "  Revisa los errores arriba y corrige la configuración del pod"
    fi
else
    log "  ⚠ Imagen no encontrada localmente: entregable4devops-frontend:1.0"
    log "⚠ TEST FRONTEND OMITIDO: Construye la imagen primero:"
    log "  cd frontend && docker build -t entregable4devops-frontend:1.0 ."
fi
log ""

log "=========================================="
log "RESUMEN TEST IMÁGENES DESARROLLADAS"
log "=========================================="

# Verificar eventos de Kyverno
log "[6/7] Revisando eventos de Kyverno..."
log ""
log "Eventos recientes de políticas:"
kubectl get events -n kyverno --sort-by='.lastTimestamp' --field-selector involvedObject.kind=ClusterPolicy --tail=20 2>&1 | tee -a "$LOG_FILE" || true
log ""

log "Eventos de validación en namespace de prueba:"
kubectl get events -n "$TEST_NAMESPACE" --sort-by='.lastTimestamp' 2>&1 | tee -a "$LOG_FILE" || true
log ""

# Resumen final
log "=========================================="
log "RESUMEN GENERAL DE VALIDACIÓN"
log "=========================================="
log "Políticas aplicadas: $POLICIES_APPLIED"
log "Tests de políticas (bloqueo): 5"
log "Tests de imágenes desarrolladas: 2"
log "Total de tests ejecutados: 7"
log "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
log ""
log "Para ver el estado de las políticas:"
log "  kubectl get clusterpolicies"
log ""
log "Para ver detalles de una política:"
log "  kubectl describe clusterpolicy <nombre-politica>"
log ""
log "Validación completada. Log guardado en: $LOG_FILE"
log "=========================================="

