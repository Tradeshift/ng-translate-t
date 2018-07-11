// This Jenkinsfile uses the declarative syntax. If you need help, check
// Overview and structure: https://jenkins.io/doc/book/pipeline/syntax/
// For plugins and steps:  https://jenkins.io/doc/pipeline/steps/
// For Github integration: https://github.com/jenkinsci/pipeline-github-plugin
// For credentials:        https://jenkins.io/doc/book/pipeline/jenkinsfile/#handling-credentials
// For credential IDs:     https://ci.ts.sv/credentials/store/system/domain/_/
// Tools (JDK, Maven):     https://ci.ts.sv/configureTools/
// Environment variables:  env.VARIABLE_NAME

pipeline {
    agent any // Put node restrictions here, if any
    triggers {
        issueCommentTrigger('^retest$')
    }
    stages {
        stage('Initialise PR') {
            when { changeRequest() }
            steps {
                echo 'HAXXORZZ'
                githubNotify(status: 'PENDING', context: 'sonarqube', description: 'Not analysed')
                githubNotify(status: 'PENDING', context: 'semantic-release', description: 'Not analysed')
            }
        }
        stage('Clone') {
            steps {
                checkout scm
            }
        }

        stage('Build and test') {
            when {
                anyOf {
                    branch 'master'
                    changeRequest()
                }
            }
            environment {
                GITHUB_CREDS = credentials 'frontend-key'
                NPM_UPLOAD_TOKEN = credentials 'jenkins-public-npm-rw-token'
                NPM_TOKEN = credentials 'jenkins-npm-ro-npm-token'
            }
            steps {
                sh '''#!/bin/bash
                ./jenkins.sh | tee build.log; exit ${PIPESTATUS[0]}
                '''
                script {
                  if (env.CHANGE_ID) {
                    def output = sh(script: "sed -n '/Analysis of/,/echo installing semantic-release/p' build.log \
                      | sed -e 's/^\\[release\\]\\s*//' -e 's/\\[Semantic release\\]:\\s*//' \
                      | grep -v 'Call plugin' \
                      | head -n -1", returnStdout: true).trim()

                    if (output) {
                      def prefix = '*Semantic release: \
                      ([Commit conventions](https://github.com/conventional-changelog-archived-repos/conventional-changelog-angular/blob/master/convention.md))*\n\n'
                      // Clean up existing release comments
                      for (comment in pullRequest.comments) {
                        if (comment.body.startsWith(prefix)) {
                          comment.delete()
                        }
                      }
                      pullRequest.comment(prefix + output)

                      // Set commit status
                      def releaseType = output.split('\n').findAll{ l -> l.contains('Analysis') }.join('').replaceFirst(/(.*): /, '')
                      githubNotify(status: 'SUCCESS', context: 'semantic-release', description: releaseType)
                    }
                  }
                }
            }
            post {
                always {
                    checkstyle pattern:'build/checkstyle/*.xml', unstableTotalAll: '0', usePreviousBuildAsReference: true
                    junit testResults: 'build/junit/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('Sonarqube') {
            when {
                anyOf {
                    branch 'master'
                    changeRequest()
                }
            }
            environment {
                SONAR_HOME = tool 'Scanner'
                GITHUB_TOKEN = credentials 'sonarqube-integration'
            }
            steps {
                sonarqube(extraOptions: '\
                    -Dsonar.exclusions="build/**/*, coverage/**/*, dist/**/*" \
                    -Dsonar.coverage.exclusions="**/*.spec.js,**/__mocks__/**/*.js,**/__tests__/**/*.js" \
                    -Dsonar.javascript.lcov.reportPaths="coverage/lcov.info" \
                ')
            }
        }
    }
}
