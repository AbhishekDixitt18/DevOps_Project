pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        PATH = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin"
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }
    
    stages {

        // ========================================
        // STAGE 1: CODE CHECKOUT
        // ========================================
        stage('1️⃣ Checkout Code') {
            steps {
                echo '📥 Checking out code from GitHub...'
                checkout scm
            }
        }
        
        // ========================================
        // STAGE 2: SETUP SSH KEY (JENKINS CREDENTIAL)
        // ========================================
        stage('2️⃣ Setup SSH Key') {
            steps {
                echo '🔑 Setting up SSH key from Jenkins credentials...'
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ansible-ssh-key',
                        keyFileVariable: 'SSH_KEY'
                    )
                ]) {
                    sh '''
                        cp "$SSH_KEY" devops.pem
                        chmod 600 devops.pem
                        echo "✅ SSH key prepared successfully"
                    '''
                }
            }
        }
        
        // ========================================
        // STAGE 3: TERRAFORM INITIALIZATION
        // ========================================
        stage('3️⃣ Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        echo '🔧 Initializing Terraform...'
                        sh 'terraform init'
                    }
                }
            }
        }
        
        // ========================================
        // STAGE 4: TERRAFORM PLAN
        // ========================================
        stage('4️⃣ Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh '''
                            terraform plan -out=tfplan
                            echo ""
                            echo "=== Plan Summary ==="
                            terraform show tfplan | grep -E "Plan:|No changes"
                        '''
                    }
                }
            }
        }
        
        // ========================================
        // STAGE 5: APPROVE TERRAFORM
        // ========================================
        stage('5️⃣ Approve Terraform Plan') {
            steps {
                input message: 'Review Terraform plan. Proceed with infrastructure creation?',
                      ok: 'Yes, Create Infrastructure'
            }
        }
        
        // ========================================
        // STAGE 6: TERRAFORM APPLY
        // ========================================
        stage('6️⃣ Terraform Apply - Infrastructure') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }
        
        // ========================================
        // STAGE 7: WAIT FOR INSTANCES
        // ========================================
        stage('7️⃣ Wait for AWS Instances') {
            steps {
                sh '''
                    sleep 30
                    cd playbooks
                    while IFS= read -r ip; do
                        [[ $ip =~ ^[0-9]+\\. ]] || continue
                        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                            -i ../devops.pem ubuntu@$ip "echo Connected"
                    done < aws_hosts
                '''
            }
        }
        
        // ========================================
        // STAGE 8: VALIDATE ANSIBLE INVENTORY
        // ========================================
        stage('8️⃣ Validate Ansible Inventory') {
            steps {
                dir('playbooks') {
                    sh '''
                        cat aws_hosts
                        ansible --version
                        ANSIBLE_CONFIG=./ansible.cfg ansible all -i aws_hosts -m ping || true
                    '''
                }
            }
        }
        
        // ========================================
        // STAGE 9: APPROVE ANSIBLE
        // ========================================
        stage('9️⃣ Approve Ansible Configuration') {
            steps {
                input message: 'Proceed with Grafana & Prometheus installation?',
                      ok: 'Yes, Run Ansible'
            }
        }
        
        // ========================================
        // STAGE 10: INSTALL GRAFANA
        // ========================================
        stage('🔟 Ansible - Install Grafana') {
            steps {
                dir('playbooks') {
                    sh 'ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i aws_hosts grafana.yaml -v'
                }
            }
        }
        
        // ========================================
        // STAGE 11: INSTALL PROMETHEUS
        // ========================================
        stage('1️⃣1️⃣ Ansible - Install Prometheus') {
            steps {
                dir('playbooks') {
                    sh 'ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i aws_hosts install-prometheus.yaml -v'
                }
            }
        }
        
        // ========================================
        // STAGE 12: VERIFY DEPLOYMENT
        // ========================================
        stage('1️⃣2️⃣ Verify Deployment') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform output
                    '''
                }
            }
        }
        
        // ========================================
        // STAGE 13: APPROVE DESTROY
        // ========================================
        stage('1️⃣3️⃣ Approve Destroy') {
            steps {
                input message: '⚠ Destroy all infrastructure?',
                      ok: 'Yes, Destroy Everything'
            }
        }
        
        // ========================================
        // STAGE 14: TERRAFORM DESTROY
        // ========================================
        stage('1️⃣4️⃣ Terraform Destroy') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh 'terraform destroy -auto-approve'
                    }
                }
            }
        }
    }
    
    post {
        always {
            sh '''
                rm -f devops.pem || true
                rm -f terraform/tfplan || true
            '''
        }
    }
}