# Stock Management System - DevOps Complete

Sistema de gestión de stock con stack completo de DevOps: contenedorización, orquestación y CI/CD.

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Helm-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Jenkins](https://img.shields.io/badge/CI%2FCD-Jenkins-D24939?logo=jenkins)](https://www.jenkins.io/)

## 📋 Tabla de Contenidos

- [Descripción](#descripción)
- [Arquitectura](#arquitectura)
- [Tecnologías](#tecnologías)
- [Requisitos](#requisitos)
- [Inicio Rápido](#inicio-rápido)
- [Despliegue](#despliegue)
- [Análisis de Calidad](#análisis-de-calidad)
- [CI/CD Pipeline](#cicd-pipeline)
- [Documentación](#documentación)

## 🎯 Descripción

Sistema completo de gestión de inventario (stock) implementando las mejores prácticas de DevOps:

- **Contenedorización** con Docker (multi-stage builds optimizados)
- **Orquestación** con Kubernetes + Helm Charts
- **CI/CD** automatizado con Jenkins
- **Análisis de seguridad** con Trivy, Snyk y Semgrep
- **Análisis de imágenes** con Dive

### Componentes

- **Backend API**: NestJS + TypeScript + Prisma ORM
- **Frontend Web**: React + Vite + TypeScript  
- **Base de Datos**: PostgreSQL 16 (Alpine)

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Frontend   │  │   Backend    │  │  PostgreSQL  │  │
│  │  (React)     │──│  (NestJS)    │──│   (Alpine)   │  │
│  │  Port: 5173  │  │  Port: 3000  │  │  Port: 5432  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                  │          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Service    │  │   Service    │  │   Service    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                           │                              │
│                    ┌──────────────┐                      │
│                    │   Ingress    │                      │
│                    └──────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

## 🛠️ Tecnologías

### Backend
- NestJS 10.x
- TypeScript 5.x
- Prisma ORM 6.x
- PostgreSQL 16

### Frontend
- React 18.x
- Vite 6.x
- TypeScript 5.x

### DevOps
- **Containerización**: Docker, Docker Compose
- **Orquestación**: Kubernetes, Helm 3.x
- **CI/CD**: Jenkins
- **Seguridad**: Trivy, Snyk, Semgrep
- **Análisis**: Dive

## 📦 Requisitos

### Para Desarrollo Local
- Docker 20.x+
- Docker Compose 2.x+
- Node.js 20.x+ (opcional)

### Para Kubernetes
- Kubernetes 1.20+
- Helm 3.0+
- kubectl configurado

### Para CI/CD
- Jenkins 2.x+
- Plugins: Docker, Kubernetes CLI, Git, Snyk

## 🚀 Inicio Rápido

### 1. Con Docker Compose (Desarrollo Local)

```bash
# Clonar el repositorio
git clone <repository-url>
cd Entregable4DevOps-main

# Construir y levantar servicios
docker-compose up -d

# Verificar servicios
docker-compose ps

# Acceder
# Frontend: http://localhost:5173
# Backend:  http://localhost:3000
# Database: localhost:5432
```

### 2. Con Kubernetes + Helm

```bash
# Construir imágenes Docker
docker-compose build

# Desplegar en Kubernetes
helm install stock-management ./helm-chart \
  --values ./helm-chart/values-dev.yaml \
  --namespace development \
  --create-namespace

# Verificar despliegue
kubectl get all -n development

# Acceder a la aplicación
kubectl port-forward svc/stock-management-frontend 5173:5173 -n development
```

Ver [DEPLOYMENT.md](./DEPLOYMENT.md) para instrucciones detalladas.

## 📊 Análisis de Calidad

### Análisis de Imágenes Docker

Se realizó un análisis completo de calidad de las imágenes Docker:

```bash
# Escaneo de vulnerabilidades con Trivy
.\trivy.exe image entregable4devops-backend:1.0

# Análisis de capas con Dive
.\dive.exe entregable4devops-backend:1.0
```

#### Resultados del Análisis

| Métrica | Backend | Frontend |
|---------|---------|----------|
| Tamaño | 872 MB | 148 MB |
| Capas | 21 | 17 |
| Vulnerabilidades Críticas | 0 | 0 |
| Vulnerabilidades Altas | 2 | 3 |
| Multi-stage Build | ✅ | ✅ |
| Usuario no-root | ✅ | ✅ |

**Reporte completo**: [reports/image-analysis.md](./reports/image-analysis.md)

### Optimizaciones Implementadas

✅ Multi-stage builds para reducir tamaño  
✅ Imágenes base Alpine Linux (8 MB vs 150 MB)  
✅ Usuario no-root para mayor seguridad  
✅ npm cache clean para eliminar archivos temporales  
✅ .dockerignore para optimizar contexto de build  

### Mejoras Sugeridas

🔧 Migrar frontend de Node+serve a Nginx Alpine (reducción 80%)  
🔧 Evaluar eliminación de Prisma CLI global en backend  
🔧 Combinar comandos RUN para reducir capas  

## 🔄 CI/CD Pipeline

### Pipeline de Jenkins

El pipeline automatizado incluye:

1. **Checkout** - Clonación del repositorio
2. **Static Analysis** - Análisis con Semgrep
3. **Vulnerability Scan** - Escaneo con Snyk
4. **Build & Test** - Backend y Frontend
5. **Docker Build** - Construcción de imágenes
6. **Image Scan** - Análisis con Trivy
7. **Push Images** - Publicación a registry
8. **Deploy** - Despliegue con Helm
9. **Verify** - Verificación del despliegue

```groovy
// Ejemplo de ejecución
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                sh '''
                    helm upgrade --install stock-management ./helm-chart \
                      --values ./helm-chart/values-${ENVIRONMENT}.yaml \
                      --set backend.image.tag=${BUILD_NUMBER}
                '''
            }
        }
    }
}
```

**Jenkinsfile completo**: [Jenkinsfile](./Jenkinsfile)

### Política de Seguridad

El pipeline **se detiene** si detecta:
- ❌ Vulnerabilidades críticas en dependencias
- ❌ Issues críticos en análisis estático
- ❌ Vulnerabilidades críticas en imágenes Docker
- ❌ Fallos en tests unitarios

## 🔐 Seguridad

### Análisis de Vulnerabilidades

```bash
# Backend dependencies
cd backend
npm audit

# Frontend dependencies  
cd frontend
npm audit

# Docker images
trivy image entregable4devops-backend:1.0
trivy image entregable4devops-frontend:1.0
```

### Reportes de Seguridad

- [Backend Dockerfile](./reports/security/backend/backend_dockerfile.md)
- [Frontend Dockerfile](./reports/security/frontend/frontend_dockerfile.md)
- [Backend Dependencies](./reports/security/backend/backend_dependencies.md)
- [Frontend Dependencies](./reports/security/frontend/frontend_dependencies.md)
- [Trivy Scans](./reports/security/)

## 📚 Documentación

### Guías Principales

- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Guía completa de despliegue con Kubernetes y Helm
- **[helm-chart/README.md](./helm-chart/README.md)** - Documentación del Helm Chart
- **[reports/image-analysis.md](./reports/image-analysis.md)** - Análisis de calidad de imágenes

### Estructura del Proyecto

```
Entregable4DevOps-main/
├── backend/                    # API NestJS
│   ├── src/
│   ├── prisma/
│   ├── Dockerfile
│   └── package.json
├── frontend/                   # React App
│   ├── components/
│   ├── Dockerfile
│   └── package.json
├── helm-chart/                 # Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   └── templates/
│       ├── deployment-backend.yaml
│       ├── deployment-frontend.yaml
│       ├── deployment-postgresql.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── configmap.yaml
│       └── secret.yaml
├── reports/                    # Análisis y reportes
│   ├── image-analysis.md
│   └── security/
├── docker-compose.yml
├── Jenkinsfile                 # Pipeline CI/CD
├── DEPLOYMENT.md              # Guía de despliegue
└── README.md
```

## 🧪 Testing

### Local con Docker Compose

```bash
# Levantar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f backend

# Tests del backend
docker-compose exec api npm run test

# Detener servicios
docker-compose down
```

### Validar Helm Chart

```bash
# Windows
.\validate-helm.ps1

# Linux/macOS
chmod +x validate-helm.sh
./validate-helm.sh
```

## 📈 Monitoreo

### Verificar Estado de Pods

```bash
# Ver todos los pods
kubectl get pods -n development

# Ver logs en tiempo real
kubectl logs -f -l app.kubernetes.io/component=backend -n development

# Describir pod
kubectl describe pod <pod-name> -n development
```

### Métricas de Recursos

```bash
# CPU y memoria de pods
kubectl top pods -n development

# Recursos de nodos
kubectl top nodes
```

## 🔄 Actualización

### Actualizar Despliegue

```bash
# Construir nuevas imágenes
docker-compose build

# Actualizar en Kubernetes
helm upgrade stock-management ./helm-chart \
  --values ./helm-chart/values-dev.yaml \
  --set backend.image.tag=1.1.0 \
  --set frontend.image.tag=1.1.0
```

### Rollback

```bash
# Ver historial
helm history stock-management -n development

# Rollback
helm rollback stock-management -n development
```

## 🛑 Desinstalación

```bash
# Docker Compose
docker-compose down -v

# Kubernetes
helm uninstall stock-management -n development
kubectl delete namespace development
```

## 🤝 Contribución

1. Fork el proyecto
2. Crear una rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📝 Comandos Útiles

### Docker

```bash
# Construir imágenes
docker-compose build

# Listar imágenes
docker images | grep entregable4devops

# Analizar imagen con Dive
dive entregable4devops-backend:1.0

# Escanear con Trivy
trivy image entregable4devops-backend:1.0
```

### Helm

```bash
# Validar chart
helm lint ./helm-chart

# Template sin instalar
helm template stock-management ./helm-chart

# Ver valores actuales
helm get values stock-management -n development

# Ver manifest desplegado
helm get manifest stock-management -n development
```

### Kubectl

```bash
# Port forward
kubectl port-forward svc/stock-management-frontend 5173:5173 -n development

# Ejecutar comando en pod
kubectl exec -it <pod-name> -n development -- /bin/sh

# Ver eventos
kubectl get events -n development --sort-by='.lastTimestamp'
```

## 📞 Soporte

Para problemas o preguntas:
- Ver [Troubleshooting](./DEPLOYMENT.md#troubleshooting) en DEPLOYMENT.md
- Revisar [Issues](https://github.com/your-repo/issues)
- Consultar documentación de [Helm](https://helm.sh/docs/) y [Kubernetes](https://kubernetes.io/docs/)

## 📄 Licencia

Este proyecto es parte de un entregable académico de DevOps.

---

**Desarrollado con** ❤️ **para el curso de DevOps**

**Última actualización:** Noviembre 18, 2025
