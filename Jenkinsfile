pipeline {
  agent any
  environment {
    GOPROXY = 'https://goproxy.cn,direct'
  }
  tools {
    go 'go'
  }
  stages {
    stage('Clone rabbitmq cluster') {
      steps {
        git(url: scm.userRemoteConfigs[0].url, branch: '$BRANCH_NAME', changelog: true, credentialsId: 'KK-github-key', poll: true)
      }
    }

    stage('Check deps tools') {
      steps {
        script {
          if (!fileExists("/usr/bin/helm")) {
            sh 'mkdir -p $HOME/.helm'
            if (!fileExists("$HOME/.helm/.helm-src")) {
              sh 'git clone https://github.com/helm/helm.git $HOME/.helm/.helm-src'
            }
            sh 'cd $HOME/.helm/.helm-src; git checkout release-3.7; make; cp bin/helm /usr/bin/helm'
            sh 'helm version'
          }
        }
      }
    }

    stage('Switch to current cluster') {
      steps {
        sh 'cd /etc/kubeasz; ./ezctl checkout $TARGET_ENV'
      }
    }

    stage('Build rabbitmq image') {
      when {
        expression { BUILD_TARGET == 'true' }
      }
      steps {
        sh 'mkdir -p .docker-tmp; cp /usr/bin/consul .docker-tmp'
        sh(returnStdout: true, script: '''
          images=`docker images | grep entropypool | grep rabbitmq | awk '{ print $3 }'`
          for image in $images; do
            docker rmi $image
          done
        '''.stripIndent())
        sh 'docker build -t uhub.service.ucloud.cn/entropypool/rabbitmq:3.9.7 .'
      }
    }

    stage('Release rabbitmq image') {
      when {
        expression { RELEASE_TARGET == 'true' }
      }
      steps {
        sh(returnStdout: true, script: '''
          set +e
          while true; do
            docker push uhub.service.ucloud.cn/entropypool/rabbitmq:3.9.7
            if [ $? -eq 0 ]; then
              break
            fi
          done
          set -e
        '''.stripIndent())
      }
    }

    stage('Deploy redis cluster') {
      when {
        expression { DEPLOY_TARGET == 'true' }
      }
      steps {
        sh (returnStdout: true, script: '''
          export RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD
          envsubst < ./secret.yaml | kubectl apply -f -
        '''.stripIndent())
        sh 'RABBITMQ_ERLANG_COOKIE=$(kubectl get secret --namespace "kube-system" rabbitmq -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 --decode); helm upgrade rabbitmq -f values.service.yaml --namespace kube-system --set auth.erlangCookie=$RABBITMQ_ERLANG_COOKIE ./rabbitmq || helm install rabbitmq -f values.service.yaml --namespace kube-system ./rabbitmq'
        sh 'sed -i "s/rabbitmq.development.npool.top/rabbitmq.$TARGET_ENV.npool.top/g" 01-traefik-vpn-ingress.yaml'
        sh 'kubectl apply -f 01-traefik-vpn-ingress.yaml'
      }
    }

    stage('Config apollo') {
      when {
        expression { CONFIG_TARGET == 'true' }
      }
      steps {
        sh 'rm .apollo-base-config -rf'
        sh 'git clone https://github.com/NpoolPlatform/apollo-base-config.git .apollo-base-config'
        sh 'cd .apollo-base-config; ./apollo-base-config.sh $APP_ID $TARGET_ENV rabbitmq-npool-top'
        sh 'cd .apollo-base-config; ./apollo-item-config.sh $APP_ID $TARGET_ENV rabbitmq-npool-top username user'
        sh 'cd .apollo-base-config; ./apollo-item-config.sh $APP_ID $TARGET_ENV rabbitmq-npool-top password $RABBITMQ_PASSWORD'
      }
    }
  }

  post('Report') {
    fixed {
      script {
        sh(script: 'bash $JENKINS_HOME/wechat-templates/send_wxmsg.sh fixed')
     }
      script {
        // env.ForEmailPlugin = env.WORKSPACE
        emailext attachmentsPattern: 'TestResults\\*.trx',
        body: '${FILE,path="$JENKINS_HOME/email-templates/success_email_tmp.html"}',
        mimeType: 'text/html',
        subject: currentBuild.currentResult + " : " + env.JOB_NAME,
        to: '$DEFAULT_RECIPIENTS'
      }
     }
    success {
      script {
        sh(script: 'bash $JENKINS_HOME/wechat-templates/send_wxmsg.sh successful')
     }
      script {
        // env.ForEmailPlugin = env.WORKSPACE
        emailext attachmentsPattern: 'TestResults\\*.trx',
        body: '${FILE,path="$JENKINS_HOME/email-templates/success_email_tmp.html"}',
        mimeType: 'text/html',
        subject: currentBuild.currentResult + " : " + env.JOB_NAME,
        to: '$DEFAULT_RECIPIENTS'
      }
     }
    failure {
      script {
        sh(script: 'bash $JENKINS_HOME/wechat-templates/send_wxmsg.sh failure')
     }
      script {
        // env.ForEmailPlugin = env.WORKSPACE
        emailext attachmentsPattern: 'TestResults\\*.trx',
        body: '${FILE,path="$JENKINS_HOME/email-templates/fail_email_tmp.html"}',
        mimeType: 'text/html',
        subject: currentBuild.currentResult + " : " + env.JOB_NAME,
        to: '$DEFAULT_RECIPIENTS'
      }
     }
    aborted {
      script {
        sh(script: 'bash $JENKINS_HOME/wechat-templates/send_wxmsg.sh aborted')
     }
      script {
        // env.ForEmailPlugin = env.WORKSPACE
        emailext attachmentsPattern: 'TestResults\\*.trx',
        body: '${FILE,path="$JENKINS_HOME/email-templates/fail_email_tmp.html"}',
        mimeType: 'text/html',
        subject: currentBuild.currentResult + " : " + env.JOB_NAME,
        to: '$DEFAULT_RECIPIENTS'
      }
     }
  }
}
