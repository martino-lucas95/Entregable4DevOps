#!/bin/bash
# Script para popular dashboards con datos mediante requests automáticos a la aplicación
# Este script crea productos y movimientos de stock para generar métricas y popular Grafana

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
LOG_FILE="populate-dashboards.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Función para logging
log() {
    echo -e "${GREEN}[$TIMESTAMP]${NC} $1" | tee -a "$LOG_FILE" >&2
}

log_error() {
    echo -e "${RED}[$TIMESTAMP] ERROR:${NC} $1" | tee -a "$LOG_FILE" >&2
}

log_info() {
    echo -e "${BLUE}[$TIMESTAMP] INFO:${NC} $1" | tee -a "$LOG_FILE" >&2
}

# Función para obtener el puerto del backend
get_backend_port() {
    kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/component=backend -o jsonpath='{.items[0].spec.ports[0].nodePort}' 2>/dev/null || echo ""
}

# Función para esperar a que el backend esté listo
wait_for_backend() {
    log "Esperando a que el backend esté listo..."
    
    local max_attempts=30
    local attempt=1
    local backend_port=$(get_backend_port)
    
    if [ -z "$backend_port" ]; then
        log_error "No se pudo obtener el puerto del backend"
        return 1
    fi
    
    while [ $attempt -le $max_attempts ]; do
        # Intentar diferentes endpoints de health check
        if curl -s -f "http://localhost:$backend_port/products" > /dev/null 2>&1 || \
           curl -s -f "http://localhost:$backend_port/health" > /dev/null 2>&1 || \
           curl -s -f "http://localhost:$backend_port/api/health" > /dev/null 2>&1; then
            log "✓ Backend está listo en puerto $backend_port"
            return 0
        fi
        
        log_info "Intento $attempt/$max_attempts: Backend aún no está listo, esperando..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    log_error "Backend no está disponible después de $max_attempts intentos"
    return 1
}

# Función para hacer port-forward del backend
setup_port_forward() {
    log "Configurando port-forward para el backend..."
    
    local backend_port=$(get_backend_port)
    if [ -z "$backend_port" ]; then
        log_error "No se pudo obtener el puerto del backend"
        return 1
    fi
    
    # Verificar si ya hay un port-forward activo
    if lsof -Pi :$backend_port -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_info "Port-forward ya está activo en puerto $backend_port"
        return 0
    fi
    
    # Iniciar port-forward en background
    log "Iniciando port-forward: kubectl port-forward svc/$HELM_RELEASE-backend $backend_port:3000 -n $NAMESPACE"
    kubectl port-forward svc/$HELM_RELEASE-backend $backend_port:3000 -n "$NAMESPACE" >> "$LOG_FILE" 2>&1 &
    local pf_pid=$!
    
    # Esperar un momento para que el port-forward se establezca
    sleep 3
    
    # Verificar que el port-forward esté funcionando
    if kill -0 $pf_pid 2>/dev/null; then
        log "✓ Port-forward iniciado (PID: $pf_pid)"
        echo $pf_pid > /tmp/backend-port-forward.pid
        return 0
    else
        log_error "Error al iniciar port-forward"
        return 1
    fi
}

# Función para crear un producto
create_product() {
    local name=$1
    local cost=$2
    local price=$3
    local barcode=$4
    local backend_port=$(get_backend_port)
    
    log_info "Creando producto: $name"
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:$backend_port/products" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$name\",
            \"cost\": $cost,
            \"price\": $price,
            \"barcode\": \"$barcode\"
        }" 2>> "$LOG_FILE")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 201 ] || [ "$http_code" -eq 200 ]; then
        local product_id=$(echo "$body" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
        log "✓ Producto creado: ID=$product_id, Name=$name"
        echo "$product_id"
    else
        log_error "Error al crear producto $name: HTTP $http_code"
        echo "$body" >> "$LOG_FILE"
        echo ""
    fi
}

# Función para crear un movimiento de stock
create_movement() {
    local product_id=$1
    local movement_type=$2
    local quantity=$3
    local backend_port=$(get_backend_port)
    
    log_info "Creando movimiento: Producto ID=$product_id, Tipo=$movement_type, Cantidad=$quantity"
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:$backend_port/movements" \
        -H "Content-Type: application/json" \
        -d "{
            \"productId\": $product_id,
            \"type\": \"$movement_type\",
            \"quantity\": $quantity
        }" 2>> "$LOG_FILE")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 201 ] || [ "$http_code" -eq 200 ]; then
        log "✓ Movimiento creado: Producto ID=$product_id, Tipo=$movement_type, Cantidad=$quantity"
        return 0
    else
        log_error "Error al crear movimiento: HTTP $http_code"
        echo "$body" >> "$LOG_FILE"
        return 1
    fi
}

# Función para hacer requests de lectura (para generar métricas HTTP)
make_read_requests() {
    local backend_port=$(get_backend_port)
    local num_requests=${1:-10}
    
    log "Generando $num_requests requests de lectura para popular métricas..."
    
    for i in $(seq 1 $num_requests); do
        # Obtener productos
        curl -s "http://localhost:$backend_port/products" > /dev/null 2>&1
        
        # Obtener stock
        curl -s "http://localhost:$backend_port/stock" > /dev/null 2>&1
        
        # Obtener movimientos
        curl -s "http://localhost:$backend_port/movements" > /dev/null 2>&1
        
        if [ $((i % 5)) -eq 0 ]; then
            log_info "  $i/$num_requests requests completadas..."
        fi
        
        sleep 0.5
    done
    
    log "✓ Requests de lectura completadas"
}

