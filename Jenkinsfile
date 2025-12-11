pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
    }

    stages {

        stage('Init') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'aws-creds', variable: 'TF_CLI_CONFIG_FILE')]) {
                        sh '''
                            echo ">>> Showing workspace files"
                            ls -al

                            echo ">>> Terraform Init Starting"
                            terraform init -no-color
                        '''
                    }
                }
            }
        }

        stage('Plan') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'aws-creds', variable: 'TF_CLI_CONFIG_FILE')]) {
                        sh '''
                            echo ">>> Terraform Plan "
                            terraform plan -no-color
                        '''
                    }
                }
            }
        }
    }
}
