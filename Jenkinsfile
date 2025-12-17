pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        TF_INPUT = 'false'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        // =====================================================
        // STAGE 1: CHECKOUT CODE
        // =====================================================
        stage('1️⃣ Checkout Code') {
            steps {
                checkout scm
            }
        }

        // =====================================================
        // STAGE 2: SETUP SSH KEY (master-key.pem)
        // =====================================================
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
                        echo "SSH key ready"
                    '''
                }
            }
        }

        // =====================================================
        // STAGE 3: TERRAFORM INIT
        // =====================================================
        stage('3️⃣ Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        terraform --version
                        terraform init -input=false
                    '''
                }
            }
        }

        // =====================================================
        // STAGE 4: TERRAFORM PLAN (FIXED private_key_path)
        // =====================================================
        stage('4️⃣ Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        terraform plan \
                        -var="private_key_path=${WORKSPACE}/devops.pem" \
                        -out=tfplan
                    '''
                }
            }
        }

        // =====================================================
        // STAGE 5: APPROVE APPLY
        // =====================================================
        stage('5️⃣ Approve Terraform Apply') {
            steps {
                input message: 'Proceed with Terraform Apply?'
            }
        }

        // =====================================================
        // STAGE 6: TERRAFORM APPLY
        // =====================================================
        stage('6️⃣ Terraform Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        terraform apply \
                        -var="private_key_path=${WORKSPACE}/devops.pem" \
                        -auto-approve tfplan
                    '''
                }
            }
        }

        // =====================================================
        // STAGE 7: WAIT FOR EC2 SSH
        // =====================================================
        stage('7️⃣ Wait for EC2 SSH') {
            steps {
                sh '''
                    echo "Waiting for EC2 SSH..."
                    sleep 30

                    while IFS= read -r ip; do
                        [[ $ip =~ ^[0-9]+\\. ]] || continue
                        echo "Checking SSH on $ip"
                        ssh -o StrictHostKeyChecking=no \
                            -o ConnectTimeout=5 \
                            -i devops.pem ubuntu@$ip "echo SSH Ready"
                    done < aws_hosts
                '''
            }
        }

        // =====================================================
        // STAGE 8: VALIDATE ANSIBLE INVENTORY
        // =====================================================
        stage('8️⃣ Validate Ansible Inventory') {
            steps {
                dir('ansible') {
                    sh '''
                        ansible --version
                        ansible all -i inventory.ini -m ping
                    '''
                }
            }
        }

        // =====================================================
        // STAGE 9: APPROVE ANSIBLE
        // =====================================================
        stage('9️⃣ Approve Ansible') {
            steps {
                input message: 'Run Ansible Playbook?'
            }
        }

        // =====================================================
        // STAGE 10: RUN ANSIBLE PLAYBOOK
        // =====================================================
        stage('🔟 Run Ansible Playbook') {
            steps {
                dir('ansible') {
                    sh '''
                        ansible-playbook \
                        -i inventory.ini \
                        playbook.yml -v
                    '''
                }
            }
        }

        // =====================================================
        // STAGE 11: TERRAFORM OUTPUT
        // =====================================================
        stage('1️⃣1️⃣ Terraform Output') {
            steps {
                sh 'terraform output'
            }
        }

        // =====================================================
        // STAGE 12: APPROVE DESTROY
        // =====================================================
        stage('1️⃣2️⃣ Approve Destroy') {
            steps {
                input message: 'Destroy all infrastructure?'
            }
        }

        // =====================================================
        // STAGE 13: TERRAFORM DESTROY
        // =====================================================
        stage('1️⃣3️⃣ Terraform Destroy') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        terraform destroy \
                        -var="private_key_path=${WORKSPACE}/devops.pem" \
                        -auto-approve
                    '''
                }
            }
        }
    }

    // =====================================================
    // CLEANUP
    // =====================================================
    post {
        always {
            sh '''
                rm -f devops.pem || true
                rm -f tfplan || true
            '''
        }

        success {
            echo '✅ Pipeline completed successfully'
        }

        failure {
            echo '❌ Pipeline failed — check logs above'
        }
    }
}
