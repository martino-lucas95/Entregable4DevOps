# Script para validar el despliegue de Helm Chart
# Este script verifica que todo esté correctamente configurado

Write-Host "=== Validación de Helm Chart ===" -ForegroundColor Green

# Variables
$CHART_PATH = ".\helm-chart"
$RELEASE_NAME = "stock-management-test"
$NAMESPACE = "test"

Write-Host "`n[1/6] Validando sintaxis del chart..." -ForegroundColor Yellow
helm lint $CHART_PATH

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Lint falló" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/6] Generando templates (dry-run)..." -ForegroundColor Yellow
helm template $RELEASE_NAME $CHART_PATH `
    --values "$CHART_PATH\values-dev.yaml" `
    --debug > helm-template-output.yaml

Write-Host "Templates generados en: helm-template-output.yaml" -ForegroundColor Cyan

Write-Host "`n[3/6] Verificando cluster de Kubernetes..." -ForegroundColor Yellow
kubectl cluster-info

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se puede conectar al cluster de Kubernetes" -ForegroundColor Red
    Write-Host "Inicia Minikube o configura kubectl correctamente" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[4/6] Verificando que las imágenes existan..." -ForegroundColor Yellow
$backendImage = docker images -q entregable4devops-backend:1.0
$frontendImage = docker images -q entregable4devops-frontend:1.0

if (-not $backendImage) {
    Write-Host "ADVERTENCIA: Imagen backend no encontrada localmente" -ForegroundColor Yellow
    Write-Host "Construir con: docker-compose build" -ForegroundColor Cyan
}

if (-not $frontendImage) {
    Write-Host "ADVERTENCIA: Imagen frontend no encontrada localmente" -ForegroundColor Yellow
    Write-Host "Construir con: docker-compose build" -ForegroundColor Cyan
}

Write-Host "`n[5/6] Instalando chart en modo dry-run..." -ForegroundColor Yellow
helm install $RELEASE_NAME $CHART_PATH `
    --values "$CHART_PATH\values-dev.yaml" `
    --namespace $NAMESPACE `
    --create-namespace `
    --dry-run `
    --debug

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Instalación en dry-run falló" -ForegroundColor Red
    exit 1
}

Write-Host "`n[6/6] Validación completada exitosamente!" -ForegroundColor Green

Write-Host "`n=== Comandos de Despliegue ===" -ForegroundColor Cyan
Write-Host "Para desplegar en desarrollo:" -ForegroundColor White
Write-Host "  helm install $RELEASE_NAME $CHART_PATH --values $CHART_PATH\values-dev.yaml --namespace $NAMESPACE --create-namespace" -ForegroundColor Gray

Write-Host "`nPara verificar el despliegue:" -ForegroundColor White
Write-Host "  kubectl get all -n $NAMESPACE" -ForegroundColor Gray

Write-Host "`nPara acceder a los servicios (si usas Minikube):" -ForegroundColor White
Write-Host "  minikube service $RELEASE_NAME-frontend -n $NAMESPACE" -ForegroundColor Gray

Write-Host "`nPara desinstalar:" -ForegroundColor White
Write-Host "  helm uninstall $RELEASE_NAME -n $NAMESPACE" -ForegroundColor Gray
