FROM n8nio/n8n:latest

# Mudar para usuário root para instalar pacotes
USER root

# Instalar netcat-openbsd
RUN apk add --no-cache netcat-openbsd

# Voltar para o usuário padrão
USER node