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
            steps {
                sh '''
                    ./venv/bin/pip-audit --format=columns --output=pip_audit_report.txt
                    ./venv/bin/pip-audit --format=cyclonedx-json --output=pip_audit_report.sbom.json
                    ./venv/bin/pip-audit --strict --format=json --output=pip_audit_report.json
                '''
            }
        }
        stage ('Unit Testing') {
            steps {
                sh '''
                    ls -la
                    pwd
                    export PYTHONPATH=$PWD
                    ./venv/bin/pytest --help | grep "pytest.ini"
                    ./venv/bin/pytest --cov=app --cov-report=html --cov-report=xml --cov-report=term-missing --junitxml=tests/results.xml tests/
                '''
                junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'tests/results.xml'
            }
        }
    }

    post {
        always {
            archiveArtifacts allowEmptyArchive: true, artifacts: 'htmlcov/**, *_report.json', fingerprint: true, followSymlinks: false, onlyIfSuccessful: true
        }
        cleanup {
            deleteDir()
        }
    }
}
