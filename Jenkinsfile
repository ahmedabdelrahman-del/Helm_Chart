pipeline{
    agent any 
    stages{
        stage('build'){
            steps{
                echo 'Building..'
                //compile code here a java code
                sh 'javac ToUpper.java'
            }
            stage('test'){
                steps{
                    echo 'Testing..'
                    //run test cases here
                    sh 'java ToUpper'
                }
            }
            
        }
}