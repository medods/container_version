pipeline {
    agent any 
    environment {
      registryPrivate = "gainanov/container_version"
      registryCredential = 'dockerhub'
      registryCredentialPrivate = 'dockerhub-private'
      kubectlCredential = 'yandex-kubectl'
      yandexCredential = 'yandex-server'
      dockerImage =' '
    }
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                script {
                   dockerImagePrivate = docker.build registryPrivate + ":$BUILD_NUMBER"
                }
            }
        }
        stage('Push to private') {
            steps {
                echo 'Pushing..'
                script {
                    docker.withRegistry( '', registryCredentialPrivate ) {
                        dockerImagePrivate.push()
                    }
                }
            }
        }
        stage('Remove') {
            steps {
                echo 'Removing....'
                sh "docker rmi $registryPrivate:$BUILD_NUMBER"
                sh "rm -rf ./build"
            }
        }

        }
    }
}
