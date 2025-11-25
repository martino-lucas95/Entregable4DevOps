# Script para instalar Falco en el cluster de Kubernetes (PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "=== Instalación de Falco ===" -ForegroundColor Green

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

# Agregar repositorio de Falco
Write-Host "`n[2/4] Agregando repositorio de Helm de Falco..." -ForegroundColor Yellow
$repoExists = helm repo list | Select-String "falcosecurity"
if ($repoExists) {
    Write-Host "Repositorio de Falco ya existe, actualizando..." -ForegroundColor Cyan
    helm repo update falcosecurity
} else {
    helm repo add falcosecurity https://falcosecurity.github.io/charts
    helm repo update
}
Write-Host "✓ Repositorio de Falco agregado y actualizado" -ForegroundColor Green

# Verificar si Falco ya está instalado
Write-Host "`n[3/4] Verificando si Falco ya está instalado..." -ForegroundColor Yellow
$namespaceExists = kubectl get namespace falco 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "ADVERTENCIA: El namespace 'falco' ya existe" -ForegroundColor Yellow
    $response = Read-Host "¿Deseas continuar con la instalación/actualización? (y/n)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Instalación cancelada" -ForegroundColor Yellow
        exit 0
    }
}

# Instalar Falco
Write-Host "`n[4/4] Instalando Falco..." -ForegroundColor Yellow
helm upgrade --install falco falcosecurity/falco `
    --namespace falco `
    --create-namespace `
    --set driver.enabled=true `
    --set driver.loader.enabled=false `
    --set falcosidekick.enabled=true `
    --set falcosidekick.webui.enabled=true `
    --wait `
    --timeout 5m

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: La instalación de Falco falló" -ForegroundColor Red
    exit 1
}

Write-Host "`n✓ Falco instalado exitosamente!" -ForegroundColor Green

# Verificar la instalación
Write-Host "`n=== Verificación de la Instalación ===" -ForegroundColor Green
Write-Host "Verificando pods de Falco..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=falco -n falco --timeout=120s

Write-Host "`nEstado de los pods:" -ForegroundColor Cyan
kubectl get pods -n falco

Write-Host "`nEstado de los servicios:" -ForegroundColor Cyan
kubectl get svc -n falco

Write-Host "`n=== Instalación Completada ===" -ForegroundColor Green
Write-Host "Falco está listo para monitorear eventos de seguridad." -ForegroundColor Green
Write-Host ""
Write-Host "Para ver eventos de Falco:" -ForegroundColor Cyan
Write-Host "  kubectl logs -f -l app.kubernetes.io/name=falco -n falco" -ForegroundColor White
Write-Host ""
Write-Host "Para ver eventos en Falco Sidekick:" -ForegroundColor Cyan
Write-Host "  kubectl logs -f -l app.kubernetes.io/name=falcosidekick -n falco" -ForegroundColor White

