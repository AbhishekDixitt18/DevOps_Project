pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }

    stages {

        stage('1️⃣ Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('2️⃣ Setup SSH Key') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ansible-ssh-key',
                        keyFileVariable: 'SSH_KEY'
                    )
                ]) {
                    sh '''
                        cp "$SSH_KEY" devops.pem
                        chmod 600 devops.pem
                    '''
                }
            }
        }

        stage('3️⃣ Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh 'terraform init'
                }
            }
        }

        stage('4️⃣ Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('5️⃣ Approve Terraform') {
            steps {
                input message: 'Proceed with Terraform Apply?'
            }
        }

        stage('6️⃣ Terraform Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('7️⃣ Wait for EC2 SSH') {
            steps {
                sh '''
                    sleep 30
                    while IFS= read -r ip; do
                        [[ $ip =~ ^[0-9]+\\. ]] || continue
                        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                            -i devops.pem ubuntu@$ip "echo Connected"
                    done < aws_hosts
                '''
            }
        }

        stage('8️⃣ Validate Ansible Inventory') {
            steps {
                dir('ansible') {
                    sh '''
                        ansible --version
                        ansible all -i inventory.ini -m ping || true
                    '''
                }
            }
        }

        stage('9️⃣ Approve Ansible') {
            steps {
                input message: 'Run Ansible playbook?'
            }
        }

        stage('🔟 Run Ansible Playbook') {
            steps {
                dir('ansible') {
                    sh 'ansible-playbook -i inventory.ini playbook.yml -v'
                }
            }
        }

        stage('1️⃣1️⃣ Terraform Output') {
            steps {
                sh 'terraform output'
            }
        }

        stage('1️⃣2️⃣ Approve Destroy') {
            steps {
                input message: 'Destroy all infrastructure?'
            }
        }

        stage('1️⃣3️⃣ Terraform Destroy') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }

    post {
        always {
            sh '''
                rm -f devops.pem || true
                rm -f tfplan || true
            '''
        }
    }
}

