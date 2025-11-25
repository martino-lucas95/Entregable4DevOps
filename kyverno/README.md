# Políticas de Seguridad con Kyverno

Este directorio contiene las políticas de seguridad de Kubernetes definidas con Kyverno.

## Estructura

```
kyverno/
├── README.md          # Este archivo
└── policies/          # Políticas de Kyverno (ClusterPolicy/Policy)
```

## Instalación de Kyverno

Para instalar Kyverno en el cluster, ejecuta uno de los siguientes scripts desde la raíz del proyecto:

**Linux/macOS:**
```bash
./install-kyverno.sh
```

**Windows (PowerShell):**
```powershell
.\install-kyverno.ps1
```

## Verificación

Después de la instalación, verifica que Kyverno esté funcionando:

```bash
# Verificar pods de Kyverno
kubectl get pods -n kyverno

# Verificar políticas instaladas
kubectl get clusterpolicies
kubectl get policies --all-namespaces
```

## Validación de Políticas

Para validar que las políticas funcionan correctamente y que los pods que incumplan sean rechazados, ejecuta el script de validación:

**Linux/macOS:**
```bash
./validate-kyverno-policies.sh
```

**Windows (PowerShell):**
```powershell
.\validate-kyverno-policies.ps1
```

El script realiza las siguientes acciones:
1. Verifica que Kyverno esté instalado y funcionando
2. Aplica todas las políticas desde `kyverno/policies/`
3. Crea pods de prueba que violan cada política para verificar que sean rechazados
4. Crea un pod válido que cumple todas las políticas para verificar que sea aceptado
5. Registra toda la evidencia en `reports/kyverno-validation.log`

**Tests ejecutados:**
- **TEST 1:** Pod con imagen `latest` (debe ser rechazado)
- **TEST 2:** Pod sin límites de recursos (debe ser rechazado)
- **TEST 3:** Pod ejecutándose como root (debe ser rechazado)
- **TEST 4:** Pod sin labels obligatorios (debe ser rechazado)
- **TEST 5:** Pod válido que cumple todas las políticas (debe ser aceptado)
- **TEST 6:** Pod con imagen Backend de la aplicación (`entregable4devops-backend:1.0`) - debe cumplir todas las políticas
- **TEST 7:** Pod con imagen Frontend de la aplicación (`entregable4devops-frontend:1.0`) - debe cumplir todas las políticas

## Aplicar Políticas

Para aplicar las políticas personalizadas, puedes usar el script automatizado o aplicar manualmente:

**Usando el script (recomendado):**

```bash
# Linux/macOS
./apply-kyverno-policies.sh

# Windows (PowerShell)
.\apply-kyverno-policies.ps1
```

**Aplicación manual:**

```bash
# Aplicar todas las políticas
kubectl apply -f kyverno/policies/

# Aplicar una política específica
kubectl apply -f kyverno/policies/nombre-politica.yaml

# Verificar políticas aplicadas
kubectl get clusterpolicies
```

## Políticas Implementadas

El proyecto incluye las siguientes políticas de seguridad:

### 1. Prohibir Imágenes con Tag Latest
**Archivo:** `disallow-latest-tag.yaml`

Prohíbe el uso de imágenes con el tag `latest` para garantizar reproducibilidad y seguridad. Requiere que todas las imágenes especifiquen un tag específico o digest.

**Aplica a:** Contenedores, initContainers, ephemeralContainers

### 2. Requerir Límites de Recursos
**Archivo:** `require-resource-limits.yaml`

Exige que todos los pods tengan límites de CPU y memoria definidos para prevenir el consumo excesivo de recursos y garantizar la estabilidad del cluster.

**Aplica a:** Contenedores, initContainers, ephemeralContainers

### 3. Prohibir Ejecución como Root
**Archivo:** `disallow-root-containers.yaml`

Impide que los contenedores se ejecuten como usuario root (UID 0) para reducir el riesgo de escalada de privilegios y cumplir con el principio de menor privilegio.

**Aplica a:** Contenedores, initContainers, ephemeralContainers

### 4. Requerir Labels Obligatorios
**Archivo:** `require-labels.yaml`

Requiere que todos los pods tengan labels obligatorios (`app`, `version`, `environment`) para facilitar la organización, monitoreo y gestión de recursos en el cluster.

**Aplica a:** Todos los pods

## Tipos de Políticas

Kyverno soporta dos tipos de políticas:

1. **ClusterPolicy**: Políticas que se aplican a nivel de cluster (todos los namespaces)
2. **Policy**: Políticas que se aplican a un namespace específico

## Recursos

- [Documentación oficial de Kyverno](https://kyverno.io/docs/)
- [Ejemplos de políticas](https://kyverno.io/policies/)
- [Guía de mejores prácticas](https://kyverno.io/docs/best-practices/)
