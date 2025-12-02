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

                        // Create persistent pip cache directory in Jenkins workspace
                        sh """
                        mkdir -p \${WORKSPACE}/.pip-cache
                        """

                        // Use Jenkins cache to persist pip cache between builds
                        // Note: Requires Pipeline Cache Plugin (install via Manage Jenkins > Plugins)
                        try {
                            cache(maxCacheSize: 500, caches: [
                                [$class: 'ArbitraryFileCache', path: '.pip-cache']
                            ]) {
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
                            }
                        } catch (Exception e) {
                            // Fallback if cache plugin not available - still use BuildKit cache mounts
                            echo "Cache plugin not available, using BuildKit cache mounts only: ${e.message}"
                            sh """
                            export DOCKER_API_VERSION=1.43
                            
                            # Login to ECR
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUrl}
                            
                            # Pull cache image if it exists
                            docker pull ${cacheImage} || echo 'Cache image not found'
                            
                            # Build with BuildKit (cache mounts work without Jenkins cache plugin)
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
                            
                            # Push cache image
                            docker push ${cacheImage} || echo 'Failed to push cache image'
                            """
                        }

                        archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                    }
                }
            }
        }

//         stage('Deploy to AWS Fargate') {
//             steps {
//                 withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
//                     script {
//                         def accountId = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
//                         def ecrUrl = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}"
//                         def imageFullTag = "${ecrUrl}:${IMAGE_TAG}"
//                         def clusterName = "rag-medical-chatbot-cluster"
//                         def serviceName = "rag-medical-chatbot-service"
//                         def taskFamily = "rag-medical-chatbot-task"

//                         echo "Deploying to AWS Fargate..."
//                         echo "Cluster: ${clusterName}"
//                         echo "Service: ${serviceName}"
//                         echo "Task Family: ${taskFamily}"
//                         echo "Image: ${imageFullTag}"

//                         // Register new task definition with updated image using Python
//                         sh """
//                         # Get the current task definition and update image using Python
//                         python3 << 'PYTHON_SCRIPT'
// import json
// import subprocess
// import sys

// task_family = '${taskFamily}'
// region = '${AWS_REGION}'
// new_image = '${imageFullTag}'

// # Get current task definition
// result = subprocess.run(
//     ['aws', 'ecs', 'describe-task-definition', '--task-definition', task_family, '--region', region, '--query', 'taskDefinition', '--output', 'json'],
//     capture_output=True,
//     text=True
// )

// if result.returncode != 0:
//     print(f"Error getting task definition: {result.stderr}", file=sys.stderr)
//     sys.exit(1)

// task_def = json.loads(result.stdout)

// # Update image in container definitions
// task_def['containerDefinitions'][0]['image'] = new_image

// # Remove fields that shouldn't be in new task definition
// fields_to_remove = ['taskDefinitionArn', 'revision', 'status', 'requiresAttributes', 'compatibilities', 'registeredAt', 'registeredBy']
// for field in fields_to_remove:
//     task_def.pop(field, None)

// # Register new task definition
// register_result = subprocess.run(
//     ['aws', 'ecs', 'register-task-definition', '--cli-input-json', json.dumps(task_def), '--region', region],
//     capture_output=True,
//     text=True
// )

// if register_result.returncode != 0:
//     print(f"Error registering task definition: {register_result.stderr}", file=sys.stderr)
//     sys.exit(1)

// print("Task definition registered successfully")
// PYTHON_SCRIPT

//                         # Update service to use new task definition (will use latest revision)
//                         aws ecs update-service \
//                             --cluster ${clusterName} \
//                             --service ${serviceName} \
//                             --task-definition ${taskFamily} \
//                             --force-new-deployment \
//                             --region ${AWS_REGION}

//                         echo "Deployment initiated. Fargate service will pull the new image from ECR."
//                         echo "Monitor deployment status in AWS Console: ECS → Clusters → ${clusterName} → Services → ${serviceName}"
//                         """
//                     }
//                 }
//             }
//         }
    }
}