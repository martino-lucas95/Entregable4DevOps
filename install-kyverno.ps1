# Script para instalar Kyverno en el cluster de Kubernetes (PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "=== Instalación de Kyverno ===" -ForegroundColor Green

# Verificar que kubectl esté disponible
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: kubectl no está instalado o no está en el PATH" -ForegroundColor Red
    exit 1
}

# Verificar que helm esté disponible
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: helm no está instalado o no está en el PATH" -ForegroundColor Red
    exit 1
}

# Verificar conexión al cluster
Write-Host "`n[1/4] Verificando conexión al cluster de Kubernetes..." -ForegroundColor Yellow
try {
    kubectl cluster-info | Out-Null
    Write-Host "✓ Conexión al cluster verificada" -ForegroundColor Green
} catch {
    Write-Host "ERROR: No se puede conectar al cluster de Kubernetes" -ForegroundColor Red
    Write-Host "Verifica que kubectl esté configurado correctamente" -ForegroundColor Yellow
    exit 1
}

# Agregar repositorio de Kyverno
Write-Host "`n[2/4] Agregando repositorio de Helm de Kyverno..." -ForegroundColor Yellow
$repoExists = helm repo list | Select-String "kyverno"
if ($repoExists) {
    Write-Host "Repositorio de Kyverno ya existe, actualizando..." -ForegroundColor Cyan
    helm repo update kyverno
} else {
    helm repo add kyverno https://kyverno.github.io/kyverno/
    helm repo update
}
Write-Host "✓ Repositorio de Kyverno agregado y actualizado" -ForegroundColor Green

# Verificar si Kyverno ya está instalado
Write-Host "`n[3/4] Verificando si Kyverno ya está instalado..." -ForegroundColor Yellow
$namespaceExists = kubectl get namespace kyverno 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "ADVERTENCIA: El namespace 'kyverno' ya existe" -ForegroundColor Yellow
    $response = Read-Host "¿Deseas continuar con la instalación/actualización? (y/n)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Instalación cancelada" -ForegroundColor Yellow
        exit 0
    }
}

# Instalar Kyverno
Write-Host "`n[4/4] Instalando Kyverno..." -ForegroundColor Yellow
helm upgrade --install kyverno kyverno/kyverno `
    --namespace kyverno `
    --create-namespace `
    --set replicaCount=1 `
    --wait `
    --timeout 5m

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: La instalación de Kyverno falló" -ForegroundColor Red
    exit 1
}

Write-Host "`n✓ Kyverno instalado exitosamente!" -ForegroundColor Green

# Verificar la instalación
Write-Host "`n=== Verificación de la Instalación ===" -ForegroundColor Green
Write-Host "Verificando pods de Kyverno..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=120s

Write-Host "`nEstado de los pods:" -ForegroundColor Cyan
kubectl get pods -n kyverno

Write-Host "`nEstado de los servicios:" -ForegroundColor Cyan
kubectl get svc -n kyverno

Write-Host "`n=== Instalación Completada ===" -ForegroundColor Green
Write-Host "Kyverno está listo para usar." -ForegroundColor Green
Write-Host ""
Write-Host "Para verificar las políticas instaladas:" -ForegroundColor Cyan
Write-Host "  kubectl get clusterpolicies" -ForegroundColor White
Write-Host ""
Write-Host "Para aplicar políticas personalizadas:" -ForegroundColor Cyan
Write-Host "  kubectl apply -f kyverno/policies/" -ForegroundColor White
