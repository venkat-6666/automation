pipeline{
    agent any
    parameters {
        choice(name: 'TERRAFORM_ACTION', choices: ['apply', 'destroy'], description: 'Terraform action to perform')
    }
    stages {
        stage('Build') {
            steps {
                echo 'Building the dockerfile...'
                dir
                sh 'docker build -t python-app .'
            }
        }

       
        stage('push image to GAR') {
            steps {
                echo 'pushing image to GAR...'
                sh "docker tag python-app:latest us-central1-docker.pkg.dev/venkat-473005/demo/python-app:v1"
                sh "docker push us-central1-docker.pkg.dev/venkat-473005/demo/python-app:v1"
            }
        }
        stage('Terraform ') {
            when {
                expression {params.TERRAFORM_ACTION == 'apply'}
            }
            steps {
                echo 'Terraform init and apply...'
                dir('terraform') {
                 sh ' terraform init .'
                 sh " terraform apply --auto-approve"
                
                }
          }
        stage("destroy") {
            when {
                expression {params.TERRAFORM_ACTION == 'destroy' }
            }
            steps {
                echo 'Terraform destroy...'
                sh  "terraform destroy --auto-approve"
            }
        }
        stage("Ansible") {
            steps {
                echo 'Running ansible playbook...'
                sh 'ansible-playbook -i inventory.ini playbook.yml'
            }
        }
        stage("docker swarm") {
            steps {
                echo 'Deploying to Docker Swarm...'
                sh 'docker stack deploy -c docker-stack.yml mystack'
            }
        }
    }
}
}
