pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        // =====================================================
        // 1️⃣ CHECKOUT CODE
        // =====================================================
        stage('1️⃣ Checkout Code') {
            steps {
                checkout scm
            }
        }

        // =====================================================
        // 2️⃣ SETUP SSH KEY
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
                        echo "✅ SSH key ready"
                    '''
                }
            }
        }

        // =====================================================
        // 3️⃣ TERRAFORM INIT
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
        // 4️⃣ TERRAFORM PLAN
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
        // 5️⃣ APPROVE APPLY (only on dev branch)
        // =====================================================
        stage('5️⃣ Approve Terraform Apply') {
            when {
                expression {
                    return (env.BRANCH_NAME == 'dev') || (env.GIT_BRANCH != null && env.GIT_BRANCH.contains('dev'))
                }
            }
            steps {
                input message: 'Proceed with Terraform Apply?'
            }
        }

        // =====================================================
        // 6️⃣ TERRAFORM APPLY
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
        // 6️⃣.1️⃣ GENERATE ANSIBLE INVENTORY (SINGLE SOURCE OF TRUTH)
        // =====================================================
        stage('6️⃣.1️⃣ Generate Ansible Inventory') {
            steps {
                sh '''
                    set -euo pipefail
                    EC2_IP=""
                    for i in {1..6}; do
                      EC2_IP=$(terraform output -raw instance_public_ip 2>/dev/null || true)
                      [ -n "$EC2_IP" ] && break || sleep 2
                    done

                    if [ -z "$EC2_IP" ]; then
                      echo "ERROR: could not read instance_public_ip from terraform output"
                      exit 1
                    fi

                    mkdir -p ansible
                    rm -f ansible/inventory.ini

                    cat > ansible/inventory.ini <<EOF
[aws]
${EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${WORKSPACE}/devops.pem ansible_python_interpreter=/usr/bin/python3 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

                    echo "✅ Inventory generated:"
                    cat ansible/inventory.ini
                '''
            }
        }

        // =====================================================
        // 7️⃣ WAIT FOR EC2 SSH
        // =====================================================
        stage('7️⃣ Wait for EC2 SSH') {
            steps {
                sh '''
                    set -euo pipefail
                    EC2_IP=""
                    for i in {1..6}; do
                      EC2_IP=$(terraform output -raw instance_public_ip 2>/dev/null || true)
                      [ -n "$EC2_IP" ] && break || sleep 2
                    done

                    if [ -z "$EC2_IP" ]; then
                      echo "ERROR: could not read instance_public_ip from terraform output"
                      exit 1
                    fi

                    echo "⏳ Waiting for SSH on $EC2_IP..."

                    for i in {1..12}; do
                        ssh -o StrictHostKeyChecking=no \
                            -o ConnectTimeout=5 \
                            -i devops.pem ubuntu@$EC2_IP "echo SSH READY" && break
                        sleep 10
                    done
                '''
            }
        }

        // =====================================================
        // 8️⃣ VALIDATE ANSIBLE INVENTORY
        // =====================================================
        stage('8️⃣ Validate Ansible Inventory') {
            steps {
                sh '''
                    ansible --version
                    ansible-inventory -i ansible/inventory.ini --list
                    ansible all -i ansible/inventory.ini -m ping
                '''
            }
        }

        // =====================================================
        // 9️⃣ APPROVE ANSIBLE (only on dev branch)
        // =====================================================
        stage('9️⃣ Approve Ansible') {
            when {
                expression {
                    return (env.BRANCH_NAME == 'dev') || (env.GIT_BRANCH != null && env.GIT_BRANCH.contains('dev'))
                }
            }
            steps {
                input message: 'Run Ansible Playbook?'
            }
        }

        // =====================================================
        // 🔟 RUN ANSIBLE PLAYBOOK
        // =====================================================
        stage('🔟 Run Ansible Playbook') {
            steps {
                sh '''
                    ansible-playbook \
                      -i ansible/inventory.ini \
                      ansible/playbook.yml -v
                '''
            }
        }

        // =====================================================
        // 1️⃣1️⃣ TERRAFORM OUTPUT
        // =====================================================
        stage('1️⃣1️⃣ Terraform Output') {
            steps {
                sh 'terraform output'
            }
        }

        // =====================================================
        // 1️⃣2️⃣ APPROVE DESTROY
        // =====================================================
        stage('1️⃣2️⃣ Approve Destroy') {
            steps {
                input message: 'Destroy all infrastructure?'
            }
        }

        // =====================================================
        // 1️⃣3️⃣ TERRAFORM DESTROY
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
                rm -f devops.pem tfplan || true
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