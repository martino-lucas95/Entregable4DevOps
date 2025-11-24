#!/bin/bash
# Script para aplicar todas las políticas de Kyverno

set -e

echo "=== Aplicando Políticas de Kyverno ==="

# Verificar que kubectl esté disponible
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl no está instalado o no está en el PATH"
    exit 1
fi

# Verificar que Kyverno esté instalado
echo -e "\n[1/3] Verificando que Kyverno esté instalado..."
if ! kubectl get namespace kyverno &> /dev/null; then
    echo "ERROR: Kyverno no está instalado. Ejecuta primero: ./install-kyverno.sh"
    exit 1
fi

# Verificar que los pods de Kyverno estén listos
if ! kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=30s &> /dev/null; then
    echo "ADVERTENCIA: Los pods de Kyverno no están listos. Continuando de todas formas..."
fi

# Aplicar políticas
echo -e "\n[2/3] Aplicando políticas de Kyverno..."
POLICIES_DIR="kyverno/policies"

if [ ! -d "$POLICIES_DIR" ]; then
    echo "ERROR: Directorio de políticas no encontrado: $POLICIES_DIR"
    exit 1
fi

for policy in "$POLICIES_DIR"/*.yaml; do
    if [ -f "$policy" ]; then
        echo "  Aplicando: $(basename $policy)"
        kubectl apply -f "$policy"
    fi
done

# Verificar políticas aplicadas
echo -e "\n[3/3] Verificando políticas aplicadas..."
echo ""
echo "Políticas ClusterPolicy instaladas:"
kubectl get clusterpolicies

echo -e "\n✓ Políticas aplicadas exitosamente!"
echo ""
echo "Para ver detalles de una política:"
echo "  kubectl describe clusterpolicy <nombre-politica>"
echo ""
echo "Para ver eventos de políticas:"
echo "  kubectl get events -n kyverno --sort-by='.lastTimestamp'"

