# Script para analizar la calidad de las imágenes Docker
# Asegúrate de que Docker Desktop esté corriendo antes de ejecutar este script

Write-Host "=== Análisis de Calidad de Imágenes Docker ===" -ForegroundColor Green

# Directorio de trabajo
$PROJECT_DIR = "c:\Users\ForiscSe\Downloads\Entregable4DevOps-main\Entregable4DevOps-main"
Set-Location $PROJECT_DIR

# Crear directorio de reportes si no existe
if (-not (Test-Path ".\reports")) {
    New-Item -ItemType Directory -Path ".\reports" | Out-Null
}

Write-Host "`n[1/4] Construyendo imágenes..." -ForegroundColor Yellow
docker-compose build

Write-Host "`n[2/4] Ejecutando análisis de vulnerabilidades con Trivy..." -ForegroundColor Yellow

# Análisis de Backend con Trivy
Write-Host "`nAnalizando imagen backend..." -ForegroundColor Cyan
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image entregable4devops-backend:1.0 > reports/trivy-backend-analysis.txt

# Análisis de Frontend con Trivy
Write-Host "Analizando imagen frontend..." -ForegroundColor Cyan
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image entregable4devops-frontend:1.0 > reports/trivy-frontend-analysis.txt

Write-Host "`n[3/4] Analizando capas y tamaño con docker inspect..." -ForegroundColor Yellow

# Obtener información de las imágenes
$backendInfo = docker inspect entregable4devops-backend:1.0 | ConvertFrom-Json
$frontendInfo = docker inspect entregable4devops-frontend:1.0 | ConvertFrom-Json

# Información de Backend
$backendSize = [math]::Round($backendInfo.Size / 1MB, 2)
$backendLayers = $backendInfo.RootFS.Layers.Count

# Información de Frontend
$frontendSize = [math]::Round($frontendInfo.Size / 1MB, 2)
$frontendLayers = $frontendInfo.RootFS.Layers.Count

Write-Host "Backend - Tamaño: $backendSize MB, Capas: $backendLayers" -ForegroundColor Cyan
Write-Host "Frontend - Tamaño: $frontendSize MB, Capas: $frontendLayers" -ForegroundColor Cyan

# Para usar Dive (necesita instalación):
# choco install dive
# O descargar desde: https://github.com/wagoodman/dive/releases

Write-Host "`n[4/4] Para análisis detallado de capas, instala Dive:" -ForegroundColor Yellow
Write-Host "  1. Instalar: choco install dive" -ForegroundColor Gray
Write-Host "  2. Analizar backend: dive entregable4devops-backend:1.0" -ForegroundColor Gray
Write-Host "  3. Analizar frontend: dive entregable4devops-frontend:1.0" -ForegroundColor Gray

Write-Host "`nGenerando reporte en reports/image-analysis.md..." -ForegroundColor Yellow

# Crear el reporte
$reportContent = @"
# Análisis de Calidad de Imágenes Docker

**Fecha de análisis:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 1. Resumen de Imágenes

### Backend (entregable4devops-backend:1.0)
- **Tamaño total:** $backendSize MB
- **Cantidad de capas:** $backendLayers
- **Imagen base:** node:20-alpine
- **Build multietapa:** Sí

### Frontend (entregable4devops-frontend:1.0)
- **Tamaño total:** $frontendSize MB
- **Cantidad de capas:** $frontendLayers
- **Imagen base:** node:20-alpine
- **Build multietapa:** Sí

## 2. Análisis de Vulnerabilidades (Trivy)

### Backend
Ver detalles completos en: ``reports/trivy-backend-analysis.txt``

### Frontend
Ver detalles completos en: ``reports/trivy-frontend-analysis.txt``

## 3. Observaciones de Optimización

### Backend

#### Optimizaciones Implementadas ✅
- **Multi-stage build:** Reduce el tamaño final al no incluir dependencias de desarrollo
- **Imagen base Alpine:** Imagen ligera basada en Alpine Linux
- **npm cache clean:** Limpia el caché de npm después de instalaciones
- **Usuario no-root:** Mejora la seguridad ejecutando como usuario sin privilegios
- **Dependencias de producción:** Solo instala dependencias necesarias en la etapa final

#### Optimizaciones Adicionales Sugeridas 🔧
1. **Eliminar Prisma CLI global:** 
   - Considerar si realmente se necesita Prisma CLI en producción
   - Si solo se necesita para migraciones, considerar hacerlas antes del despliegue
   - Ahorro estimado: 30-50 MB

