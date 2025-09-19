pipeline {
  agent {
    kubernetes {
      label "gradle-kaniko-${UUID.randomUUID().toString()}"
      defaultContainer 'gradle'
      yaml """
apiVersion: v1
kind: Pod
spec:
  restartPolicy: Never
  containers:
    - name: gradle
      image: gradle:8.9-jdk17
      command: ['cat']
      tty: true
      volumeMounts:
        - name: gradle-cache
          mountPath: /home/gradle/.gradle

    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: ['/busybox/sh','-c','sleep infinity']
      tty: true
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker
        - name: workspace
          mountPath: /workspace

  volumes:
    - name: gradle-cache
      emptyDir: {}

    - name: workspace
      emptyDir: {}

    - name: docker-config
      secret:
        secretName: dockerhub-cred
        items:
          - key: .dockerconfigjson
            path: config.json
"""
    }
  }

  environment {
    IMAGE_NAME = 'tipsyboy/test'
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
    GITHUB_REPOSITORY = 'https://github.com/tipsyboy/devops-practice'
  }
  stages {
    stage('Checkout') {
      steps {
        container('gradle') {
          checkout([$class: 'GitSCM',
            branches: [[name: '*/main']],
            userRemoteConfigs: [[url: "${GITHUB_REPOSITORY}"]]
          ])
        }
      }
    }

    stage('Gradle Build') {
      steps {
        container('gradle') {
          sh '''
            chmod +x ./gradlew || true
            ./gradlew --no-daemon clean bootJar
          '''
        }
      }
    }

    stage('Kaniko Build & Push') {
      steps {
        container('kaniko') {
          sh """
            /kaniko/executor \
              --context=${WORKSPACE} \
              --dockerfile=${WORKSPACE}/Dockerfile \
              --destination=${IMAGE_NAME}:${IMAGE_TAG} \
              --destination=${IMAGE_NAME}:latest \
              --single-snapshot \
              --use-new-run \
              --cache=true \
              --snapshotMode=redo
          """
        }
      }
    }

    stage('Result') {
      steps {
        echo "Pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
      }
    }
  }
}