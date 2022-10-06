def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger',
]

def cancelPreviousBuilds() {
    def jobName = env.JOB_NAME
    def buildNumber = env.BUILD_NUMBER.toInteger()
    def currentJob = Jenkins.instance.getItemByFullName(jobName)

    for (def build : currentJob.builds) {
        def exec = build.getExecutor()
        if (build.isBuilding() && buildNumber.toInteger() != buildNumber && exec != null) {
            exec.interrupt(
                    Result.ABORTED,
                    new CauseOfInterruption.UserInterruption("Job aborted by #${currentBuild.number}")
                )
            println("Job aborted previously running build #${build.number}")
        }
    }
}

def buildNumber = env.BUILD_NUMBER as int
if (buildNumber > 1) milestone(buildNumber - 1)
milestone(buildNumber)

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
    post {
        always {
            mattermostSend color: COLOR_MAP[currentBuild.currentResult],
                        message: "*${currentBuild.currentResult}:* Job `${env.JOB_NAME}` build ${env.BUILD_NUMBER} \n <${env.BUILD_URL}|More info>"
        }
        
    }
       
}
