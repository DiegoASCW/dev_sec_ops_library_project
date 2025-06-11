pipeline {
    agent any

    environment {
        PROJECT_DIR = "Containers/rest-api-setup/scripts"
        GEN_FILE = "Env-gen.sh"
    }

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

        stage('Preparar e Executar Ambiente') {
            steps {
                dir("${PROJECT_DIR}") {
                    sh '''
                        set -euxo pipefail
                        chmod +x ${GEN_FILE}
                        echo "Executando fase de Delivery via ${GEN_FILE}..."
                        ./Env-gen.sh
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline finalizado com sucesso! CI/CD concluído."
        }
        failure {
            echo "Pipeline falhou. Verifique os logs e a execução do script ${GEN_FILE}."
        }
    }
}
