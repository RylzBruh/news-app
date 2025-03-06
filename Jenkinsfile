pipeline {
    agent any

    environment {
        API_KEY = credentials('NEWS_API_KEY')
        NVD_API_KEY = credentials('NVD_API_KEY')
    }

    stages {
        stage ('Prepare Environment') {
            steps {
                sh '''
                    echo "NEWS_API_KEY=${API_KEY}" > .env
                    echo "Debug: Content of .env file"
                    cat .env
                '''
            }
        }
        stage ('Install Dependencies') {
            steps {
                sh '''
                whoami
                sudo apt-get update -qq && sudo apt-get install -y python3 python3-venv -qq
                which python3
                python3 -m venv venv
                ./venv/bin/pip install -r requirements.txt --no-cache-dir
                '''
            }
        }
        stage ('Dependency Scanning') {
            parallel {
                stage ('pip-audit check') {
                    steps {
                        sh '''
                            ./venv/bin/pip-audit --format=columns --output=pip_audit_report.txt
                            ./venv/bin/pip-audit --format=cyclonedx-json --output=pip_audit_report.sbom.json
                            ./venv/bin/pip-audit --strict --format=json --output=pip_audit_report.json
                        '''
                    }
                }
                stage ('OWASP Dependency-Check') {
                    steps {
                        sh '''
                            ls -la
                            pwd
                            echo $NVD_API_KEY
                        '''
                        dependencyCheck additionalArguments: '''
                        --nvdApiKey \'$NVD_API_KEY\'
                        --scan \'/var/lib/jenkins/workspace/pplication_feature_enabling-cicd\requirements.txt'
                        --scan \'./\'
                        --out \'./\'
                        --format \'ALL\'
                        --prettyPrint''', odcInstallation: 'OWASP-DepCheck-12-1-0'

                        dependencyCheckPublisher pattern: 'dependency-check-report.xml', stopBuild: true, unstableTotalCritical: 1
                    }
                }
            }
        }
    }
}
