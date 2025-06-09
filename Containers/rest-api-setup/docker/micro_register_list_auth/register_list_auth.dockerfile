FROM debian:12

# Instala pacotes necessários
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      python3 python3-venv python3-pip \
      default-libmysqlclient-dev build-essential curl \
 && rm -rf /var/lib/apt/lists/*

# Cria venv
ENV VENV_PATH=/opt/venv
RUN python3 -m venv $VENV_PATH \
 && $VENV_PATH/bin/python -m pip install --upgrade pip setuptools wheel

# Define o venv como referência padrão
ENV PATH="$VENV_PATH/bin:$PATH"

# Define o diretório da aplicação
WORKDIR /app

# Copia o código-fonte
COPY ./register_list_auth_api /app

# Instala dependências Python
RUN pip install pymysql flask authlib requests

EXPOSE 5003
CMD ["python", "register_list_auth.py"]