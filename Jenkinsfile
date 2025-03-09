pipeline {
    agent any

    environment {
        API_KEY = credentials('NEWS_API_KEY')
        NVD_API_KEY = credentials('NVD_API_KEY')
        SONAR_SCANNER_HOME = tool 'sonar-scanner7-0-1';
        GITEA_TOKEN = credentials('gitea-token')
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
                ./venv/bin/pip install -r requirements.txt
                '''
            }
        }
        
        stage ('Code Testing') {
            parallel {
                stage ('Dependency Scanning') {
                    steps {
                        sh '''
                            ./venv/bin/pip-audit --format=columns --output=pip_audit_report.txt
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
                        timeout(time: 5, unit: 'MINUTES') {
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
            }
        }

        stage ('Build Docker Image') {
            steps {
                sh 'docker build -t rsrprojects/news-application:$GIT_COMMIT .'
            }
        }

        stage ('Trivy Vulnerability Scanner') {
            steps {
                sh 'ls -la /usr/local/share/trivy/templates/'
                sh '''
                    trivy image rsrprojects/news-application:$GIT_COMMIT \
                        --severity LOW,MEDIUM,HIGH \
                        --exit-code 0 \
                        --quiet \
                        --format json -o trivy-image-MEDIUM-results.json

                    trivy image rsrprojects/news-application:$GIT_COMMIT \
                        --severity CRITICAL \
                        --exit-code 1 \
                        --quiet \
                        --format json -o trivy-image-CRITICAL-results.json
                '''
            }
            post {
                always {
                    sh 'ls -la'
                    sh '''
                        trivy convert \
                            --format template \
                            --template "@/usr/local/share/trivy/templates/html.tpl" \
                            --output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json

                        trivy convert \
                            --format template \
                            --template "@/usr/local/share/trivy/templates/html.tpl" \
                            --output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json

                        trivy convert \
                            --format template \
                            --template "@/usr/local/share/trivy/templates/junit.tpl" \
                            --output trivy-image-MEDIUM-results.xml trivy-image-MEDIUM-results.json

                        trivy convert \
                            --format template \
                            --template "@/usr/local/share/trivy/templates/junit.tpl" \
                            --output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json
                    '''
                }
            }
      
        }

        stage ('Push Docker Image') {
            steps {
                withDockerRegistry(credentialsId: 'docker-hub-credentials', url: "") {
                    sh 'docker push rsrprojects/news-application:$GIT_COMMIT'
                }     
            }
        }

        stage ('Deploy - AWS EC2') {
            when {
                branch 'feature/*'
            }
            steps {
                script {
                    withAWS(credentials: 'aws-creds', region: 'eu-west-1') {
                        EC2_IP = sh(
                            script: '''
                                aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "dev-deploy") | .PublicIpAddress'
                            ''',
                            returnStdout: true
                        ).trim()
                    }
                    echo "EC2 IP: ${EC2_IP}"

                    sshagent(['aws-dev-deploy-ec2-instance']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '
                                    if sudo docker ps | grep news-application; then
                                        echo "Container found. Stopping..."
                                            sudo docker stop "news-application" && sudo docker rm "news-application"
                                        echo "Container stopped and removed."
                                    fi
                                        sudo docker run --restart unless-stopped --name news-application \
                                        -p 5000:5000 -d rsrprojects/news-application:${GIT_COMMIT}
                                    '
                        """
                    }
                }   
            }
        }

        stage ('Integration Testing - AWS EC2') {
            when {
                branch 'feature/*'
            }
            steps {
                sh 'printenv | grep -i branch'
                withAWS(credentials: 'aws-creds', region: 'eu-west-1') {
                    sh '''
                        bash integration-testing-ec2.sh
                    '''
                }
            }
        }

        stage ('K8S update Image Tag') {
            when {
                branch 'PR*'
            }
            steps {
                sh 'git clone -b main http://192.168.1.246:3000/news-application/news-application-argocd.git'
                dir("news-application-argocd/kubernetes") {
                    script {
                        sh """
                            if git branch -r | grep feature-$BUILD_ID; then
                                echo "Branch exists. Pulling changes..."
                                    git checkout feature-$BUILD_ID
                                    git pull origin feature-$BUILD_ID
                                echo "Branch updated."
                            else
                                echo "Branch does not exist. Creating new branch..."
                                    git checkout -b feature-$BUILD_ID
                                echo "Branch created."
                            fi
                                echo "Updating Docker Image Tag in deployment manifest..."
                                    sed -i "s#rsrprojects.*#rsrprojects/news-application:$GIT_COMMIT#g" deployment.yml
                                    cat deployment.yml
                                echo "Committing changes..."
                                    git config --global user.email "jenkins@rsr.com"
                                    git config --global user.name "Jenkins"
                                    git remote set-url origin http://$GITEA_TOKEN@192.168.1.246:3000/news-application/news-application-argocd
                                    git add .
                                    git commit -am "Update Docker Image Tag to $GIT_COMMIT"
                                echo "Pushing changes..."
                                    git push origin feature-$BUILD_ID
                                echo "Changes pushed."
                        """
                    }
                }
            }
        }

        stage ('K8S - Raise PR') {
            when {
                branch 'PR*'
            }
            steps {
                sh """
                    curl -X 'POST' \
                        'http://192.168.1.246:3000/api/v1/repos/news-application/news-application-argocd/pulls' \
                        -H 'accept: application/json' \
                        -H 'Authorization: token $GITEA_TOKEN' \
                        -H 'Content-Type: application/json' \
                        -d '{
                            "assignee": "rafael",
                            "assignees": [
                                "rafael"
                            ],
                            "base": "main",
                            "body": "Update docker image in deployment manifest",
                            "head": "feature-$BUILD_ID",
                            "title": "Update Docker Image"
                        }'
                """
            }
        }

        stage ('Application Running?') {
            when {
                branch 'PR*'
            }
            steps {
                timeout(time: 1, unit: 'DAYS') {
                    input message: 'Is the application running?', ok: 'Yes! PR is Merged and ArgoCD Application Synced'
                }
            }

        }

        stage ('DAST - OWASP ZAP') {
            when {
                branch 'PR*'
            }
            steps {
                script {
                    sh '''
                        if docker ps | grep zap-scanner; then
                            echo "Container found. Stopping..."
                                docker stop zap-scanner && docker rm zap-scanner
                            echo "Container stopped and removed."
                        fi
                            chmod 777 $(pwd)
                            docker run --rm --name zap-scanner --network=host -v $(pwd):/zap/wrk/:rw -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                            -t http://192.168.49.2:30000/ \
                            -r zap-report.html \
                            -w zap-report.md \
                            -J zap-report.json \
                            -x zap-report.xml 
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                if (fileExists('news-application-argocd')) {
                    sh 'rm -rf news-application-argocd'
                }
            }
            archiveArtifacts allowEmptyArchive: true, artifacts: 'htmlcov/**, *_report.json, *-results.*', fingerprint: true, followSymlinks: false, onlyIfSuccessful: true

            junit allowEmptyResults: true, stdioRetention: '', testResults: 'tests/results.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-MEDIUM-results.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-CRITICAL-results.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'zap-report.xml'

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'htmlcov', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-results.html', reportName: 'Trivy Image Critical Vul Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-MEDIUM-results.html', reportName: 'Trivy Image Medium Vul Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'zap-report.html', reportName: 'DAST - OWASP ZAP Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    //     cleanup {
    //         deleteDir()
    //     }
    }
}