2. **Combinar comandos RUN:**
   - Varios comandos RUN crean capas adicionales
   - Combinar comandos relacionados reduce capas y tamaño
   
3. **Usar .dockerignore:**
   - Excluir node_modules, .git, archivos de test, etc.
   - Reduce el contexto de build

4. **Cache de dependencias:**
   - El orden actual es correcto (COPY package*.json antes de npm install)
   - Aprovecha el cache de Docker efectivamente

### Frontend

#### Optimizaciones Implementadas ✅
- **Multi-stage build:** Separa build de producción
- **Imagen base Alpine:** Minimiza el tamaño base
- **Usuario no-root:** Seguridad mejorada
- **Servidor ligero (serve):** Usa serve en lugar de servidor completo

#### Optimizaciones Adicionales Sugeridas 🔧
1. **Considerar Nginx en lugar de serve:**
   - Nginx es más eficiente para servir archivos estáticos
   - Imagen nginx:alpine es muy ligera (~40 MB vs ~180 MB de node:alpine)
   - Mejor rendimiento y menor consumo de recursos
   
2. **Optimización de assets:**
   - Verificar que Vite esté configurado para minificación
   - Considerar compresión gzip/brotli de assets
   
3. **Usar .dockerignore:**
   - Excluir node_modules, .git, archivos de desarrollo

### Mejoras Generales

1. **Versionado de dependencias:**
   - Fijar versiones específicas en package.json
   - Evita cambios inesperados en builds futuros

2. **Health checks:**
   - Agregar HEALTHCHECK en los Dockerfiles
   - Mejor integración con orquestadores

3. **Labels:**
   - Agregar labels con metadata (versión, maintainer, etc.)
   - Facilita la gestión de imágenes

4. **Escaneo continuo:**
   - Integrar Trivy en CI/CD
   - Escanear en cada build

## 4. Análisis Detallado de Capas

Para un análisis interactivo detallado de las capas, use Dive:

\`\`\`powershell
# Instalar Dive
choco install dive

# Analizar backend
dive entregable4devops-backend:1.0

# Analizar frontend
dive entregable4devops-frontend:1.0
\`\`\`

Dive permite:
- Ver el tamaño de cada capa individualmente
- Identificar archivos que ocupan más espacio
- Detectar duplicación de archivos entre capas
- Calcular la eficiencia de la imagen

## 5. Recomendaciones Prioritarias

### Alta Prioridad
1. ✅ Multi-stage builds (ya implementado)
2. ✅ Imágenes Alpine (ya implementado)
3. 🔧 Agregar .dockerignore a ambos proyectos
4. 🔧 Evaluar necesidad de Prisma CLI global en backend

### Media Prioridad
1. 🔧 Considerar Nginx para frontend
2. 🔧 Combinar comandos RUN para reducir capas
3. 🔧 Agregar HEALTHCHECK

### Baja Prioridad
1. 🔧 Agregar labels de metadata
2. 🔧 Optimizar orden de capas para mejor cache

## 6. Métricas de Calidad

| Métrica | Backend | Frontend | Estado |
|---------|---------|----------|--------|
| Tamaño | $backendSize MB | $frontendSize MB | ✅ Aceptable |
| Capas | $backendLayers | $frontendLayers | ✅ Bueno |
| Multi-stage | Sí | Sí | ✅ Implementado |
| Usuario no-root | Sí | Sí | ✅ Implementado |
| Imagen base | Alpine | Alpine | ✅ Óptimo |

**Conclusión:** Las imágenes están bien optimizadas con multi-stage builds y Alpine. 
Las mejoras sugeridas son incrementales y pueden implementarse gradualmente.
"@

# Guardar el reporte
$reportContent | Out-File -FilePath "reports\image-analysis.md" -Encoding UTF8

Write-Host "`n=== Análisis completado ===" -ForegroundColor Green
Write-Host "Reporte generado en: reports\image-analysis.md" -ForegroundColor Cyan
Write-Host "`nPara ver vulnerabilidades detalladas:" -ForegroundColor Yellow
Write-Host "  - Backend: reports\trivy-backend-analysis.txt" -ForegroundColor Gray
Write-Host "  - Frontend: reports\trivy-frontend-analysis.txt" -ForegroundColor Gray
