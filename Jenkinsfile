pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/demarchi3353/avaliacao-infra.git', branch: 'main'
            }
        }

        stage('Auth GCP') {
            steps {
                sh "gcloud auth activate-service-account --key-file=${GCP_CREDENTIALS}"
                sh "gcloud config set project ${GCP_PROJECT}"
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "docker-credential-gcr configure-docker --registries=us-central1-docker.pkg.dev"
                sh "docker push ${DOCKER_IMAGE}"
            }
        }

        stage('Create Secrets') {
            steps {
                script {
                    def secretTemplate = readFile 'k8s/secrets/mongo-credentials-template.yaml'
                    def urlBase64 = sh(script: "echo -n '${params.MONGO_URL}' | base64", returnStdout: true).trim()
                    def usernameBase64 = sh(script: "echo -n '${params.MONGO_USERNAME}' | base64", returnStdout: true).trim()
                    def passwordBase64 = sh(script: "echo -n '${params.MONGO_PASSWORD}' | base64", returnStdout: true).trim()
                    def secretYaml = secretTemplate.replaceAll('\\${MONGO_USERNAME}', usernameBase64).replaceAll('\\${MONGO_PASSWORD}', passwordBase64).replaceAll('\\${MONGO_URL}', urlBase64)
                    writeFile file: 'secret.yaml', text: secretYaml
                    sh 'kubectl apply -f secret.yaml'
                    sh 'kubectl create secret tls certificate --cert=/k8s/secrets/cert/cert.pem --key=/k8s/secrets/cert/privkey.pem'
                }
            }
        }

        stage('Deploy Nginx Ingress Controller') {
            steps {
                sh "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.0/deploy/static/provider/cloud/deploy.yaml"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh "gcloud container clusters get-credentials ${GKE_CLUSTER} --zone ${GKE_ZONE}"
                sh "kubectl apply -f k8s/deployments --namespace=${K8S_NAMESPACE}"
            }
        }
    }
}