#!/bin/bash
# Script para instalar Falco en el cluster de Kubernetes

set -e

echo "=== Instalación de Falco ==="

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

# Agregar repositorio de Falco
echo -e "\n[2/4] Agregando repositorio de Helm de Falco..."
if helm repo list | grep -q "falcosecurity"; then
    echo "Repositorio de Falco ya existe, actualizando..."
    helm repo update falcosecurity
else
    helm repo add falcosecurity https://falcosecurity.github.io/charts
    helm repo update
fi
echo "✓ Repositorio de Falco agregado y actualizado"

# Verificar si Falco ya está instalado
echo -e "\n[3/4] Verificando si Falco ya está instalado..."
if kubectl get namespace falco &> /dev/null; then
    echo "ADVERTENCIA: El namespace 'falco' ya existe"
    read -p "¿Deseas continuar con la instalación/actualización? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Instalación cancelada"
        exit 0
    fi
fi

# Instalar Falco
echo -e "\n[4/4] Instalando Falco..."
if [ -f "falco-values.yaml" ]; then
    echo "Usando valores personalizados desde falco-values.yaml"
    helm upgrade --install falco falcosecurity/falco \
        --namespace falco \
        --create-namespace \
        --values falco-values.yaml \
        --wait \
        --timeout 5m
else
    echo "Instalando con valores por defecto (puede fallar si hay políticas de Kyverno)"
    helm upgrade --install falco falcosecurity/falco \
        --namespace falco \
        --create-namespace \
        --set driver.enabled=true \
        --set driver.loader.enabled=false \
        --set falcosidekick.enabled=false \
        --wait \
        --timeout 5m
fi

echo -e "\n✓ Falco instalado exitosamente!"

# Verificar la instalación
echo -e "\n=== Verificación de la Instalación ==="
echo "Verificando pods de Falco..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=falco -n falco --timeout=120s

echo -e "\nEstado de los pods:"
kubectl get pods -n falco

echo -e "\nEstado de los servicios:"
kubectl get svc -n falco

echo -e "\n=== Instalación Completada ==="
echo "Falco está listo para monitorear eventos de seguridad."
echo ""
echo "Para ver eventos de Falco:"
echo "  kubectl logs -f -l app.kubernetes.io/name=falco -n falco"
echo ""
echo "Para ver eventos en Falco Sidekick:"
echo "  kubectl logs -f -l app.kubernetes.io/name=falcosidekick -n falco"

