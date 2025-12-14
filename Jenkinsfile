pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'vbz-tram-service'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        CONTAINER_NAME = 'vbz-tram-departures'
        APP_PORT = '3001'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Stop Old Container') {
            steps {
                script {
                    sh """
                        docker stop ${CONTAINER_NAME} || true
                        docker rm ${CONTAINER_NAME} || true
                    """
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo "Deploying container: ${CONTAINER_NAME}"
                    sh """
                        docker run -d \
                          --name ${CONTAINER_NAME} \
                          --restart unless-stopped \
                          -p ${APP_PORT}:3001 \
                          -e NODE_ENV=production \
                          -e TZ=Europe/Zurich \
                          ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "Waiting for service to be healthy..."
                    sleep 5
                    sh "curl -f http://localhost:${APP_PORT}/api/abfahrten || exit 1"
                }
            }
        }
        
        stage('Cleanup Old Images') {
            steps {
                script {
                    sh """
                        docker image prune -f --filter "label=stage=builder"
                        docker images ${DOCKER_IMAGE} --format '{{.ID}} {{.Tag}}' | grep -v latest | tail -n +6 | awk '{print \$1}' | xargs -r docker rmi || true
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Deployment erfolgreich! Service läuft auf http://localhost:${APP_PORT}"
        }
        failure {
            echo "❌ Deployment fehlgeschlagen!"
            sh "docker logs ${CONTAINER_NAME} || true"
        }
    }
}
