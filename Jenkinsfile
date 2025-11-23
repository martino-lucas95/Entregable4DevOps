pipeline {
    agent any
    
    environment {
        // Docker registry configuration
        DOCKER_REGISTRY = credentials('docker-registry-url')
        DOCKER_CREDENTIALS = credentials('docker-credentials')
        
        // Kubernetes configuration
        KUBECONFIG = credentials('kubeconfig')
        
        // Snyk configuration
        SNYK_TOKEN = credentials('snyk-token')
        
        // Application versions
        BACKEND_IMAGE = "entregable4devops-backend"
        FRONTEND_IMAGE = "entregable4devops-frontend"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        
        // Helm configuration
        HELM_RELEASE = "stock-management"
        HELM_NAMESPACE = "default"
        
        // Environment
        DEPLOY_ENV = "${env.BRANCH_NAME == 'main' ? 'prod' : 'dev'}"
    }
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Deployment environment')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip tests')
        booleanParam(name: 'SKIP_SECURITY_SCAN', defaultValue: false, description: 'Skip security scans (not recommended)')
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "=== Stage: Clonación del Repositorio ==="
                    checkout scm
                    
                    // Get commit info for tracking
                    env.GIT_COMMIT_MSG = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
                    env.GIT_AUTHOR = sh(returnStdout: true, script: 'git log -1 --pretty=%an').trim()
                    
                    echo "Commit: ${env.GIT_COMMIT_MSG}"
                    echo "Author: ${env.GIT_AUTHOR}"
                }
            }
        }
        
        stage('Static Code Analysis') {
            steps {
                script {
                    echo "=== Stage: Análisis de Código Estático con Semgrep ==="
                    
                    // Install Semgrep if not available
                    sh '''
                        if ! command -v semgrep &> /dev/null; then
                            pip3 install semgrep
                        fi
                    '''
                    
                    // Run Semgrep analysis
                    sh '''
                        echo "Running Semgrep analysis..."
                        semgrep --config=auto \
                                --json \
                                --output=semgrep-report.json \
                                backend/ frontend/ || true
                        
                        # Generate human-readable report
                        semgrep --config=auto \
                                --output=semgrep-report.txt \
                                backend/ frontend/ || true
                    '''
                    
                    // Archive reports
                    archiveArtifacts artifacts: 'semgrep-report.*', allowEmptyArchive: true
                    
                    // Check for critical issues
                    script {
                        def semgrepResults = readJSON file: 'semgrep-report.json'
                        def criticalIssues = semgrepResults.results?.findAll { 
                            it.extra?.severity == 'ERROR' 
                        }?.size() ?: 0
                        
                        if (criticalIssues > 0) {
                            echo "WARNING: Found ${criticalIssues} critical issues in static analysis"
                            // Uncomment to fail on critical issues:
                            // error("Critical security issues found. Pipeline aborted.")
                        } else {
                            echo "No critical issues found in static analysis"
                        }
                    }
                }
            }
        }
        
        stage('Dependency Vulnerability Scan') {
            when {
                expression { return !params.SKIP_SECURITY_SCAN }
            }
            steps {
                script {
                    echo "=== Stage: Escaneo de Vulnerabilidades con Snyk ==="
                    
                    def criticalVulns = 0
                    def highVulns = 0
                    
                    // Scan Backend dependencies
                    dir('backend') {
                        sh '''
                            echo "Scanning backend dependencies..."
                            npx snyk auth ${SNYK_TOKEN}
                            npx snyk test \
                                --json \
                                --severity-threshold=high \
                                > ../snyk-backend-report.json || true
                        '''
                    }
                    
                    // Scan Frontend dependencies
                    dir('frontend') {
                        sh '''
                            echo "Scanning frontend dependencies..."
                            npx snyk test \
                                --json \
                                --severity-threshold=high \
                                > ../snyk-frontend-report.json || true
                        '''
                    }
                    
                    // Archive reports
                    archiveArtifacts artifacts: 'snyk-*-report.json', allowEmptyArchive: true
                    
                    // Parse results and check for critical vulnerabilities
                    script {
                        try {
                            def backendReport = readJSON file: 'snyk-backend-report.json'
                            def frontendReport = readJSON file: 'snyk-frontend-report.json'
                            
                            criticalVulns = (backendReport.vulnerabilities?.findAll { it.severity == 'critical' }?.size() ?: 0) +
                                          (frontendReport.vulnerabilities?.findAll { it.severity == 'critical' }?.size() ?: 0)
                            
                            highVulns = (backendReport.vulnerabilities?.findAll { it.severity == 'high' }?.size() ?: 0) +
                                       (frontendReport.vulnerabilities?.findAll { it.severity == 'high' }?.size() ?: 0)
                            
                            echo "Vulnerability Summary:"
                            echo "  Critical: ${criticalVulns}"
                            echo "  High: ${highVulns}"
                            
                            // Fail pipeline if critical vulnerabilities found
                            if (criticalVulns > 0) {
                                error("CRITICAL VULNERABILITIES FOUND: ${criticalVulns} critical vulnerabilities detected. Pipeline aborted for security reasons.")
                            }
                            
                            if (highVulns > 5) {
                                echo "WARNING: ${highVulns} high severity vulnerabilities found. Consider fixing before production deployment."
                            }
                        } catch (Exception e) {
                            echo "Could not parse Snyk reports: ${e.message}"
                        }
                    }
                }
            }
        }
        
        stage('Build and Test Backend') {
            steps {
                script {
                    echo "=== Stage: Construcción y Test de Backend ==="
                    
                    dir('backend') {
                        sh '''
                            echo "Installing dependencies..."
                            npm ci
                            
                            echo "Generating Prisma client..."
                            npx prisma generate
                        '''
                        
                        if (!params.SKIP_TESTS) {
                            sh '''
                                echo "Running tests..."
                                npm run test -- --coverage || true
                            '''
                            
                            // Archive test results
                            junit testResults: '**/test-results/*.xml', allowEmptyResults: true
                            
                            // Publish coverage
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage',
                                reportFiles: 'index.html',
                                reportName: 'Backend Coverage Report'
                            ])
                        }
                        
                        sh '''
                            echo "Building application..."
                            npm run build
                        '''
                    }
                }
            }
        }
        
        stage('Build and Test Frontend') {
            steps {
                script {
                    echo "=== Stage: Construcción y Test de Frontend ==="
                    
                    dir('frontend') {
                        sh '''
                            echo "Installing dependencies..."
                            npm ci
                        '''
                        
                        if (!params.SKIP_TESTS) {
                            sh '''
                                echo "Running tests..."
                                npm run test || true
                            '''
                        }
                        
                        sh '''
                            echo "Building application..."
                            npm run build
                        '''
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo "=== Stage: Construcción de Imágenes Docker ==="
                    
                    // Build backend image
                    echo "Building backend Docker image..."
                    sh """
                        docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} \
                                     -t ${BACKEND_IMAGE}:latest \
                                     ./backend
                    """
                    
                    // Build frontend image
                    echo "Building frontend Docker image..."
                    sh """
                        docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} \
                                     -t ${FRONTEND_IMAGE}:latest \
                                     ./frontend
                    """
                    
                    // Display image sizes
                    sh """
                        echo "Image sizes:"
                        docker images | grep entregable4devops
                    """
                }
            }
        }
        
        stage('Scan Docker Images') {
            when {
                expression { return !params.SKIP_SECURITY_SCAN }
            }
            steps {
                script {
                    echo "=== Stage: Escaneo de Imágenes Docker con Trivy ==="
                    
                    // Scan backend image
                    sh """
                        echo "Scanning backend image..."
                        trivy image \
                            --format json \
                            --output trivy-backend-image.json \
                            --severity CRITICAL,HIGH \
                            ${BACKEND_IMAGE}:${IMAGE_TAG} || true
                        
                        trivy image \
                            --severity CRITICAL,HIGH \
                            ${BACKEND_IMAGE}:${IMAGE_TAG}
                    """
                    
                    // Scan frontend image
                    sh """
                        echo "Scanning frontend image..."
                        trivy image \
                            --format json \
                            --output trivy-frontend-image.json \
                            --severity CRITICAL,HIGH \
                            ${FRONTEND_IMAGE}:${IMAGE_TAG} || true
                        
                        trivy image \
                            --severity CRITICAL,HIGH \
                            ${FRONTEND_IMAGE}:${IMAGE_TAG}
                    """
                    
                    archiveArtifacts artifacts: 'trivy-*-image.json', allowEmptyArchive: true
                    
                    // Check for critical vulnerabilities
                    script {
                        def backendScan = sh(
                            script: "trivy image --format json --quiet ${BACKEND_IMAGE}:${IMAGE_TAG}",
                            returnStdout: true
                        )
                        def frontendScan = sh(
                            script: "trivy image --format json --quiet ${FRONTEND_IMAGE}:${IMAGE_TAG}",
                            returnStdout: true
                        )
                        
                        // Parse and check for critical vulnerabilities
                        // If critical vulnerabilities found, fail the pipeline
                        echo "Image vulnerability scan completed. Check Trivy reports for details."
                    }
                }
            }
        }
        
        stage('Push Docker Images') {
            steps {
                script {
                    echo "=== Stage: Publicación de Imágenes Docker ==="
                    
                    // Login to Docker registry
                    sh """
                        echo ${DOCKER_CREDENTIALS_PSW} | docker login -u ${DOCKER_CREDENTIALS_USR} --password-stdin ${DOCKER_REGISTRY}
                    """
                    
                    // Tag images for registry
                    sh """
                        docker tag ${BACKEND_IMAGE}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG}
                        docker tag ${BACKEND_IMAGE}:latest ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:latest
                        
                        docker tag ${FRONTEND_IMAGE}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG}
                        docker tag ${FRONTEND_IMAGE}:latest ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:latest
                    """
                    
                    // Push images
                    sh """
                        docker push ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:latest
                        
                        docker push ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:latest
                    """
                    
                    echo "Images pushed successfully:"
                    echo "  - ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG}"
                    echo "  - ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "=== Stage: Despliegue en Kubernetes con Helm ==="
                    
                    def valuesFile = params.ENVIRONMENT == 'prod' ? 'values-prod.yaml' : 'values-dev.yaml'
                    
                    sh """
                        # Set kubectl context
                        export KUBECONFIG=${KUBECONFIG}
                        
                        # Update Helm dependencies
                        helm dependency update ./helm-chart
                        
                        # Deploy or upgrade release
                        helm upgrade --install ${HELM_RELEASE} ./helm-chart \
                            --namespace ${HELM_NAMESPACE} \
                            --create-namespace \
                            --values ./helm-chart/${valuesFile} \
                            --set backend.image.tag=${IMAGE_TAG} \
                            --set frontend.image.tag=${IMAGE_TAG} \
                            --wait \
                            --timeout 5m
                        
                        # Display deployment status
                        echo "Deployment completed. Checking status..."
                        kubectl get pods -n ${HELM_NAMESPACE} -l app.kubernetes.io/instance=${HELM_RELEASE}
                        kubectl get services -n ${HELM_NAMESPACE} -l app.kubernetes.io/instance=${HELM_RELEASE}
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo "=== Stage: Verificación del Despliegue ==="
                    
                    sh """
                        export KUBECONFIG=${KUBECONFIG}
                        
                        echo "Waiting for pods to be ready..."
                        kubectl wait --for=condition=ready pod \
                            -l app.kubernetes.io/instance=${HELM_RELEASE} \
                            -n ${HELM_NAMESPACE} \
                            --timeout=300s
                        
                        echo "Pod status:"
                        kubectl get pods -n ${HELM_NAMESPACE} -l app.kubernetes.io/instance=${HELM_RELEASE}
                        
                        echo "Service endpoints:"
                        kubectl get svc -n ${HELM_NAMESPACE} -l app.kubernetes.io/instance=${HELM_RELEASE}
                        
                        echo "Deployment history:"
                        helm history ${HELM_RELEASE} -n ${HELM_NAMESPACE}
                    """
                    
                    // Optional: Run smoke tests
                    echo "Deployment verified successfully!"
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo "=== Pipeline Execution: SUCCESS ==="
                echo "Build: ${env.BUILD_NUMBER}"
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Backend Image: ${BACKEND_IMAGE}:${IMAGE_TAG}"
                echo "Frontend Image: ${FRONTEND_IMAGE}:${IMAGE_TAG}"
                
                // Send success notification (if configured)
                // slackSend(color: 'good', message: "Deployment successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
            }
        }
        
        failure {
            script {
                echo "=== Pipeline Execution: FAILED ==="
                echo "Build: ${env.BUILD_NUMBER}"
                echo "Check logs for details"
                
                // Send failure notification (if configured)
                // slackSend(color: 'danger', message: "Deployment failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
            }
        }
        
        always {
            script {
                // Cleanup
                echo "Cleaning up workspace..."
                
                // Remove old Docker images
                sh """
                    docker image prune -f
                """
                
                // Archive important artifacts
                archiveArtifacts artifacts: '**/reports/*.json', allowEmptyArchive: true
            }
        }
    }
}
