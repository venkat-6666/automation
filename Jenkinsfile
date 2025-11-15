pipeline {
    agent any

    parameters {
        choice(name: 'TERRAFORM_ACTION', choices: ['apply', 'destroy'], description: 'Terraform action to perform')
    }

    // environment {
    //     PATH = "/usr/local/bin:/usr/bin:/bin:/snap/bin"
    // }

    stages {

        stage('Build') {
            steps {
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
                sh '''
                    docker tag python-app:latest us-docker.pkg.dev/fifth-medley-478216-a7/docker/python-app:v1
                    docker push us-docker.pkg.dev/fifth-medley-478216-a7/docker/python-app:v1
                '''
            }
        }

        stage('Terraform') {
            when {
                expression { params.TERRAFORM_ACTION == 'apply' }
            }
            steps {
                echo 'Terraform init and apply...'
                dir('terraform') {
                    sh '''
                        terraform init
                        terraform apply --auto-approve
                    '''
                }
            }
        }

        stage('Destroy Terraform Resources') {
            when {
                expression { params.TERRAFORM_ACTION == 'destroy' }
            }
            steps {
                echo 'Terraform destroy...'
                dir('terraform') {
                    sh '''
                        terraform init
                        terraform destroy --auto-approve
                    '''
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
