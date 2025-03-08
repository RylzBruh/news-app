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
                timeout(time: 60, unit: 'SECONDS') {
                    withSonarQubeEnv('sonarqube-server') {
                        sh 'echo $SONAR_SCANNER_HOME'
                        sh '''
                            $SONAR_SCANNER_HOME/bin/sonar-scanner \
                                -Dsonar.projectKey=Solar-System-Project \
                                -Dsonar.sources=app/ \
                                -Dsonar.python.coverage.reportPaths=coverage.xml 
                        '''
                    }
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage ('Build Docker Image') {
            steps {
                sh 'printenv'
                sh 'sudo docker build -t rsrprojects/news-application:$GIT_COMMIT .'
            }

        }

        stage ('Trivy Vulnerability Scanner') {
            steps {
                sh 'ls -la @/usr/local/share/trivy/templates/'
                sh '''
                    trivy image rsrprojects/news-application:$GIT_COMMIT \
                        -- severity LOW, MEDIUM \
                        -- exit-code 0 \
                        -- quiet \
                        -- format json -o trivy-image-MEDIUM-results.json

                    trivy image rsrprojects/news-application:$GIT_COMMIT \
                        -- severity CRITICAL \
                        -- exit-code 1 \
                        -- quiet \
                        -- format json -o trivy-image-CRITICAL-results.json
                '''
            }
            post {
                always {
                    sh '''
                        trivy convert \
                            -- format template -- template "@/usr/local/share/trivy/templates/html.tpl" \
                            -- output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json

                        trivy convert \
                            -- format template -- template "@/usr/local/share/trivy/templates/html.tpl" \
                            -- output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json

                        trivy convert \
                            -- format template -- template "@/usr/local/share/trivy/templates/junit.tpl" \
                            -- output trivy-image-MEDIUM-results.xml trivy-image-MEDIUM-results.json

                        trivy convert \
                            -- format template -- template "@/usr/local/share/trivy/templates/junit.tpl" \
                            -- output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json
                    '''
            }
        }
      
    }

    post {
        always {

            archiveArtifacts allowEmptyArchive: true, artifacts: 'htmlcov/**, *_report.json', fingerprint: true, followSymlinks: false, onlyIfSuccessful: true

            junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'tests/results.xml'
            junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'trivy-image-MEDIUM-results.xml'
            junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'trivy-image-CRITICAL-results.xml'

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'htmlcov', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-results.html', reportName: 'Trivy Image Critical Vul Report' reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-MEDIUM-results.html', reportName: 'Trivy Image Medium Vul Report', reportTitles: '', useWrapperFileDirectly: true])
        }
        // cleanup {
        //     deleteDir()
        // }
    }
}