# Función para popular datos
populate_data() {
    log "=== Populando Datos en la Aplicación ==="
    
    # Crear productos
    log "Creando productos..."
    local product1_id=$(create_product "Laptop Dell XPS 15" 1200.00 1599.99 "LAP001")
    local product2_id=$(create_product "Mouse Logitech MX Master" 79.99 99.99 "MOU001")
    local product3_id=$(create_product "Teclado Mecánico Keychron" 89.99 129.99 "KEY001")
    local product4_id=$(create_product "Monitor LG 27 pulgadas" 299.99 399.99 "MON001")
    local product5_id=$(create_product "Webcam Logitech C920" 69.99 89.99 "WEB001")
    
    # Esperar un momento para que los productos se guarden
    sleep 2
    
    # Crear movimientos de entrada (IN)
    log "Creando movimientos de entrada (IN)..."
    if [ -n "$product1_id" ]; then
        create_movement "$product1_id" "IN" 10
        create_movement "$product1_id" "IN" 5
    fi
    if [ -n "$product2_id" ]; then
        create_movement "$product2_id" "IN" 25
        create_movement "$product2_id" "IN" 15
    fi
    if [ -n "$product3_id" ]; then
        create_movement "$product3_id" "IN" 20
    fi
    if [ -n "$product4_id" ]; then
        create_movement "$product4_id" "IN" 8
        create_movement "$product4_id" "IN" 4
    fi
    if [ -n "$product5_id" ]; then
        create_movement "$product5_id" "IN" 30
    fi
    
    sleep 2
    
    # Crear movimientos de salida (OUT)
    log "Creando movimientos de salida (OUT)..."
    if [ -n "$product1_id" ]; then
        create_movement "$product1_id" "OUT" 3
        create_movement "$product1_id" "OUT" 2
    fi
    if [ -n "$product2_id" ]; then
        create_movement "$product2_id" "OUT" 10
        create_movement "$product2_id" "OUT" 5
    fi
    if [ -n "$product3_id" ]; then
        create_movement "$product3_id" "OUT" 8
    fi
    if [ -n "$product4_id" ]; then
        create_movement "$product4_id" "OUT" 2
    fi
    if [ -n "$product5_id" ]; then
        create_movement "$product5_id" "OUT" 12
        create_movement "$product5_id" "OUT" 8
    fi
    
    log "✓ Datos populados exitosamente"
}

# Función para generar tráfico continuo
generate_traffic() {
    local duration=${1:-60}  # Duración en segundos, default 60
    local interval=${2:-2}   # Intervalo entre requests en segundos, default 2
    
    log "Generando tráfico continuo por $duration segundos (intervalo: $interval segundos)..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local request_count=0
    
    while [ $(date +%s) -lt $end_time ]; do
        make_read_requests 1
        request_count=$((request_count + 1))
        sleep $interval
    done
    
    log "✓ Tráfico generado: $request_count requests en $duration segundos"
}

# Función para limpiar port-forward
cleanup_port_forward() {
    if [ -f /tmp/backend-port-forward.pid ]; then
        local pid=$(cat /tmp/backend-port-forward.pid)
        if kill -0 $pid 2>/dev/null; then
            log "Deteniendo port-forward (PID: $pid)..."
            kill $pid 2>/dev/null || true
            rm -f /tmp/backend-port-forward.pid
        fi
    fi
}

# Función principal
main() {
    log "=========================================="
    log "Populando Dashboards con Datos"
    log "=========================================="
    log ""
    
    # Verificar que el backend esté disponible
    local backend_port=$(get_backend_port)
    if [ -z "$backend_port" ]; then
        log_error "No se pudo encontrar el servicio del backend"
        log_error "Asegúrate de que la aplicación esté desplegada: ./setup-environment.sh"
        exit 1
    fi
    
    # Configurar port-forward si es necesario
    if ! curl -s -f "http://localhost:$backend_port/products" > /dev/null 2>&1 && \
       ! curl -s -f "http://localhost:$backend_port/health" > /dev/null 2>&1 && \
       ! curl -s -f "http://localhost:$backend_port/api/health" > /dev/null 2>&1; then
        setup_port_forward
        wait_for_backend
    else
        log "Backend ya está accesible en puerto $backend_port"
    fi
    
    # Popular datos
    populate_data
    
    # Generar tráfico para popular métricas
    log ""
    log "=== Generando Tráfico para Métricas ==="
    make_read_requests 20
    
    # Generar tráfico continuo (opcional, comentado por defecto)
    # log ""
    # log "=== Generando Tráfico Continuo ==="
    # generate_traffic 120 3  # 120 segundos, 1 request cada 3 segundos
    
    log ""
    log "=========================================="
    log "✓ Dashboards Populados"
    log "=========================================="
    log ""
    log "Los dashboards de Grafana ahora deberían mostrar:"
    log "  - Productos en inventario"
    log "  - Movimientos de stock (IN/OUT)"
    log "  - Métricas HTTP (requests, latencia)"
    log "  - Métricas de CPU y memoria"
    log ""
    log "Accede a Grafana para ver los dashboards:"
    log "  kubectl port-forward svc/$HELM_RELEASE-grafana 3000:80 -n $NAMESPACE"
    log ""
    log "Log completo guardado en: $LOG_FILE"
    
    # No limpiar port-forward automáticamente, dejar que el usuario lo haga manualmente
    # cleanup_port_forward
}

# Trap para limpiar port-forward al salir
trap cleanup_port_forward EXIT

# Ejecutar función principal
main "$@"

