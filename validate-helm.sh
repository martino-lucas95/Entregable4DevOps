#!/bin/bash
# Script para validar el despliegue de Helm Chart (Linux/macOS)

echo "=== Validación de Helm Chart ==="

# Variables
CHART_PATH="./helm-chart"
RELEASE_NAME="stock-management-test"
NAMESPACE="test"

echo -e "\n[1/6] Validando sintaxis del chart..."
helm lint $CHART_PATH

if [ $? -ne 0 ]; then
    echo "ERROR: Lint falló"
    exit 1
fi

echo -e "\n[2/6] Generando templates (dry-run)..."
helm template $RELEASE_NAME $CHART_PATH \
    --values "$CHART_PATH/values-dev.yaml" \
    --debug > helm-template-output.yaml

echo "Templates generados en: helm-template-output.yaml"

echo -e "\n[3/6] Verificando cluster de Kubernetes..."
kubectl cluster-info

if [ $? -ne 0 ]; then
    echo "ERROR: No se puede conectar al cluster de Kubernetes"
    echo "Inicia Minikube o configura kubectl correctamente"
    exit 1
fi

echo -e "\n[4/6] Verificando que las imágenes existan..."
if ! docker images | grep -q "entregable4devops-backend.*1.0"; then
    echo "ADVERTENCIA: Imagen backend no encontrada localmente"
    echo "Construir con: docker-compose build"
fi

if ! docker images | grep -q "entregable4devops-frontend.*1.0"; then
    echo "ADVERTENCIA: Imagen frontend no encontrada localmente"
    echo "Construir con: docker-compose build"
fi

echo -e "\n[5/6] Instalando chart en modo dry-run..."
helm install $RELEASE_NAME $CHART_PATH \
    --values "$CHART_PATH/values-dev.yaml" \
    --namespace $NAMESPACE \
    --create-namespace \
    --dry-run \
    --debug

if [ $? -ne 0 ]; then
    echo "ERROR: Instalación en dry-run falló"
    exit 1
fi

echo -e "\n[6/6] Validación completada exitosamente!"

echo -e "\n=== Comandos de Despliegue ==="
echo "Para desplegar en desarrollo:"
echo "  helm install $RELEASE_NAME $CHART_PATH --values $CHART_PATH/values-dev.yaml --namespace $NAMESPACE --create-namespace"

echo -e "\nPara verificar el despliegue:"
echo "  kubectl get all -n $NAMESPACE"

echo -e "\nPara acceder a los servicios:"
echo "  kubectl port-forward svc/$RELEASE_NAME-frontend 5173:5173 -n $NAMESPACE"

echo -e "\nPara desinstalar:"
echo "  helm uninstall $RELEASE_NAME -n $NAMESPACE"
