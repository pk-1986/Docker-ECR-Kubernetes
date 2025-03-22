1. Prerequisites
Jenkins installed and configured.
AWS CLI and kubectl installed on the Jenkins server.
An EKS Cluster and ECR repository already set up.
Jenkins plugins installed:
Kubernetes CLI Plugin
Amazon EC2 Plugin
Pipeline Plugin
An IAM role or user with permissions for ECR, EKS, and necessary AWS services.
2. Dockerfile and Application Code
Ensure your project directory contains:

A Dockerfile defining how to build the Docker image.
Kubernetes manifest files (e.g., deployment.yaml, service.yaml).
A Jenkins pipeline script (Jenkinsfile).
3. Set Up Jenkins Pipeline
Create or update the Jenkinsfile in your repository:

#
groovy
Copy code
pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2' // Set your AWS region
        ECR_REPO_NAME = 'my-app-repo' // Your ECR repo name
        EKS_CLUSTER_NAME = 'my-eks-cluster' // Your EKS cluster name
        IMAGE_TAG = "${env.BUILD_NUMBER}" // Image tag using build number
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/your-repo.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${ECR_REPO_NAME}:${IMAGE_TAG}")
                }
            }
        }
        stage('Login to ECR') {
            steps {
                script {
                    sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    '''
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script {
                    sh '''
                    docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }
        stage('Update Kubernetes Deployment') {
            steps {
                script {
                    sh '''
                    aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER_NAME}
                    kubectl set image deployment/my-app-deployment my-app-container=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
4. Configure Jenkins Credentials
AWS Credentials:

Create an IAM user with programmatic access and permissions for ECR and EKS.
Add the credentials in Jenkins under Manage Jenkins > Credentials > System > Global credentials.
Docker Credentials (if needed):

Add Docker credentials for private repositories.
5. Set Up ECR Repository
Run this command to create an ECR repository if not already created:

bash
Copy code
aws ecr create-repository --repository-name my-app-repo --region us-west-2
6. Configure EKS Cluster
Ensure your Kubernetes deployment is ready and update the deployment.yaml file to use the ECR image. For example:

yaml
Copy code
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app-container
        image: <ECR_IMAGE_URL>
        ports:
        - containerPort: 80
Apply the initial configuration:

bash
Copy code
kubectl apply -f deployment.yaml
7. Trigger the Jenkins Pipeline
Whenever code is pushed to the repository:

Jenkins will pull the latest code.
Build a Docker image.
Push the image to ECR.
Update the Kubernetes deployment to use the new image.
8. Monitor and Validate
Use Jenkins logs to debug pipeline execution.
Use kubectl get pods and kubectl logs to monitor Kubernetes pods.
Would you like assistance with a specific part of this setup, such as EKS configuration, the Jenkinsfile, or AWS IAM permissions?







