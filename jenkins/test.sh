pipeline {
    agent any

    stages {
        stage('Git Clone') {
            steps{
                echo "Cloneing Repository"
                git branch: 'main', url: 'https://github.com/tipsyboy/devops-practice'
            }
        }
        stage('Gradle Build') {
            steps{
                echo "Add Permission"
                sh 'chmod +x gradlew'

                echo "Build"
                sh './gradlew bootJar'
            }
        }
    }
}