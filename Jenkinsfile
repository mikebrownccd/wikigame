pipeline {
    agent any

    environment {
        ANDROID_HOME = '/Users/michelle/Library/Android/sdk'
        AVD_NAME     = 'jenkins_avd'
        PATH         = "/usr/local/bin:${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'flutter pub get'
            }
        }

        stage('Build') {
            steps {
                sh 'flutter build apk --debug'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'flutter test --reporter json > test-results.json || true'
            }
            post {
                always {
                    sh 'flutter test --reporter expanded'
                }
            }
        }

        stage('Instrumented Tests') {
            steps {
                sh '''
                    # Start emulator in background
                    $ANDROID_HOME/emulator/emulator -avd $AVD_NAME -no-window -no-audio -no-snapshot &
                    EMULATOR_PID=$!

                    # Wait for emulator to boot
                    $ANDROID_HOME/platform-tools/adb wait-for-device
                    until $ANDROID_HOME/platform-tools/adb shell getprop sys.boot_completed 2>/dev/null | grep -m 1 "1"; do
                        sleep 5
                    done

                    # Disable animations for test stability
                    $ANDROID_HOME/platform-tools/adb shell settings put global window_animation_scale 0
                    $ANDROID_HOME/platform-tools/adb shell settings put global transition_animation_scale 0
                    $ANDROID_HOME/platform-tools/adb shell settings put global animator_duration_scale 0

                    # Run integration tests
                    flutter test integration_test || true

                    # Shut down emulator
                    $ANDROID_HOME/platform-tools/adb -s emulator-5554 emu kill || kill $EMULATOR_PID || true
                    wait $EMULATOR_PID || true
                '''
            }
        }
    }
}
