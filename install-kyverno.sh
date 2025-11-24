#!/bin/bash
# Script para instalar Kyverno en el cluster de Kubernetes

set -e

echo "=== Instalación de Kyverno ==="

# Verificar que kubectl esté disponible
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl no está instalado o no está en el PATH"
    exit 1
fi

# Verificar que helm esté disponible
if ! command -v helm &> /dev/null; then
    echo "ERROR: helm no está instalado o no está en el PATH"
    exit 1
fi

# Verificar conexión al cluster
echo -e "\n[1/4] Verificando conexión al cluster de Kubernetes..."
if ! kubectl cluster-info &> /dev/null; then
    echo "ERROR: No se puede conectar al cluster de Kubernetes"
    echo "Verifica que kubectl esté configurado correctamente"
    exit 1
fi
echo "✓ Conexión al cluster verificada"

# Agregar repositorio de Kyverno
echo -e "\n[2/4] Agregando repositorio de Helm de Kyverno..."
if helm repo list | grep -q "kyverno"; then
    echo "Repositorio de Kyverno ya existe, actualizando..."
    helm repo update kyverno
else
    helm repo add kyverno https://kyverno.github.io/kyverno/
    helm repo update
fi
echo "✓ Repositorio de Kyverno agregado y actualizado"

# Verificar si Kyverno ya está instalado
echo -e "\n[3/4] Verificando si Kyverno ya está instalado..."
if kubectl get namespace kyverno &> /dev/null; then
    echo "ADVERTENCIA: El namespace 'kyverno' ya existe"
    read -p "¿Deseas continuar con la instalación/actualización? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Instalación cancelada"
        exit 0
    fi
fi

# Instalar Kyverno
echo -e "\n[4/4] Instalando Kyverno..."
helm upgrade --install kyverno kyverno/kyverno \
    --namespace kyverno \
    --create-namespace \
    --set replicaCount=1 \
    --wait \
    --timeout 5m

echo -e "\n✓ Kyverno instalado exitosamente!"

# Verificar la instalación
echo -e "\n=== Verificación de la Instalación ==="
echo "Verificando pods de Kyverno..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=120s

echo -e "\nEstado de los pods:"
kubectl get pods -n kyverno

echo -e "\nEstado de los servicios:"
kubectl get svc -n kyverno

echo -e "\n=== Instalación Completada ==="
echo "Kyverno está listo para usar."
echo ""
echo "Para verificar las políticas instaladas:"
echo "  kubectl get clusterpolicies"
echo ""
echo "Para aplicar políticas personalizadas:"
echo "  kubectl apply -f kyverno/policies/"
