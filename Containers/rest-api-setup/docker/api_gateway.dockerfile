FROM debian:12

# Atualiza o sistema e instala dependências completas do Python
RUN apt update && apt upgrade -y && \
    apt install -y python3-full python3.11-venv \
        default-libmysqlclient-dev \
        build-essential \
        python3-dev \
        curl

# Cria diretório da aplicação
WORKDIR /tmp/rest_api

# Copia a API para dentro do contêiner
COPY ./rest_api /tmp/rest_api

# Cria o ambiente virtual e instala dependências
RUN python3 -m venv venv && \
    ./venv/bin/python -m ensurepip --upgrade && \
    ./venv/bin/python -m pip install --upgrade pip setuptools wheel && \
    ./venv/bin/python -m pip install pymysql flask authlib requests

# Expõe a porta usada pela aplicação
EXPOSE 5000

# Comando de inicialização
CMD ["./venv/bin/python", "main.py"]
