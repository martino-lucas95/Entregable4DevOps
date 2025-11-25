#!/bin/bash
# Script principal para inicializar todo el entorno del proyecto
# Este script instala operadores, despliega componentes y configura el entorno completo

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
LOG_FILE="setup-environment.log"
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

# Función para verificar prerequisitos
check_prerequisites() {
    log "Verificando prerequisitos..."
    
    local missing_tools=()
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Herramientas faltantes: ${missing_tools[*]}"
        log_error "Por favor instala las herramientas faltantes antes de continuar"
        exit 1
    fi
    
    # Verificar conexión al cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "No se puede conectar al cluster de Kubernetes"
        log_error "Asegúrate de que el cluster esté corriendo (minikube start, etc.)"
        exit 1
    fi
    
    log "✓ Todos los prerequisitos están disponibles"
}

# Función para instalar operadores de Kubernetes
install_operators() {
    log "=== Instalando Operadores de Kubernetes ==="
    
    # Nota: En este proyecto usamos deployments directos en lugar de operadores
    # para Prometheus y Grafana. Si necesitas Prometheus Operator, descomenta:
    # 
    # log "Instalando Prometheus Operator..."
    # helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    # helm repo update
    # helm install prometheus prometheus-community/kube-prometheus-stack \
    #     --namespace monitoring \
    #     --create-namespace \
    #     --wait
    
    log "No se requieren operadores adicionales (usando deployments directos)"
    log "✓ Operadores verificados"
}

# Función para construir imágenes Docker
build_images() {
    log "=== Construyendo Imágenes Docker ==="
    
    log "Construyendo imagen del backend..."
    docker build -t entregable4devops-backend:1.0 ./backend || {
        log_error "Error al construir imagen del backend"
        exit 1
    }
    
    log "Construyendo imagen del frontend..."
    docker build -t entregable4devops-frontend:1.0 ./frontend || {
        log_error "Error al construir imagen del frontend"
        exit 1
    }
    
    log "✓ Imágenes construidas exitosamente"
    
    # Mostrar imágenes construidas
    log_info "Imágenes disponibles:"
    docker images | grep entregable4devops | tee -a "$LOG_FILE"
}

# Función para instalar Kyverno
install_kyverno() {
    log "=== Instalando Kyverno ==="
    
    if [ -f "./install-kyverno.sh" ]; then
        ./install-kyverno.sh >> "$LOG_FILE" 2>&1 || {
            log_warning "Kyverno puede estar ya instalado o hubo un error"
        }
        log "✓ Kyverno instalado/verificado"
    else
        log_warning "Script install-kyverno.sh no encontrado, saltando instalación de Kyverno"
    fi
}

# Función para aplicar políticas de Kyverno
apply_kyverno_policies() {
    log "=== Aplicando Políticas de Kyverno ==="
    
    if [ -f "./apply-kyverno-policies.sh" ]; then
        ./apply-kyverno-policies.sh >> "$LOG_FILE" 2>&1 || {
            log_warning "Error al aplicar políticas de Kyverno"
        }
        log "✓ Políticas de Kyverno aplicadas"
    else
        log_warning "Script apply-kyverno-policies.sh no encontrado"
    fi
}

# Función para instalar Falco
install_falco() {
    log "=== Instalando Falco ==="
    
    if [ -f "./install-falco.sh" ]; then
        echo "y" | ./install-falco.sh >> "$LOG_FILE" 2>&1 || {
            log_warning "Falco puede estar ya instalado o hubo un error"
        }
        log "✓ Falco instalado/verificado"
    else
        log_warning "Script install-falco.sh no encontrado, saltando instalación de Falco"
    fi
}

# Función para desplegar la aplicación
deploy_application() {
    log "=== Desplegando Aplicación con Helm ==="
    
    # Crear namespace si no existe
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >> "$LOG_FILE" 2>&1
    
    # Actualizar dependencias de Helm
    log "Actualizando dependencias de Helm..."
    helm dependency update ./helm-chart >> "$LOG_FILE" 2>&1 || true
    
    # Desplegar aplicación
    log "Desplegando aplicación en namespace: $NAMESPACE"
    helm upgrade --install "$HELM_RELEASE" ./helm-chart \
        --namespace "$NAMESPACE" \
        --values ./helm-chart/values-dev.yaml \
        --set backend.image.tag=1.0 \
        --set frontend.image.tag=1.0 \
        --wait \
        --timeout 10m >> "$LOG_FILE" 2>&1 || {
        log_error "Error al desplegar la aplicación"
        exit 1
    }
    
    log "✓ Aplicación desplegada exitosamente"
    
    # Esperar a que los pods estén listos
    log "Esperando a que todos los pods estén listos..."
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/instance="$HELM_RELEASE" \
        -n "$NAMESPACE" \
        --timeout=300s >> "$LOG_FILE" 2>&1 || {
        log_warning "Algunos pods pueden no estar listos todavía"
    }
    
    # Mostrar estado de los pods
    log_info "Estado de los pods:"
    kubectl get pods -n "$NAMESPACE" | tee -a "$LOG_FILE"
}

# Función para verificar servicios
verify_services() {
    log "=== Verificando Servicios ==="
    
    log_info "Servicios desplegados:"
    kubectl get svc -n "$NAMESPACE" | tee -a "$LOG_FILE"
    
    # Obtener URLs de acceso
    log_info "URLs de acceso:"
    
    # Backend
    BACKEND_PORT=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/component=backend -o jsonpath='{.items[0].spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
    if [ "$BACKEND_PORT" != "N/A" ]; then
        log "  Backend API: http://localhost:$BACKEND_PORT"
    fi
    
    # Frontend
    FRONTEND_PORT=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/component=frontend -o jsonpath='{.items[0].spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
    if [ "$FRONTEND_PORT" != "N/A" ]; then
        log "  Frontend: http://localhost:$FRONTEND_PORT"
    fi
    
    # Grafana
    GRAFANA_PORT=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/component=grafana -o jsonpath='{.items[0].spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
    if [ "$GRAFANA_PORT" != "N/A" ]; then
        log "  Grafana: http://localhost:$GRAFANA_PORT (admin/admin)"
    fi
    
    # Prometheus
    log "  Prometheus: kubectl port-forward svc/$HELM_RELEASE-prometheus 9090:9090 -n $NAMESPACE"
}

# Función principal
main() {
    log "=========================================="
    log "Inicialización del Entorno Completo"
    log "=========================================="
    log ""
    
    check_prerequisites
    install_operators
    build_images
    install_kyverno
    apply_kyverno_policies
    install_falco
    deploy_application
    verify_services
    
    log ""
    log "=========================================="
    log "✓ Inicialización Completada"
    log "=========================================="
    log ""
    log "Próximos pasos:"
    log "1. Ejecuta './populate-dashboards.sh' para generar datos y popular dashboards"
    log "2. Accede a Grafana para ver las métricas"
    log "3. Usa './cleanup-environment.sh' para limpiar todos los recursos"
    log ""
    log "Log completo guardado en: $LOG_FILE"
}

# Ejecutar función principal
main "$@"

