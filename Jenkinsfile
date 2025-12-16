pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION    = "true"
        AWS_DEFAULT_REGION = "us-east-1"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare SSH Key') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ansible-ssh-key',
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    sh '''
                        cp $SSH_KEY /tmp/ansible_key.pem
                        chmod 600 /tmp/ansible_key.pem
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh 'terraform init -no-color'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        terraform plan -no-color \
                        -out=tfplan \
                        -var="private_key_path=/tmp/ansible_key.pem"
                    '''
                }
            }
        }

        stage('Approval: Terraform Apply') {
            steps {
                script {
                    def decision = input(
                        message: 'Terraform plan completed. Apply changes?',
                        parameters: [
                            choice(name: 'ACTION', choices: ['Apply', 'Abort'], description: '')
                        ]
                    )

                    if (decision == 'Abort') {
                        error "Terraform Apply aborted by user"
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        terraform apply -auto-approve -no-color tfplan
                    '''
                }
            }
        }

        stage('Approval: Ansible Configuration') {
            steps {
                script {
                    def decision = input(
                        message: 'Run Ansible configuration?',
                        parameters: [
                            choice(name: 'ACTION', choices: ['Apply', 'Abort'], description: '')
                        ]
                    )

                    if (decision == 'Abort') {
                        echo "Ansible execution skipped by user"
                        currentBuild.result = 'SUCCESS'
                        return
                    }
                }
            }
        }

        stage('Run Ansible') {
            steps {
                sh '''
                    ansible-playbook -i ansible/inventory.ini \
                    ansible/playbook.yml \
                    --private-key /tmp/ansible_key.pem
                '''
            }
        }
    }

    post {
        always {
            script {
                def destroyChoice = input(
                    message: 'Do you want to destroy the infrastructure?',
                    parameters: [
                        choice(name: 'DESTROY', choices: ['No', 'Yes'], description: '')
                    ]
                )

                if (destroyChoice == 'Yes') {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            terraform destroy -auto-approve -no-color \
                            -var="private_key_path=/tmp/ansible_key.pem"
                        '''
                    }
                } else {
                    echo "Infrastructure retained"
                }
            }
        }
    }
}
