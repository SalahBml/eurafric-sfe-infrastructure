pipeline {
    agent any

    parameters {
        string(name: 'ADMIN_USER', defaultValue: 'salah', description: 'Local admin username')
        password(name: 'ADMIN_PASS', defaultValue: '1234', description: 'Local admin password (Masked securely)')
    }

    environment {
        WORKSPACE_DIR = "/opt/test_multipass"
        TF_STATE_ID  = "null-null-null"
    }
    
    stages {
        stage('Security: IaC Scan') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    sh "tfsec . --soft-fail"
                }
            }
        }
        
        stage('Infrastructure: Provisioning') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    withCredentials([string(credentialsId: 'sfe-ssh-pub-key', variable: 'TF_VAR_ssh_public_key')]) {
                        sh """
                            terraform init
                            terraform workspace select "${TF_STATE_ID}" || terraform workspace new "${TF_STATE_ID}"
                            terraform plan -out=tfplan
                        """
                    }
                }
            }
        }

        stage('Infrastructure: Approval') {
            steps {
                script {
                    // pipeline freezes until human approval
                    input message: "Review the Terraform Plan. Do you want to apply these changes?", ok: "Deploy Infrastructure"
                }
            }
        }

        stage('Infrastructure: Apply') {
            steps {
                // FIXED: Must be executed inside the workspace directory targeting the tfplan file
                dir("${WORKSPACE_DIR}") {
                    sh "terraform apply tfplan"
                }
            }
        }

        stage('Infrastructure: Discovery') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    script {
                        def vmListRaw = sh(script: "terraform output -json vm_names", returnStdout: true).trim()
                        def vms = new groovy.json.JsonSlurper().parseText(vmListRaw)

                        sh "echo '[nodes]' > inventory.ini"

                        vms.each { vmName ->
                            sh "multipass.exe start ${vmName}"
                            def ip = sh(script: "multipass.exe info ${vmName} --format csv | grep ${vmName} | cut -d, -f3", returnStdout: true).trim()
                            if (ip) {
                                sh "echo '${ip} ansible_user=ubuntu'  >> inventory.ini"
                            }
                        }
                    }
                }
            }
        }

        stage('Docker install') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    sh """
                        ansible-playbook tasks/install_docker.yml
                    """
                }
            }
        }

        stage('Nginx config') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    sh """
                        ansible-playbook tasks/setup_nginx_web.yml
                    """
                }
            }
        }
        
        stage('User config') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    sh """
                        ansible-playbook tasks/setup_admin_user.yml \
                          -e "admin_user=${params.ADMIN_USER}" \
                          -e "admin_password=${params.ADMIN_PASS}"
                    """
                }
            }
        }
    }
}
