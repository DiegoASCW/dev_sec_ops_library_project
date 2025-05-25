FROM debian:12

# atualiza o sistema e instala dependências completas do Python
RUN apt update && apt upgrade -y && \
    apt install -y python3-full python3.11-venv \
        default-libmysqlclient-dev \
        build-essential \
        python3-dev \
        curl

# cria diretório da aplicação
WORKDIR /tmp/rest_api

# copia o código python
COPY ./rest_api /tmp/rest_api

# cria o venv e instala depedências
RUN python3 -m venv venv && \
    ./venv/bin/python -m ensurepip --upgrade && \
    ./venv/bin/python -m pip install --upgrade pip setuptools wheel && \
    ./venv/bin/python -m pip install pymysql flask authlib requests

# expõe porta do Flask Server
EXPOSE 5000

# executa o server
CMD ["./venv/bin/python", "main.py"]
