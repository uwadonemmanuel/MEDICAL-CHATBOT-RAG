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
                    checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'github-token', url: 'https://github.com/uwadonemmanuel/RAG-MEDICAL-CHATBOT.git']])
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

        stage('Deploy to AWS Elastic Beanstalk') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    script {
                        def accountId = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                        def ecrUrl = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}"
                        def imageFullTag = "${ecrUrl}:${IMAGE_TAG}"
                        def appName = "rag-medical-chatbot"
                        def envName = "rag-medical-chatbot-prod"

                        echo "Deploying to AWS Elastic Beanstalk..."
                        echo "Application: ${appName}"
                        echo "Environment: ${envName}"
                        echo "Image: ${imageFullTag}"

                        // Update Elastic Beanstalk environment Docker configuration
                        sh """
                        # Update the Docker image in Elastic Beanstalk environment
                        aws elasticbeanstalk update-environment \
                            --application-name ${appName} \
                            --environment-name ${envName} \
                            --option-settings \
                                Namespace=aws:elasticbeanstalk:application:environment,OptionName=DOCKER_IMAGE,Value=${imageFullTag} \
                            --region ${AWS_REGION}

                        echo "Deployment initiated. Elastic Beanstalk will pull the new image from ECR."
                        echo "Monitor deployment status in AWS Console."
                        """
                    }
                }
            }
        }
    }
}