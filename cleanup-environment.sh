#!/bin/bash
# Script para limpiar todos los recursos del entorno
# Este script elimina la aplicación, operadores, políticas y todos los recursos relacionados

set -e
set -o pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuración
NAMESPACE="${NAMESPACE:-development}"
HELM_RELEASE="stock-management"
LOG_FILE="cleanup-environment.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Función para logging
log() {
    echo -e "${GREEN}[$TIMESTAMP]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$TIMESTAMP] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$TIMESTAMP] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$TIMESTAMP] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

# Función para confirmar acción destructiva
confirm_cleanup() {
    log_warning "Esta acción eliminará TODOS los recursos del proyecto:"
    log_warning "  - Aplicación desplegada con Helm"
    log_warning "  - Namespace: $NAMESPACE"
    log_warning "  - Políticas de Kyverno"
    log_warning "  - Falco"
    log_warning "  - Jenkins"
    log_warning "  - Port-forwards activos"
    log ""
    read -p "¿Estás seguro de que deseas continuar? (escribe 'yes' para confirmar): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        log "Operación cancelada"
        exit 0
    fi
}

# Función para detener port-forwards
stop_port_forwards() {
    log "=== Deteniendo Port-Forwards ==="
    
    # Detener port-forward del backend si existe
    if [ -f /tmp/backend-port-forward.pid ]; then
        local pid=$(cat /tmp/backend-port-forward.pid)
        if kill -0 $pid 2>/dev/null; then
            log "Deteniendo port-forward del backend (PID: $pid)..."
            kill $pid 2>/dev/null || true
            rm -f /tmp/backend-port-forward.pid
        fi
    fi
    
    # Buscar y detener otros port-forwards relacionados
    local pids=$(lsof -ti :30001,:30002,:9090,:3000 2>/dev/null || true)
    if [ -n "$pids" ]; then
        log "Deteniendo port-forwards activos..."
        echo "$pids" | xargs kill 2>/dev/null || true
    fi
    
    log "✓ Port-forwards detenidos"
}

# Función para desinstalar la aplicación
uninstall_application() {
    log "=== Desinstalando Aplicación ==="
    
    # Desinstalar Helm release
    if helm list -n "$NAMESPACE" | grep -q "$HELM_RELEASE"; then
        log "Desinstalando Helm release: $HELM_RELEASE"
        helm uninstall "$HELM_RELEASE" -n "$NAMESPACE" >> "$LOG_FILE" 2>&1 || {
            log_warning "Error al desinstalar Helm release, continuando..."
        }
        log "✓ Helm release desinstalado"
    else
        log_info "Helm release no encontrado, saltando..."
    fi
    
    # Eliminar namespace (esto eliminará todos los recursos dentro)
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log "Eliminando namespace: $NAMESPACE"
        kubectl delete namespace "$NAMESPACE" --timeout=5m >> "$LOG_FILE" 2>&1 || {
            log_warning "Error al eliminar namespace, puede que algunos recursos aún existan"
        }
        log "✓ Namespace eliminado"
    else
        log_info "Namespace no encontrado, saltando..."
    fi
}

# Función para eliminar políticas de Kyverno
remove_kyverno_policies() {
    log "=== Eliminando Políticas de Kyverno ==="
    
    # Eliminar políticas de cluster
    local policies=("disallow-latest-tag" "require-resource-limits" "disallow-root-containers" "require-labels")
    
    for policy in "${policies[@]}"; do
        if kubectl get clusterpolicy "$policy" &> /dev/null; then
            log "Eliminando ClusterPolicy: $policy"
            kubectl delete clusterpolicy "$policy" >> "$LOG_FILE" 2>&1 || true
        fi
    done
    
    # Eliminar PolicyException si existe
    if kubectl get policyexception falco-exception -n falco &> /dev/null 2>&1; then
        log "Eliminando PolicyException: falco-exception"
        kubectl delete policyexception falco-exception -n falco >> "$LOG_FILE" 2>&1 || true
    fi
    
    log "✓ Políticas de Kyverno eliminadas"
}

# Función para desinstalar Falco
uninstall_falco() {
    log "=== Desinstalando Falco ==="
    
    if helm list -n falco | grep -q falco; then
        log "Desinstalando Falco..."
        helm uninstall falco -n falco >> "$LOG_FILE" 2>&1 || {
            log_warning "Error al desinstalar Falco"
        }
        
        # Eliminar namespace de Falco
        if kubectl get namespace falco &> /dev/null; then
            kubectl delete namespace falco --timeout=2m >> "$LOG_FILE" 2>&1 || true
        fi
        
        log "✓ Falco desinstalado"
    else
        log_info "Falco no está instalado, saltando..."
    fi
}

# Función para desinstalar Kyverno
uninstall_kyverno() {
    log "=== Desinstalando Kyverno ==="
    
    if helm list -n kyverno | grep -q kyverno; then
        log "Desinstalando Kyverno..."
        helm uninstall kyverno -n kyverno >> "$LOG_FILE" 2>&1 || {
            log_warning "Error al desinstalar Kyverno"
        }
        
        # Eliminar namespace de Kyverno
        if kubectl get namespace kyverno &> /dev/null; then
            kubectl delete namespace kyverno --timeout=2m >> "$LOG_FILE" 2>&1 || true
        fi
        
        log "✓ Kyverno desinstalado"
    else
        log_info "Kyverno no está instalado, saltando..."
    fi
}

# Función para desinstalar Jenkins
uninstall_jenkins() {
    log "=== Desinstalando Jenkins ==="
    
    if helm list -n jenkins | grep -q jenkins; then
        log "Desinstalando Jenkins..."
        helm uninstall jenkins -n jenkins >> "$LOG_FILE" 2>&1 || {
            log_warning "Error al desinstalar Jenkins"
        }
        
        # Eliminar namespace de Jenkins
        if kubectl get namespace jenkins &> /dev/null; then
            kubectl delete namespace jenkins --timeout=2m >> "$LOG_FILE" 2>&1 || true
        fi
        
        log "✓ Jenkins desinstalado"
    else
        log_info "Jenkins no está instalado, saltando..."
    fi
}

# Función para limpiar imágenes Docker locales (opcional)
cleanup_docker_images() {
    log "=== Limpiando Imágenes Docker Locales (Opcional) ==="
    
    read -p "¿Deseas eliminar las imágenes Docker locales del proyecto? (y/n): " cleanup_images
    
    if [ "$cleanup_images" = "y" ] || [ "$cleanup_images" = "Y" ]; then
        log "Eliminando imágenes Docker..."
        docker rmi entregable4devops-backend:1.0 entregable4devops-frontend:1.0 2>/dev/null || {
            log_warning "Algunas imágenes no se pudieron eliminar (pueden estar en uso)"
        }
        log "✓ Imágenes Docker eliminadas"
    else
        log_info "Imágenes Docker conservadas"
    fi
}

# Función principal
main() {
    log "=========================================="
    log "Limpieza Completa del Entorno"
    log "=========================================="
    log ""
    
    confirm_cleanup
    
    stop_port_forwards
    uninstall_application
    remove_kyverno_policies
    uninstall_falco
    uninstall_kyverno
    uninstall_jenkins
    cleanup_docker_images
    
    log ""
    log "=========================================="
    log "✓ Limpieza Completada"
    log "=========================================="
    log ""
    log "Recursos eliminados:"
    log "  ✓ Aplicación y namespace $NAMESPACE"
    log "  ✓ Políticas de Kyverno"
    log "  ✓ Falco"
    log "  ✓ Kyverno"
    log "  ✓ Jenkins"
    log "  ✓ Port-forwards"
    log ""
    log "Para volver a inicializar el entorno, ejecuta:"
    log "  ./setup-environment.sh"
    log ""
    log "Log completo guardado en: $LOG_FILE"
}

# Ejecutar función principal
main "$@"

