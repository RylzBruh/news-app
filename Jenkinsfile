pipeline {
    agent any

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
        stage ('pip-audit check') {
            steps {
                sh './venv/bin/pip-audit --strict --format=cyclonedx-json --output=pip_audit_report.sbom.json'
            }
        }
    }
}
