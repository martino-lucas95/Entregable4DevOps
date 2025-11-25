# Script para validar políticas de Kyverno y registrar evidencia (PowerShell)

$ErrorActionPreference = "Stop"

$LOG_FILE = "reports\kyverno-validation.log"
$TEST_NAMESPACE = "kyverno-test"

# Crear directorio de reports si no existe
if (-not (Test-Path "reports")) {
    New-Item -ItemType Directory -Path "reports" | Out-Null
}

# Función para loggear
function Log {
    param([string]$Message)
    $TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$TIMESTAMP] $Message"
    Write-Host $logMessage
    Add-Content -Path $LOG_FILE -Value $logMessage
}

# Función para limpiar recursos de prueba
function Cleanup {
    Log "Limpiando recursos de prueba..."
    kubectl delete namespace $TEST_NAMESPACE --ignore-not-found=true 2>&1 | Out-File -Append -FilePath $LOG_FILE
}

# Registrar limpieza al salir
Register-EngineEvent PowerShell.Exiting -Action { Cleanup } | Out-Null

Log "=========================================="
Log "Validación de Políticas de Kyverno"
Log "=========================================="
Log ""

# Verificar que kubectl esté disponible
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Log "ERROR: kubectl no está instalado o no está en el PATH"
    exit 1
}

# Verificar que Kyverno esté instalado
Log "[1/6] Verificando instalación de Kyverno..."
$namespaceExists = kubectl get namespace kyverno 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: Kyverno no está instalado. Ejecuta primero: .\install-kyverno.ps1"
    exit 1
}

# Verificar que los pods de Kyverno estén listos
try {
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=60s 2>&1 | Out-File -Append -FilePath $LOG_FILE
} catch {
    Log "ADVERTENCIA: Los pods de Kyverno no están listos"
}
Log "✓ Kyverno está instalado y funcionando"
Log ""

# Aplicar políticas
Log "[2/6] Aplicando políticas de Kyverno..."
$POLICIES_DIR = "kyverno\policies"
$POLICIES_APPLIED = 0

if (-not (Test-Path $POLICIES_DIR)) {
    Log "ERROR: Directorio de políticas no encontrado: $POLICIES_DIR"
    exit 1
}

Get-ChildItem -Path $POLICIES_DIR -Filter "*.yaml" | ForEach-Object {
    $POLICY_NAME = $_.Name
    Log "  Aplicando: $POLICY_NAME"
    kubectl apply -f $_.FullName 2>&1 | Out-File -Append -FilePath $LOG_FILE
    if ($LASTEXITCODE -eq 0) {
        $POLICIES_APPLIED++
        Log "    ✓ Política aplicada: $POLICY_NAME"
    } else {
        Log "    ✗ Error al aplicar: $POLICY_NAME"
    }
}

Log "✓ Total de políticas aplicadas: $POLICIES_APPLIED"
Log ""

# Verificar políticas aplicadas
Log "[3/6] Verificando políticas aplicadas..."
kubectl get clusterpolicies -o name | ForEach-Object {
    Log "  - $_"
}
Log ""

# Crear namespace de prueba
Log "[4/7] Creando namespace de prueba: $TEST_NAMESPACE"
kubectl create namespace $TEST_NAMESPACE --dry-run=client -o yaml | kubectl apply -f - 2>&1 | Out-File -Append -FilePath $LOG_FILE
Log "✓ Namespace creado"
Log ""

# Test 1: Política disallow-latest-tag
Log "[5/7] Ejecutando pruebas de validación..."
Log ""
Log "--- TEST 1: Política disallow-latest-tag ---"
Log "Intentando crear pod con imagen 'latest'..."

$test1Yaml = @"
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
"@

$test1Yaml | kubectl apply -f - 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
if ($LASTEXITCODE -ne 0) {
    Log "✓ TEST 1 PASADO: Pod con tag 'latest' fue correctamente rechazado"
} else {
    Log "✗ TEST 1 FALLÓ: Pod con tag 'latest' fue aceptado (no debería)"
    kubectl delete pod test-latest-tag -n $TEST_NAMESPACE --ignore-not-found=true 2>&1 | Out-File -Append -FilePath $LOG_FILE
}
Log ""

# Test 2: Política require-resource-limits
Log "--- TEST 2: Política require-resource-limits ---"
Log "Intentando crear pod sin límites de recursos..."

$test2Yaml = @"
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
"@

$test2Yaml | kubectl apply -f - 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
if ($LASTEXITCODE -ne 0) {
    Log "✓ TEST 2 PASADO: Pod sin límites de recursos fue correctamente rechazado"
} else {
    Log "✗ TEST 2 FALLÓ: Pod sin límites de recursos fue aceptado (no debería)"
    kubectl delete pod test-no-resources -n $TEST_NAMESPACE --ignore-not-found=true 2>&1 | Out-File -Append -FilePath $LOG_FILE
}
Log ""

# Test 3: Política disallow-root-containers
Log "--- TEST 3: Política disallow-root-containers ---"
Log "Intentando crear pod ejecutándose como root..."

$test3Yaml = @"
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
"@

$test3Yaml | kubectl apply -f - 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
if ($LASTEXITCODE -ne 0) {
    Log "✓ TEST 3 PASADO: Pod ejecutándose como root fue correctamente rechazado"
} else {
    Log "✗ TEST 3 FALLÓ: Pod ejecutándose como root fue aceptado (no debería)"
    kubectl delete pod test-root-container -n $TEST_NAMESPACE --ignore-not-found=true 2>&1 | Out-File -Append -FilePath $LOG_FILE
}
Log ""

