pipeline {
    agent any

    parameters {
        choice(name: 'TERRAFORM_ACTION', choices: ['apply', 'destroy'], description: 'Terraform action to perform')
    }

    stages {

        stage('Build') {
            when { expression { params.TERRAFORM_ACTION == 'apply' } }
            steps {
                echo 'Building the dockerfile...'
                sh 'docker build -t python-app .'
            }
        }

        stage('Authenticate to GAR') {
            when { expression { params.TERRAFORM_ACTION == 'apply' } }
            steps {
                echo "Authenticating to Google Artifact Registry..."

                withCredentials([file(credentialsId: 'gar-key', variable: 'GCLOUD_KEY')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GCLOUD_KEY
                        gcloud auth configure-docker us-docker.pkg.dev
                    '''
                }
            }
        }

        stage('Push image to GAR') {
            when { expression { params.TERRAFORM_ACTION == 'apply' } }
            steps {
                echo 'Pushing image to GAR...'
                sh '''
                    docker tag python-app:latest us-docker.pkg.dev/fifth-medley-478216-a7/docker/python-app:v1
                    docker push us-docker.pkg.dev/fifth-medley-478216-a7/docker/python-app:v1
                '''
            }
        }

        stage('Terraform Apply') {
            when { expression { params.TERRAFORM_ACTION == 'apply' } }
            steps {
                withCredentials([file(credentialsId: 'gar-key', variable: 'GCLOUD_KEY')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GCLOUD_KEY
                        export GOOGLE_APPLICATION_CREDENTIALS=$GCLOUD_KEY
                        cd Terraform
                        terraform init
                        terraform apply --auto-approve
                    '''
                }
            }
        }

        stage('Terraform Destroy') {
            when { expression { params.TERRAFORM_ACTION == 'destroy' } }
            steps {
                withCredentials([file(credentialsId: 'gar-key', variable: 'GCLOUD_KEY')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GCLOUD_KEY
                        export GOOGLE_APPLICATION_CREDENTIALS=$GCLOUD_KEY
                        cd Terraform
                        terraform init
                        terraform destroy --auto-approve
                    '''
                }
            }
        }



        stage('Fix Key Permissions') {
            when { expression { params.TERRAFORM_ACTION == 'apply' } }
            steps {
                sh 'chmod 600 Terraform/id_rsa'
            }
        }

        stage('Generate Dynamic Inventory File') {
            when { expression { params.TERRAFORM_ACTION == 'apply' } }
            steps {
                
                sh " chmod +x inventory.py"
            }
        }

        stage('Ansible') {
            when { expression { params.TERRAFORM_ACTION == 'apply' } }
            steps {
                sh '''
                    
                    

                    export ANSIBLE_HOST_KEY_CHECKING=False 
                    ansible-playbook -i inventory.py play.yaml \
                        --ssh-extra-args="-o StrictHostKeyChecking=no"
                '''
            }
        }
    }
}
