FROM debian:12

# instala pacotes necessários
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      python3 python3-venv python3-pip \
      default-libmysqlclient-dev build-essential curl \
 && rm -rf /var/lib/apt/lists/*

# cria venv
ENV VENV_PATH=/opt/venv
RUN python3 -m venv $VENV_PATH \
 && $VENV_PATH/bin/python -m pip install --upgrade pip setuptools wheel

# define o venv como diretório de referência dos binários,
#   usado nesse caso para definir o 'python3' à partir do venv
ENV PATH="$VENV_PATH/bin:$PATH"

# copia o seu código e instala bibliotecas
WORKDIR /app
COPY ./auth_api /app
RUN pip install pymysql flask authlib requests

EXPOSE 5001
#CMD ["python", "auth.py"]
CMD ["tail", "-f", "/dev/null"]
