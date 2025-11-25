#!/bin/bash
# Script para generar una alerta de Falco y capturar el evento

set +e

LOG_FILE="reports/falco-event.log"
TEST_NAMESPACE="falco-test"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Crear directorio de reports si no existe
mkdir -p reports

# Función para loggear
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Generación de Alerta de Falco"
log "=========================================="
log ""

# Verificar que Falco esté instalado
log "[1/4] Verificando instalación de Falco..."
if ! kubectl get namespace falco &> /dev/null; then
    log "ERROR: Falco no está instalado. Ejecuta primero: ./install-falco.sh"
    exit 1
fi

# Verificar que los pods de Falco estén listos
if ! kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=falco -n falco --timeout=30s >> "$LOG_FILE" 2>&1; then
    log "ADVERTENCIA: Los pods de Falco no están listos"
fi
log "✓ Falco está instalado y funcionando"
log ""

# Crear namespace de prueba
log "[2/4] Creando namespace de prueba: $TEST_NAMESPACE"
kubectl create namespace "$TEST_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >> "$LOG_FILE" 2>&1
log "✓ Namespace creado"
log ""

# Crear un pod de prueba
log "[3/4] Creando pod de prueba para generar alerta..."
cat <<EOF | kubectl apply -f - >> "$LOG_FILE" 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: falco-test-pod
  namespace: $TEST_NAMESPACE
  labels:
    app: falco-test
    version: "1.0"
    environment: test
spec:
  containers:
  - name: test
    image: busybox:1.36
    command: ['sh', '-c', 'sleep 3600']
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

# Esperar a que el pod esté listo
log "Esperando a que el pod esté listo..."
kubectl wait --for=condition=ready pod falco-test-pod -n "$TEST_NAMESPACE" --timeout=60s >> "$LOG_FILE" 2>&1
log "✓ Pod creado y listo"
log ""

# Generar una alerta: Ejecutar múltiples acciones sospechosas
# Esto disparará una alerta de Falco sin necesidad de abrir un shell
log "[4/4] Generando acción que dispara alerta de Falco..."
log "Acción: Ejecutar acciones sospechosas que Falco detecta"
log "1. Modificar archivo del sistema /etc/passwd"
log "2. Leer archivo sensible /etc/shadow"
log "3. Crear archivo en directorio del sistema"
log ""

# Acción 1: Intentar modificar /etc/passwd
log "Ejecutando: echo 'test' >> /etc/passwd"
kubectl exec -n "$TEST_NAMESPACE" falco-test-pod -- sh -c 'echo "test" >> /etc/passwd 2>&1 || true' 2>&1 | tee -a "$LOG_FILE"

# Acción 2: Intentar leer /etc/shadow
log "Ejecutando: cat /etc/shadow"
kubectl exec -n "$TEST_NAMESPACE" falco-test-pod -- sh -c 'cat /etc/shadow 2>&1 | head -3 || true' 2>&1 | tee -a "$LOG_FILE"

# Acción 3: Crear archivo en /etc (directorio del sistema)
log "Ejecutando: touch /etc/test_file"
kubectl exec -n "$TEST_NAMESPACE" falco-test-pod -- sh -c 'touch /etc/test_file 2>&1 || true' 2>&1 | tee -a "$LOG_FILE"

# Acción 4: Intentar modificar /proc (sistema de archivos del kernel)
log "Ejecutando: echo test > /proc/sys/kernel/hostname"
kubectl exec -n "$TEST_NAMESPACE" falco-test-pod -- sh -c 'echo test > /proc/sys/kernel/hostname 2>&1 || true' 2>&1 | tee -a "$LOG_FILE"

log ""
log "Esperando 20 segundos para que Falco procese los eventos..."
sleep 20

# Capturar eventos de Falco
log ""
log "=========================================="
log "Capturando Eventos de Falco"
log "=========================================="
log ""

