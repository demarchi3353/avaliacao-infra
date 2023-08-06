pipeline {
    agent any
    
    stages {
        stage('Auth GCP') {
            steps {
                sh '''
                    export PATH=$PATH:/google-cloud-sdk/bin
                    /google-cloud-sdk/bin/gcloud auth activate-service-account ${GCP_SERVICE_ACCOUNT} --key-file=${GCP_CREDENTIALS} --project=${GCP_PROJECT}
                '''
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

        stage('Set Kubernetes Context') {
            steps {
                sh '''
                    export PATH=$PATH:/google-cloud-sdk/bin
                    gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${CLUSTER_ZONE} --project ${GCP_PROJECT}
                '''
            }
        }

        stage('Create Secrets') {
            steps {
                script {
                    def secretTemplate = readFile '/pipeline_data/k8s/secrets/mongo-credentials-template.yaml'
                    def urlBase64
                    withCredentials([string(credentialsId: 'url_mongo', variable: 'MONGO_URL')]) {
                        urlBase64 = sh(script: "echo -n \$MONGO_URL | base64", returnStdout: true).trim()
                    }
                    def usernameBase64
                    withCredentials([string(credentialsId: 'mongo_username', variable: 'MONGO_USERNAME')]) {
                        usernameBase64 = sh(script: "echo -n \$MONGO_USERNAME | base64", returnStdout: true).trim()
                    }
                    def passwordBase64
                    withCredentials([string(credentialsId: 'passwd_mongo', variable: 'MONGO_PASSWORD')]) {
                        passwordBase64 = sh(script: "echo -n \$MONGO_PASSWORD | base64", returnStdout: true).trim()
                    }
                    def secretYaml = secretTemplate.replace('${MONGO_USERNAME}', usernameBase64).replace('${MONGO_PASSWORD}', passwordBase64).replace('${MONGO_URL}', urlBase64)
                    writeFile file: 'secret.yaml', text: secretYaml

                    sh '''
                        export PATH=$PATH:/google-cloud-sdk/bin
                        cat secret.yaml
                        kubectl config current-context
                        kubectl config view
                        kubectl apply -f secret.yaml
                        kubectl create secret tls certificate --cert=/certs/cert.pem --key=/certs/privkey.pem
                    '''
                }
            }
        }

        stage('Deploy Nginx Ingress Controller') {
            steps {
                sh '''
                    export PATH=$PATH:/google-cloud-sdk/bin
                    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.0/deploy/static/provider/cloud/deploy.yaml
                '''                
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    export PATH=$PATH:/google-cloud-sdk/bin
                    kubectl apply -f /pipeline_data/k8s/deployments/app-deployment --namespace=${K8S_NAMESPACE}
                    kubectl apply -f /pipeline_data/k8s/deployments/app-service --namespace=${K8S_NAMESPACE}
                    kubectl apply -f /pipeline_data/k8s/deployments/app-ingress --namespace=${K8S_NAMESPACE}
                    kubectl apply -f /pipeline_data/k8s/deployments/mongo-deployment --namespace=${K8S_NAMESPACE}
                    kubectl apply -f /pipeline_data/k8s/deployments/mongo-service --namespace=${K8S_NAMESPACE}
                '''                     
            }
        }
    }
}