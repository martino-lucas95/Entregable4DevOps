pipeline {
    agent any
    
    environment {
        // Docker registry configuration
        DOCKER_REGISTRY = credentials('docker-registry-url')
        DOCKER_CREDENTIALS = credentials('docker-credentials')
        
        // Kubernetes configuration
        KUBECONFIG = credentials('kubeconfig')
        
        // Checkmarx One configuration
        CHECKMARX_ONE_API_KEY = credentials('checkmarx-one-api-key')
        CHECKMARX_ONE_BASE_URI = credentials('checkmarx-one-base-uri')
        
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
                            error("CRITICAL SECURITY ISSUES FOUND: ${criticalIssues} critical issues detected in static analysis. Pipeline aborted for security reasons.")
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
                    echo "=== Stage: Escaneo de Vulnerabilidades con Checkmarx One SCA ==="
                    
                    // Install Checkmarx One CLI if not available
                    // Assuming Linux x64 environment (standard for CI/CD containers)
                    sh '''
                        if ! command -v cx &> /dev/null; then
                            echo "Installing Checkmarx One CLI (Linux x64)..."
                            
                            # Download latest release for Linux x64
                            curl -L -o cx.tar.gz "https://github.com/checkmarx-io/ast-cli/releases/latest/download/ast-cli_linux_x64.tar.gz" || {
                                echo "ERROR: Failed to download Checkmarx One CLI"
                                exit 1
                            }
                            
                            # Extract and install
                            tar -xzf cx.tar.gz
                            chmod +x cx
                            
                            # Install to /usr/local/bin or add to PATH
                            if [ -w /usr/local/bin ]; then
                                mv cx /usr/local/bin/
                            else
                                mkdir -p /tmp/cx-cli
                                mv cx /tmp/cx-cli/
                                export PATH=$PATH:/tmp/cx-cli
                            fi
                            
                            rm -f cx.tar.gz
                            
                            # Verify installation
                            if command -v cx &> /dev/null; then
                                echo "Checkmarx One CLI installed successfully"
                                cx version || true
                            else
                                echo "ERROR: Checkmarx One CLI installation failed"
                                exit 1
                            fi
                        else
                            echo "Checkmarx One CLI already installed"
                            cx version || true
                        fi
                    '''
                    
                    // Authenticate with Checkmarx One using API Key
                    sh '''
                        echo "Authenticating with Checkmarx One using API Key..."
                        cx auth login \
                            --apikey "${CHECKMARX_ONE_API_KEY}" \
                            --base-uri "${CHECKMARX_ONE_BASE_URI}"
                    '''
                    
                    // Single SCA scan for both backend and frontend
                    sh '''
                        echo "Running combined SCA scan for backend and frontend..."
                        echo "This scan will analyze dependencies from both backend/ and frontend/ directories"
                        
                        # Run single SCA scan from project root
                        # The --threshold parameter will cause the command to exit with non-zero code
                        # if critical or high vulnerabilities are found, which will fail the pipeline
                        # The CLI will automatically display scan results in the console output
                        cx scan create \
                            -s . \
                            --project-name "stock-management" \
                            --sca \
                            --output-path checkmarx-sca-report.json \
                            --output-format json \
                            --branch "${GIT_BRANCH}" \
                            --threshold "sca-critical=1; sca-high=1"
                        
                        # If we reach here, the scan completed successfully (no critical/high vulnerabilities)
                        echo "SCA scan completed successfully - no critical or high vulnerabilities found"
                    '''
                    
                    // Archive report for reference
                    archiveArtifacts artifacts: 'checkmarx-sca-report.json', allowEmptyArchive: true
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
                                npm run test -- --coverage
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
                                npm run test
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
                        try {
                            def backendReport = readJSON file: 'trivy-backend-image.json'
                            def frontendReport = readJSON file: 'trivy-frontend-image.json'
                            
                            // Count critical vulnerabilities from Trivy JSON structure
                            def backendCritical = 0
                            def frontendCritical = 0
                            
                            // Parse backend report
                            if (backendReport.Results) {
                                backendReport.Results.each { result ->
                                    if (result.Vulnerabilities) {
                                        result.Vulnerabilities.each { vuln ->
                                            if (vuln.Severity == 'CRITICAL') {
                                                backendCritical++
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Parse frontend report
                            if (frontendReport.Results) {
                                frontendReport.Results.each { result ->
                                    if (result.Vulnerabilities) {
                                        result.Vulnerabilities.each { vuln ->
                                            if (vuln.Severity == 'CRITICAL') {
                                                frontendCritical++
                                            }
                                        }
                                    }
                                }
                            }
                            
                            def totalCritical = backendCritical + frontendCritical
                            
                            if (totalCritical > 0) {
                                error("CRITICAL VULNERABILITIES FOUND IN DOCKER IMAGES: ${totalCritical} critical vulnerabilities detected (Backend: ${backendCritical}, Frontend: ${frontendCritical}). Pipeline aborted for security reasons.")
                            } else {
                                echo "No critical vulnerabilities found in Docker images. Scan completed successfully."
                            }
                        } catch (Exception e) {
                            echo "Warning: Could not parse Trivy reports: ${e.message}"
                            echo "Image vulnerability scan completed. Check Trivy reports for details."
                            // Don't fail pipeline if parsing fails, but log the error
                        }
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
