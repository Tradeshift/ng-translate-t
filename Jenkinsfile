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
        stage('Setup nodejs') {
            steps {
                useNodeJS()
            }
        }
        stage('npm install') {
            steps {
                sh 'which node; node -v'
                sh 'which npm; npm -v'
                sh 'npm install'
            }
        }

        stage('Build and test') {
            steps {
                sh "npm run validate"
            }
            post {
                always {
                    sh '''#!/bin/bash
                    # Hack for absolute paths in lcov files:
                    if [ -f  coverage/lcov.info ]; then
                        sed -i "s|SF:${APP_DIR}|SF:${BUILD_DIR}/|g" coverage/lcov.info
                    fi
                    '''
                    checkstyle pattern:'build/checkstyle/*.xml', unstableTotalAll: '0', usePreviousBuildAsReference: true
                    junit testResults: 'build/junit/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('Semantic release') {
            environment {
                NPM_TOKEN = credentials 'jenkins-public-npm-rw-token'
            }
            steps {
                semanticVersion()
            }
        }

        stage('Sonarqube') {
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
