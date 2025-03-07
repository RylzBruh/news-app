pipeline {
    agent any

    environment {
        API_KEY = credentials('NEWS_API_KEY')
        NVD_API_KEY = credentials('NVD_API_KEY')
        SONAR_SCANNER_HOME = tool 'sonar-scanner7-0-1';
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
                    ls -la htmlcov
                '''
            }
        }

        stage ('SAST - Static application security testing - SonarQube') {
            steps {
                sh 'echo $SONAR_SCANNER_HOME'
                sh '''
                    $SONAR_SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=Solar-System-Project \
                        -Dsonar.sources=app/ \
                        -Dsonar.host.url=http://172.19.154.120:9000 \
                        -Dsonar.python.coverage.reportPaths=coverage.xml \
                        -Dsonar.token=sqp_5dbed4dfdefdcf62b992eaeded2c6fd7dee7be8f 
                '''
            }
        }

      
    }

    post {
        always {

            archiveArtifacts allowEmptyArchive: true, artifacts: 'htmlcov/**, *_report.json', fingerprint: true, followSymlinks: false, onlyIfSuccessful: true
            junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'tests/results.xml'

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'htmlcov', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        }
        // cleanup {
        //     deleteDir()
        // }
    }
}
