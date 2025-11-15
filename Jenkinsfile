pipeline {
    agent any

    parameters {
        choice(name: 'TERRAFORM_ACTION', choices: ['apply', 'destroy'], description: 'Terraform action to perform')
    }

    stages {

        stage('Build') {
            steps {
                cleanWs()
                echo 'Building the dockerfile...'
                sh 'docker build -t python-app .'
            }
        }

        stage('Authenticate to GAR') {
            steps {
                echo "Authenticating to Google Artifact Registry..."

                withCredentials([file(credentialsId: 'gar-key', variable: 'GCLOUD_KEY')]) {
                    sh '''
                        echo "Activating service account..."
                        gcloud auth activate-service-account --key-file=$GCLOUD_KEY

                        echo "Configuring Docker authentication for GAR..."
                        gcloud auth configure-docker us-docker.pkg.dev
                    '''
                }
            }
        }

        stage('Push image to GAR') {
            steps {
                echo 'Pushing image to GAR...'
                sh 'docker tag python-app:latest us-docker.pkg.dev/fifth-medley-478216-a7/docker/python-app:v1'
                sh 'docker push us-docker.pkg.dev/fifth-medley-478216-a7/docker/python-app:v1'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.TERRAFORM_ACTION == 'apply' }
            }
            steps {
                withCredentials([file(credentialsId: 'gar-key', variable: 'GCLOUD_KEY')]) {
                    sh '''
                        echo "Activating service account for Terraform..."
                        gcloud auth activate-service-account --key-file=$GCLOUD_KEY
                        export GOOGLE_APPLICATION_CREDENTIALS=$GCLOUD_KEY
                    '''

                    echo 'Running Terraform apply...'

                    dir('Terraform') {
                        sh 'terraform init'
                        sh 'terraform apply --auto-approve'
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.TERRAFORM_ACTION == 'destroy' }
            }
            steps {
                withCredentials([file(credentialsId: 'gar-key', variable: 'GCLOUD_KEY')]) {
                    sh '''
                        echo "Activating service account for Terraform..."
                        gcloud auth activate-service-account --key-file=$GCLOUD_KEY
                        export GOOGLE_APPLICATION_CREDENTIALS=$GCLOUD_KEY
                    '''

                    echo 'Running Terraform destroy...'

                    dir('Terraform') {
                        sh 'terraform init'
                        sh 'terraform destroy --auto-approve'
                    }
                }
            }
        }

        stage('Ansible') {
            steps {
                echo 'Running Ansible playbook...'
                sh 'ansible-playbook -i inventory.ini playbook.yml'
            }
        }

        stage('Docker Swarm Deploy') {
            steps {
                echo 'Deploying to Docker Swarm...'
                sh 'docker stack deploy -c docker-stack.yml mystack'
            }
        }
    }
}
