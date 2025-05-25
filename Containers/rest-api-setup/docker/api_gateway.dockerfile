FROM debian:12

# Instala dependências básicas (ajuste conforme necessário)
RUN chmod 1777 /tmp \
    apt update && apt upgrade -y && apt install -y python3 \
    python3.11-venv \
    default-libmysqlclient-dev \
    build-essential \
    python3-dev

# Copia os arquivos da API para dentro da imagem
COPY ../rest_api /tmp
COPY ./api_gateway_dependencies.sh /tmp

# Executa o script de instalação de dependências
RUN chmod +x /tmp/api_gateway_dependencies.sh && \
    /bin/bash /tmp/api_gateway_dependencies.sh

# Expõe a porta usada pela aplicação
EXPOSE 5000

# Comando padrão ao iniciar o container
CMD ["python3", "/tmp/main.py"]
