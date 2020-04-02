pipeline {
    agent any
    environment {
        // Do not use http://localhost:2375
        // https://github.com/docker/compose/issues/6293#issuecomment-432326127
        DOCKER_HOST = 'localhost:2375'
    }
    stages {
        stage('Build Tests') {
            steps {
               sh 'docker-compose -f docker-compose-test.yml build runner'
            }
        }
        stage('Test') { 
            steps {
                // Set folder permissions
                // TODO: add git tool to store file metadata
                sh 'chmod 777 test/reports'
                sh 'docker-compose -f docker-compose-test.yml run --rm runner'
                junit 'test/reports/*.xml'
            }
        }
        stage('Build') {
            steps {
                withCredentials([string(credentialsId: 'rails_master_key', variable: 'RAILS_MASTER_KEY')]) {
                   sh 'docker-compose -f docker-compose-production.yml build rails'
                   sh 'docker-compose -f docker-compose-production.yml build nginx'
                }
            }
        }
        stage('Publish') {
            steps {
                withDockerRegistry([ credentialsId: "aagdockerid_credentials", url: "" ]) {
                    sh 'docker push p91challenge/rails-prod'
                    sh 'docker push p91challenge/nginx-prod'
                }
            }
        }
    }
    post {
        always {
            sh "docker-compose down -v"
        }
    }
}
