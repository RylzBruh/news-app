pipeline {
    agent any
    environment {
        API_KEY = credentials('NEWS_API_KEY')
        DOCKER_IMAGE = 'rsrprojects/flask-news-app'
        IMAGE_TAG = 'latest'
        DOCKERHUB_CREDS = credentials('DOCKER_CREDENTIALS')
        TF_API_TOKEN = credentials('TERRAFORM_CLOUD_API')
        WORKSPACE_ID = 'ws-sbPFYMrFfwvtFurY'
    }
    stages ('Checkout') {
        steps {
            checkout scm
        }
    }
    stages ('Prepare Environment') {
        steps {
            sh '''
                echo "NEWS_API_KEY=${API_KEY}" > .env
                echo "Debug: Content of .env file"
                cat .env
            '''
        }
    }
    stages ('Setup Requirements') {
        steps {
            sh '''
                which python3 || (apt-get update && apt-get install -y python3 python3-venv)
                python3 -m venv venv
                ./venv/bin/pip install -r requirements.txt
            '''
        }
    }
    stages ('Run Tests') {
        steps {
            sh './venv/bin/python -m pytest tests/'
        }
    }
}