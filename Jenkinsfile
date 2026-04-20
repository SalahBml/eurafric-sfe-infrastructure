def provisionedVMs = [:]

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
	stage('Security: Secret Scan') {
        
/*    steps {
                dir("${WORKSPACE_DIR}") {
                    sh "docker run --rm --user root -v \$(pwd):/path zricethezav/gitleaks:latest detect --source=/path -v"
                }
            }
        }*/

        stage('Security: Dependency Scan (SCA)') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    sh "trivy fs --scanners vuln --severity HIGH,CRITICAL --exit-code 1 ."
                }
            }
        }

        stage('Security: SAST') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    sh "semgrep scan --config auto --error ."
                }
            }
        }

        stage('Security: IaC Scan') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    sh "tfsec ."
                }
            }
        }

        stage('Infrastructure: Plan') {
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
            when {
                branch 'main'
            }
            steps {
                script {
                    input message: "Review the Terraform Plan. Do you want to apply these changes?", ok: "Deploy Infrastructure"
                }
            }
        }

        stage('Infrastructure: Apply') {
            when {
                branch 'main'
            }
            steps {
                dir("${WORKSPACE_DIR}") {
                    sh "terraform apply tfplan"
                }
            }
        }

        stage('Infrastructure: Discovery') {
            when {
                branch 'main'
            }
            steps {
                dir("${WORKSPACE_DIR}") {
                    script {
                        def vmListRaw = sh(script: "terraform output -json vm_names", returnStdout: true).trim()
                        def vms = new groovy.json.JsonSlurperClassic().parseText(vmListRaw)

                        sh "echo '[nodes]' > inventory.ini"

                        vms.each { vmName ->
                            sh "multipass start ${vmName}"
                            def ip = sh(script: "multipass info ${vmName} --format csv | grep ${vmName} | cut -d, -f3", returnStdout: true).trim()
                            if (ip) {
                                sh "echo '${ip} ansible_user=ubuntu'  >> inventory.ini"
                                provisionedVMs[vmName] = ip
                            }
                        }
                    }
                }
            }
        }

        stage('User config') {
            when {
                branch 'main'
            }
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
    
    post {
        always {
            script {
                echo "==================================================="
                echo " MULTIPASS VM IP ADDRESSES"
                echo "==================================================="

                if (provisionedVMs.isEmpty()) {
                    echo "No IPs were captured. (Normal behavior for PR branches)"
                } else {
                    provisionedVMs.each { name, ipAddr ->
                        echo " ${name} -> ${ipAddr}"
                    }
                }

                echo "==================================================="
            }
        }
    }
}
