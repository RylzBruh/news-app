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
        stage ('VM Python Version') {
            steps {
                sh 'python3 --version'
            }
        }
    }
}