pipeline {
    agent any

    stages {
        stage('Limpar Workspace') {
            steps {
                echo "Limpando arquivos antigos no workspace..."
                deleteDir()
            }
        }

        stage('Clonar Repositório') {
            steps {
                echo "Clonando o repositório..."
                checkout scm
            }
        }
    } 
}
