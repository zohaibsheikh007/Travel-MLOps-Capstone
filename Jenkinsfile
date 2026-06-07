pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'travelwise/flight-price-api'
        K8S_MANIFEST = 'Flight Prediction/deployment.yaml'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'python -m pip install -r "Flight Prediction/requirements.txt"'
            }
        }

        stage('Train Model') {
            steps {
                sh 'python "Flight Prediction/train_model.py"'
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    python -c "
from Flight_Price import app
client = app.test_client()
resp = client.get('/health')
assert resp.status_code == 200
print('Health check passed')
"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def tag = "${env.BUILD_NUMBER}"
                    sh "docker build -t ${DOCKER_IMAGE}:${tag} 'Flight Prediction'"
                    sh "docker tag ${DOCKER_IMAGE}:${tag} ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Push Docker Image') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh "docker push ${DOCKER_IMAGE}:${env.BUILD_NUMBER}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                sh """
                    sed -i 's|image: .*|image: ${DOCKER_IMAGE}:${env.BUILD_NUMBER}|' '${K8S_MANIFEST}'
                    kubectl apply -f '${K8S_MANIFEST}'
                    kubectl apply -f 'Flight Prediction/service.yaml'
                """
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
