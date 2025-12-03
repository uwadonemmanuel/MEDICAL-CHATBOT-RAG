pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-north-1'
        ECR_REPO = 'rag-medical-repo'
        IMAGE_TAG = 'latest'
        // SERVICE_NAME = 'llmops-medical-service'
    }

    stages {
        stage('Clone GitHub Repo') {
            steps {
                script {
                    echo 'Cloning GitHub repo to Jenkins...'
                    checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'github-token', url: 'https://github.com/uwadonemmanuel/MEDICAL-CHATBOT-RAG.git']])
                }
            }
        }

        stage('Build, Scan, and Push Docker Image to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    script {
                        def accountId = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                        def ecrUrl = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}"
                        def imageFullTag = "${ecrUrl}:${IMAGE_TAG}"
                        def cacheImage = "${ecrUrl}:cache"

                        // Build with BuildKit for cache mounts and layer caching
                        // BuildKit cache mounts are defined in Dockerfile and work without Jenkins cache plugin
                        sh """
                        export DOCKER_API_VERSION=1.43
                        
                        # Login to ECR
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUrl}
                        
                        # Pull cache image if it exists (for layer caching)
                        docker pull ${cacheImage} || echo 'Cache image not found, will create new'
                        
                        # Build with BuildKit for cache mounts and layer caching
                        # BuildKit cache mounts are defined in Dockerfile
                        DOCKER_BUILDKIT=1 docker build \
                            --build-arg BUILDKIT_INLINE_CACHE=1 \
                            --cache-from ${cacheImage} \
                            -t ${env.ECR_REPO}:${IMAGE_TAG} \
                            -t ${cacheImage} \
                            .
                        
                        # Scan image
                        trivy image --severity HIGH,CRITICAL --format json -o trivy-report.json ${env.ECR_REPO}:${IMAGE_TAG} || true
                        
                        # Tag and push main image
                        docker tag ${env.ECR_REPO}:${IMAGE_TAG} ${imageFullTag}
                        docker push ${imageFullTag}
                        
                        # Push cache image for next build
                        docker push ${cacheImage} || echo 'Failed to push cache image, continuing...'
                        """

                        archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Deploy to AWS Fargate') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    script {
                        def accountId = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                        def ecrUrl = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}"
                        def imageFullTag = "${ecrUrl}:${IMAGE_TAG}"
                        def clusterName = "rag-medical-chatbot-cluster"
                        def serviceName = "rag-medical-chatbot-service"
                        def taskFamily = "medical-chatbot-rag-task"

                        echo "Deploying to AWS Fargate..."
                        echo "Cluster: ${clusterName}"
                        echo "Service: ${serviceName}"
                        echo "Task Family: ${taskFamily}"
                        echo "Image: ${imageFullTag}"

                        // Check if task definition exists, then update it
                        sh """
                        # Check if task definition exists
                        if ! aws ecs describe-task-definition --task-definition ${taskFamily} --region ${AWS_REGION} --query 'taskDefinition.taskDefinitionArn' --output text > /dev/null 2>&1; then
                            echo "ERROR: Task definition '${taskFamily}' does not exist!"
                            echo ""
                            echo "Please create the task definition manually first:"
                            echo "1. Go to AWS Console → ECS → Task definitions"
                            echo "2. Click 'Create new task definition'"
                            echo "3. Configure with:"
                            echo "   - Family: ${taskFamily}"
                            echo "   - Launch type: Fargate"
                            echo "   - Image: ${imageFullTag}"
                            echo "   - Port: 5000"
                            echo "   - Environment variables: GROQ_API_KEY, HF_TOKEN, PYTHONUNBUFFERED=1"
                            echo "4. After creating the task definition, run this pipeline again."
                            echo ""
                            echo "See FULL_DOCUMENTATION.md section 'Deployment to AWS Fargate' for detailed instructions."
                            exit 1
                        fi

                        # Get the current task definition and update image using Python
                        python3 << 'PYTHON_SCRIPT'
import json
import subprocess
import sys

task_family = '${taskFamily}'
region = '${AWS_REGION}'
new_image = '${imageFullTag}'

# Get current task definition
result = subprocess.run(
    ['aws', 'ecs', 'describe-task-definition', '--task-definition', task_family, '--region', region, '--query', 'taskDefinition', '--output', 'json'],
    capture_output=True,
    text=True
)

if result.returncode != 0:
    print(f"Error getting task definition: {result.stderr}", file=sys.stderr)
    sys.exit(1)

task_def = json.loads(result.stdout)

# Update image in container definitions
if len(task_def.get('containerDefinitions', [])) == 0:
    print("Error: Task definition has no container definitions", file=sys.stderr)
    sys.exit(1)

task_def['containerDefinitions'][0]['image'] = new_image

# Remove fields that shouldn't be in new task definition
fields_to_remove = ['taskDefinitionArn', 'revision', 'status', 'requiresAttributes', 'compatibilities', 'registeredAt', 'registeredBy']
for field in fields_to_remove:
    task_def.pop(field, None)

# Register new task definition
register_result = subprocess.run(
    ['aws', 'ecs', 'register-task-definition', '--cli-input-json', json.dumps(task_def), '--region', region],
    capture_output=True,
    text=True
)

if register_result.returncode != 0:
    print(f"Error registering task definition: {register_result.stderr}", file=sys.stderr)
    sys.exit(1)

print("Task definition registered successfully")
PYTHON_SCRIPT

                        # Check if service exists before updating
                        if aws ecs describe-services --cluster ${clusterName} --services ${serviceName} --region ${AWS_REGION} --query 'services[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
                            # Update service to use new task definition (will use latest revision)
                            aws ecs update-service \
                                --cluster ${clusterName} \
                                --service ${serviceName} \
                                --task-definition ${taskFamily} \
                                --force-new-deployment \
                                --region ${AWS_REGION}
                            
                            echo "Deployment initiated. Fargate service will pull the new image from ECR."
                            echo "Monitor deployment status in AWS Console: ECS → Clusters → ${clusterName} → Services → ${serviceName}"
                        else
                            echo "WARNING: Service '${serviceName}' does not exist in cluster '${clusterName}'."
                            echo "Task definition has been updated with new image, but service update was skipped."
                            echo "Please create the service manually or update it through AWS Console."
                        fi
                        """
                    }
                }
            }
        }
    }
}