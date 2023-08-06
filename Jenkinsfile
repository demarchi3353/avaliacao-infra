pipeline {
    agent any

    stages {
        stage('Auth GCP') {
            steps {
                sh "/google-cloud-sdk/bin/gcloud auth activate-service-account ${GCP_SERVICE_ACCOUNT} --key-file=${GCP_CREDENTIALS} --project=${GCP_PROJECT}"
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
                    def secretTemplate = readFile '/pipeline_data/k8s/secrets/mongo-credentials-template.yaml'
                    withCredentials([string(credentialsId: 'url_mongo', variable: 'MONGO_URL')]) {
                        def urlBase64 = sh(script: "echo -n \$MONGO_URL | base64", returnStdout: true).trim()
                    }
                    def usernameBase64 = sh(script: "echo -n '${params.MONGO_USERNAME}' | base64", returnStdout: true).trim()
                    withCredentials([string(credentialsId: 'passwd_mongo', variable: 'MONGO_PASSWORD')]) {
                        def passwordBase64 = sh(script: "echo -n \$MONGO_PASSWORD | base64", returnStdout: true).trim()
                    }
                    def secretYaml = secretTemplate.replaceAll('\\${MONGO_USERNAME}', usernameBase64).replaceAll('\\${MONGO_PASSWORD}', passwordBase64).replaceAll('\\${MONGO_URL}', urlBase64)
                    writeFile file: 'secret.yaml', text: secretYaml
                    sh 'kubectl apply -f secret.yaml'
                    sh 'kubectl create secret tls certificate --cert=/pipeline_data/k8s/secrets/cert/cert.pem --key=/pipeline_data/k8s/secrets/cert/privkey.pem'
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
                sh "/google-cloud-sdk/bin/gcloud container clusters get-credentials ${GKE_CLUSTER} --zone ${GKE_ZONE}"
                sh "kubectl apply -f /pipeline_data/k8s/deployments/app-deployment --namespace=${K8S_NAMESPACE}"
                sh "kubectl apply -f /pipeline_data/k8s/deployments/app-service --namespace=${K8S_NAMESPACE}"
                sh "kubectl apply -f /pipeline_data/k8s/deployments/app-ingress --namespace=${K8S_NAMESPACE}"
                sh "kubectl apply -f /pipeline_data/k8s/deployments/mongo-deployment --namespace=${K8S_NAMESPACE}"
                sh "kubectl apply -f /pipeline_data/k8s/deployments/mongo-service --namespace=${K8S_NAMESPACE}"
            }
        }
    }
}