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
                apt-get update && apt-get install -y python3 python3-venv
                which python3
                python3 -m venv venv
                ./venv/bin/pip install -r requirements.txt
                '''
            }
        }
    }
}