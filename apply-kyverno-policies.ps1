# Script para aplicar todas las políticas de Kyverno (PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "=== Aplicando Políticas de Kyverno ===" -ForegroundColor Green

# Verificar que kubectl esté disponible
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: kubectl no está instalado o no está en el PATH" -ForegroundColor Red
    exit 1
}

# Verificar que Kyverno esté instalado
Write-Host "`n[1/3] Verificando que Kyverno esté instalado..." -ForegroundColor Yellow
$namespaceExists = kubectl get namespace kyverno 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Kyverno no está instalado. Ejecuta primero: .\install-kyverno.ps1" -ForegroundColor Red
    exit 1
}

# Verificar que los pods de Kyverno estén listos
try {
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=30s | Out-Null
} catch {
    Write-Host "ADVERTENCIA: Los pods de Kyverno no están listos. Continuando de todas formas..." -ForegroundColor Yellow
}

# Aplicar políticas
Write-Host "`n[2/3] Aplicando políticas de Kyverno..." -ForegroundColor Yellow
$POLICIES_DIR = "kyverno\policies"

if (-not (Test-Path $POLICIES_DIR)) {
    Write-Host "ERROR: Directorio de políticas no encontrado: $POLICIES_DIR" -ForegroundColor Red
    exit 1
}

Get-ChildItem -Path $POLICIES_DIR -Filter "*.yaml" | ForEach-Object {
    Write-Host "  Aplicando: $($_.Name)" -ForegroundColor Cyan
    kubectl apply -f $_.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Falló al aplicar $($_.Name)" -ForegroundColor Red
        exit 1
    }
}

# Verificar políticas aplicadas
Write-Host "`n[3/3] Verificando políticas aplicadas..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Políticas ClusterPolicy instaladas:" -ForegroundColor Cyan
kubectl get clusterpolicies

Write-Host "`n✓ Políticas aplicadas exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "Para ver detalles de una política:" -ForegroundColor Cyan
Write-Host "  kubectl describe clusterpolicy <nombre-politica>" -ForegroundColor White
Write-Host ""
Write-Host "Para ver eventos de políticas:" -ForegroundColor Cyan
Write-Host "  kubectl get events -n kyverno --sort-by='.lastTimestamp'" -ForegroundColor White