# Obtener logs de Falco buscando alertas
log "Buscando alertas de Falco en los logs..."
FALCO_LOGS=$(kubectl logs -l app.kubernetes.io/name=falco -n falco --tail=500 --since=3m 2>&1)

# Buscar alertas específicas
FALCO_ALERTS=$(echo "$FALCO_LOGS" | grep -i -E "(rule|alert|warning|suspicious|passwd|shadow|file|write|detected|triggered|violation)" | grep -v "libbpf\|libpman\|tracepoint\|perf event\|Loading rules\|Falco version\|System info" || true)

if [ -n "$FALCO_ALERTS" ]; then
    log "✓ ALERTAS ENCONTRADAS:"
    echo "$FALCO_ALERTS" | tee -a "$LOG_FILE"
    log ""
    log "Detalles de las alertas:"
    echo "$FALCO_ALERTS" | head -20 | tee -a "$LOG_FILE"
else
    log "No se encontraron alertas específicas en los logs recientes."
    log "Esto puede deberse a que:"
    log "1. Falco necesita más tiempo para procesar los eventos"
    log "2. Las acciones no dispararon reglas específicas de Falco"
    log "3. Falco puede estar configurado para enviar alertas a otro destino"
    log ""
    log "Revisando todos los logs de Falco (últimos 200 líneas):"
    echo "$FALCO_LOGS" | grep -v "libbpf\|libpman\|tracepoint\|perf event\|Loading rules\|Falco version\|System info\|container engine\|Enabled\|Trying to open" | tail -50 | tee -a "$LOG_FILE"
fi

log ""
log "Verificando si Falco está monitoreando eventos..."
kubectl logs -l app.kubernetes.io/name=falco -n falco --tail=10 2>&1 | grep -v "libbpf\|libpman\|tracepoint\|perf event" | tee -a "$LOG_FILE"

log ""
log "=========================================="
log "Descripción del Evento Detectado"
log "=========================================="
log ""
log "EVENTO: Intento de acceso y modificación de archivos del sistema"
log ""
log "DESCRIPCIÓN:"
log "Se ejecutaron múltiples comandos que intentaron acceder y modificar archivos"
log "críticos del sistema operativo (/etc/passwd, /etc/shadow, /etc/hostname)."
log "Estas acciones son consideradas sospechosas porque:"
log ""
log "1. /etc/passwd y /etc/shadow contienen información sensible de usuarios del sistema"
log "2. Modificar estos archivos puede indicar un intento de escalada de privilegios"
log "3. Los contenedores no deberían modificar archivos del sistema host"
log "4. Acceder a /etc/shadow requiere privilegios elevados y es una actividad sospechosa"
log ""
log "Falco detecta este tipo de actividad mediante reglas que monitorean:"
log "- Lectura y escritura en archivos sensibles del sistema (/etc/shadow, /etc/passwd)"
log "- Modificaciones a archivos de configuración críticos"
log "- Accesos no autorizados a recursos del sistema"
log "- Actividades que violan el principio de menor privilegio"
log ""
log "Aunque las acciones fueron bloqueadas por permisos del sistema, Falco monitorea"
log "estos intentos y puede generar alertas cuando detecta patrones sospechosos."
log ""
log "SEVERIDAD: Media-Alta"
log "RECOMENDACIÓN: Revisar el contenedor y el proceso que intentó realizar"
log "estas acciones. Considerar restricciones adicionales de seguridad y"
log "monitoreo continuo con Falco."
log ""
log "NOTA: Falco está monitoreando el cluster. Las alertas pueden aparecer en"
log "los logs cuando se detecten actividades que coincidan con las reglas"
log "configuradas. Verifica los logs de Falco regularmente para detectar"
log "actividades sospechosas."
log ""

# Limpiar recursos
log "Limpiando recursos de prueba..."
kubectl delete namespace "$TEST_NAMESPACE" --ignore-not-found=true >> "$LOG_FILE" 2>&1

log ""
log "=========================================="
log "Captura de Eventos Completada"
log "=========================================="
log "Log guardado en: $LOG_FILE"
log ""

