#!/bin/bash

# Log de execução
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Iniciando configuração do servidor N8N ==="
date

# Atualizar sistema
echo "=== Atualizando sistema ==="
yum update -y

# Instalar Docker
echo "=== Instalando Docker ==="
yum install -y docker git
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Instalar Docker Compose v2
echo "=== Instalando Docker Compose v2 ==="
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Criar link simbólico para compatibilidade
ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Adicionar swap para melhor performance
echo "=== Configurando swap ==="
dd if=/dev/zero of=/swapfile bs=128M count=32
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

# Criar diretório para o projeto N8N
echo "=== Configurando diretório do projeto ==="
mkdir -p /home/ec2-user/n8n-project
cd /home/ec2-user/n8n-project

# Copiar o compose.yaml do módulo terraform
echo "=== Criando docker-compose.yml ==="
cat > docker-compose.yml << 'EOFCOMPOSE'
services:
  traefik:
    container_name: traefik 
    image: "traefik:v3.0"
    restart: always
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.mytlschallenge.acme.tlschallenge=true"
      - "--certificatesresolvers.mytlschallenge.acme.email=\$${SSL_EMAIL:-admin@example.com}"
      - "--certificatesresolvers.mytlschallenge.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Dashboard do Traefik
    volumes:
      - ./acme.json:/letsencrypt/acme.json
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - n8n-network

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n
    restart: always
    ports:
      - "5678:5678"  # Porta direta para debug
    labels:
      - traefik.enable=true
      - traefik.http.routers.n8n.rule=Host(\`localhost\`) || PathPrefix(\`/\`)
      - traefik.http.routers.n8n.entrypoints=web
      - traefik.http.services.n8n.loadbalancer.server.port=5678
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - GENERIC_TIMEZONE=\$${GENERIC_TIMEZONE:-America/Sao_Paulo}
      - N8N_METRICS=true
      - N8N_LOG_LEVEL=info
      - DB_TYPE=sqlite
      - N8N_SECURE_COOKIE=false
    volumes:
      - n8n_data:/home/node/.n8n
      - ./local-files:/files
    networks:
      - n8n-network
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:5678/healthz || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  n8n_data:
    driver: local

networks:
  n8n-network:
    driver: bridge
EOFCOMPOSE

# Criar arquivo .env
echo "=== Criando arquivo .env ==="
cat > .env << EOFENV
# Configurações N8N
GENERIC_TIMEZONE=${timezone}
SSL_EMAIL=admin@example.com
NODE_ENV=production
EOFENV

# Criar arquivo acme.json para certificados SSL
echo "=== Criando arquivo acme.json ==="
touch acme.json
chmod 600 acme.json

# Criar diretório para arquivos locais
echo "=== Criando estrutura de diretórios ==="
mkdir -p local-files
chown -R ec2-user:ec2-user /home/ec2-user/n8n-project

# Aguardar o Docker estar pronto
echo "=== Aguardando Docker estar pronto ==="
sleep 15

# Executar docker-compose
echo "=== Iniciando N8N com Docker Compose ==="
cd /home/ec2-user/n8n-project
sudo -u ec2-user docker compose up -d

# Aguardar N8N inicializar
echo "=== Aguardando N8N inicializar ==="
sleep 30

# Verificar status dos containers
echo "=== Verificando status dos containers ==="
docker ps
docker logs n8n --tail 20

# Testar conectividade do N8N
echo "=== Testando conectividade do N8N ==="
for i in {1..15}; do
    if curl -f http://localhost:5678/healthz >/dev/null 2>&1; then
        echo "✅ N8N está respondendo na porta 5678!"
        break
    elif curl -f http://localhost:80 >/dev/null 2>&1; then
        echo "✅ Traefik está respondendo na porta 80!"
        break
    else
        echo "⏳ Tentativa $i/15 - N8N ainda não está pronto..."
        sleep 10
    fi
done

# Verificar status dos serviços
echo "=== Status final dos serviços ==="
systemctl status docker --no-pager
docker compose ps

# Obter IP da instância
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "=== Configuração concluída ==="
echo "✅ N8N está disponível em:"
echo "   - Direto N8N: http://$INSTANCE_IP:5678"
echo "   - Via Traefik: http://$INSTANCE_IP:80"
echo "   - Traefik Dashboard: http://$INSTANCE_IP:8080"
echo "   - Health check N8N: http://$INSTANCE_IP:5678/healthz"

date
echo "=== Fim da configuração ==="