# Test 4: Política require-labels
Log "--- TEST 4: Política require-labels ---"
Log "Intentando crear pod sin labels obligatorios..."

$test4Yaml = @"
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
"@

$test4Yaml | kubectl apply -f - 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
if ($LASTEXITCODE -ne 0) {
    Log "✓ TEST 4 PASADO: Pod sin labels obligatorios fue correctamente rechazado"
} else {
    Log "✗ TEST 4 FALLÓ: Pod sin labels obligatorios fue aceptado (no debería)"
    kubectl delete pod test-no-labels -n $TEST_NAMESPACE --ignore-not-found=true 2>&1 | Out-File -Append -FilePath $LOG_FILE
}
Log ""

# Test 5: Pod válido (debe ser aceptado)
Log "--- TEST 5: Pod válido (debe ser aceptado) ---"
Log "Intentando crear pod que cumple todas las políticas..."

$test5Yaml = @"
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
"@

$test5Yaml | kubectl apply -f - 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
if ($LASTEXITCODE -eq 0) {
    Log "✓ TEST 5 PASADO: Pod válido fue correctamente aceptado"
    kubectl delete pod test-valid-pod -n $TEST_NAMESPACE --ignore-not-found=true 2>&1 | Out-File -Append -FilePath $LOG_FILE
} else {
    Log "✗ TEST 5 FALLÓ: Pod válido fue rechazado (no debería)"
}
Log ""

# Test 6: Validar imagen Backend de la aplicación
Log "--- TEST 6: Validar imagen Backend de la aplicación ---"
Log "Intentando crear pod con imagen entregable4devops-backend:1.0..."

# Verificar si la imagen existe localmente
$backendImage = docker images -q entregable4devops-backend:1.0
if ($backendImage) {
    Log "  Imagen encontrada localmente"
    
    $test6Yaml = @"
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
"@

    $test6Yaml | kubectl apply -f - 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
    if ($LASTEXITCODE -eq 0) {
        Log "✓ TEST 6 PASADO: Pod con imagen backend fue correctamente aceptado"
        Start-Sleep -Seconds 2
        kubectl delete pod test-backend-app -n $TEST_NAMESPACE --ignore-not-found=true 2>&1 | Out-File -Append -FilePath $LOG_FILE
    } else {
        Log "✗ TEST 6 FALLÓ: Pod con imagen backend fue rechazado"
        Log "  Revisa que la imagen cumpla todas las políticas (tag específico, recursos, runAsNonRoot, labels)"
    }
} else {
    Log "⚠ TEST 6 OMITIDO: Imagen entregable4devops-backend:1.0 no encontrada localmente"
    Log "  Construye la imagen primero: cd backend && docker build -t entregable4devops-backend:1.0 ."
}
Log ""

# Test 7: Validar imagen Frontend de la aplicación
Log "--- TEST 7: Validar imagen Frontend de la aplicación ---"
Log "Intentando crear pod con imagen entregable4devops-frontend:1.0..."

# Verificar si la imagen existe localmente
$frontendImage = docker images -q entregable4devops-frontend:1.0
if ($frontendImage) {
    Log "  Imagen encontrada localmente"
    
    $test7Yaml = @"
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
"@

    $test7Yaml | kubectl apply -f - 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
    if ($LASTEXITCODE -eq 0) {
        Log "✓ TEST 7 PASADO: Pod con imagen frontend fue correctamente aceptado"
        Start-Sleep -Seconds 2
        kubectl delete pod test-frontend-app -n $TEST_NAMESPACE --ignore-not-found=true 2>&1 | Out-File -Append -FilePath $LOG_FILE
    } else {
        Log "✗ TEST 7 FALLÓ: Pod con imagen frontend fue rechazado"
        Log "  Revisa que la imagen cumpla todas las políticas (tag específico, recursos, runAsNonRoot, labels)"
    }
} else {
    Log "⚠ TEST 7 OMITIDO: Imagen entregable4devops-frontend:1.0 no encontrada localmente"
    Log "  Construye la imagen primero: cd frontend && docker build -t entregable4devops-frontend:1.0 ."
}
Log ""

# Verificar eventos de Kyverno
Log "[6/7] Revisando eventos de Kyverno..."
Log ""
Log "Eventos recientes de políticas:"
kubectl get events -n kyverno --sort-by='.lastTimestamp' --field-selector involvedObject.kind=ClusterPolicy --tail=20 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
Log ""

Log "Eventos de validación en namespace de prueba:"
kubectl get events -n $TEST_NAMESPACE --sort-by='.lastTimestamp' 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
Log ""

# Resumen final
Log "=========================================="
Log "Resumen de Validación"
Log "=========================================="
Log "Políticas aplicadas: $POLICIES_APPLIED"
Log "Tests ejecutados: 7 (5 de políticas + 2 de imágenes de aplicación)"
Log "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Log ""
Log "Para ver el estado de las políticas:"
Log "  kubectl get clusterpolicies"
Log ""
Log "Para ver detalles de una política:"
Log "  kubectl describe clusterpolicy <nombre-politica>"
Log ""
Log "Validación completada. Log guardado en: $LOG_FILE"
Log "=========================================="

