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
      - "--certificatesresolvers.mytlschallenge.acme.email=admin@example.com"
      - "--certificatesresolvers.mytlschallenge.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
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
      - "5678:5678"
    labels:
      - traefik.enable=true
      - traefik.http.routers.n8n.rule=Host(`localhost`) || PathPrefix(`/`)
      - traefik.http.routers.n8n.entrypoints=web
      - traefik.http.services.n8n.loadbalancer.server.port=5678
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - GENERIC_TIMEZONE=America/Sao_Paulo
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

# Criar script de restart
echo "=== Criando script de restart ==="
cat > restart-n8n.sh << 'EOFRESTART'
#!/bin/bash
echo "=== Script de Restart do N8N ==="
date
cd /home/ec2-user/n8n-project || exit 1
echo "=== Parando containers existentes ==="
docker compose down --remove-orphans
echo "=== Limpando recursos órfãos ==="
docker system prune -f
docker network prune -f
echo "=== Fazendo pull das imagens ==="
docker compose pull
echo "=== Iniciando containers ==="
docker compose up -d
echo "=== Aguardando inicialização ==="
sleep 30
echo "=== Status dos containers ==="
docker ps
docker compose ps
echo "=== Logs recentes ==="
docker compose logs --tail 10
echo "=== Testando conectividade ==="
curl -I http://localhost:5678 2>/dev/null && echo "✅ N8N OK" || echo "❌ N8N Fail"
curl -I http://localhost:80 2>/dev/null && echo "✅ Traefik OK" || echo "❌ Traefik Fail"
echo "=== Script concluído ==="
date
EOFRESTART

chmod +x restart-n8n.sh

chown -R ec2-user:ec2-user /home/ec2-user/n8n-project

# Aguardar o Docker estar pronto e configurar permissões
echo "=== Configurando Docker e permissões ==="
sleep 10
systemctl restart docker
sleep 5

# Garantir que ec2-user tenha acesso ao Docker
usermod -a -G docker ec2-user
newgrp docker

# Testar Docker
echo "=== Testando Docker ==="
docker --version
docker info

# Testar Docker Compose
echo "=== Testando Docker Compose ==="
docker compose version

# Executar docker-compose
echo "=== Iniciando N8N com Docker Compose ==="
cd /home/ec2-user/n8n-project

# Verificar se Docker está rodando
systemctl status docker --no-pager

# Pull das imagens primeiro
echo "=== Fazendo pull das imagens Docker ==="
docker compose pull

# Executar com retry
for i in {1..3}; do
    echo "=== Tentativa $i de executar Docker Compose ==="
    
    # Parar containers existentes se houver
    docker compose down --remove-orphans 2>/dev/null || true
    
    # Limpar redes orfãs
    docker network prune -f
    
    # Executar containers
    docker compose up -d
    
    # Aguardar containers iniciarem
    sleep 20
    
    # Verificar se containers estão rodando
    RUNNING_CONTAINERS=$(docker compose ps --services --filter "status=running" | wc -l)
    
    if [ "$RUNNING_CONTAINERS" -ge 2 ]; then
        echo "✅ Containers executando com sucesso!"
        break
    else
        echo "❌ Tentativa $i falhou, containers não estão rodando"
        echo "=== Debug - Lista de containers ==="
        docker ps -a
        echo "=== Debug - Logs do N8N ==="
        docker compose logs n8n 2>/dev/null || echo "Sem logs do N8N"
        echo "=== Debug - Logs do Traefik ==="
        docker compose logs traefik 2>/dev/null || echo "Sem logs do Traefik"
        sleep 10
    fi
done

# Aguardar N8N inicializar
echo "=== Aguardando N8N inicializar completamente ==="
sleep 60

# Verificar status dos containers várias vezes
for i in {1..5}; do
    echo "=== Verificação $i - Status dos containers ==="
    docker ps
    docker compose ps
    
    # Verificar logs detalhadamente
    echo "=== Logs recentes do N8N ==="
    docker logs n8n --tail 10 2>/dev/null || echo "Container N8N não encontrado"
    
    echo "=== Logs recentes do Traefik ==="
    docker logs traefik --tail 10 2>/dev/null || echo "Container Traefik não encontrado"
    
    # Verificar se containers estão healthy
    HEALTHY_CONTAINERS=$(docker ps --filter "health=healthy" | wc -l)
    echo "Containers healthy: $HEALTHY_CONTAINERS"
    
    sleep 15
done

# Testar conectividade do N8N
echo "=== Testando conectividade do N8N ==="
for i in {1..20}; do
    # Testar múltiplas portas
    N8N_PORT_5678=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:5678/healthz 2>/dev/null || echo "000")
    TRAEFIK_PORT_80=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:80 2>/dev/null || echo "000")
    TRAEFIK_DASHBOARD=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
    
    echo "Tentativa $i/20:"
    echo "  - N8N (5678): HTTP $N8N_PORT_5678"
    echo "  - Traefik (80): HTTP $TRAEFIK_PORT_80"
    echo "  - Dashboard (8080): HTTP $TRAEFIK_DASHBOARD"
    
    if [ "$N8N_PORT_5678" = "200" ] || [ "$TRAEFIK_PORT_80" = "200" ]; then
        echo "✅ Serviços estão respondendo!"
        break
    elif [ "$N8N_PORT_5678" = "404" ] || [ "$TRAEFIK_PORT_80" = "404" ]; then
        echo "⚠️  Serviços rodando mas endpoint não encontrado"
        break
    else
        echo "⏳ Aguardando serviços ficarem prontos..."
        sleep 15
    fi
done

# Teste adicional de conectividade interna
echo "=== Teste de conectividade interna dos containers ==="
docker exec n8n wget -q --spider http://localhost:5678/healthz && echo "✅ N8N internal health OK" || echo "❌ N8N internal health FAIL"

# Verificar status dos serviços
echo "=== Status final dos serviços ==="
systemctl status docker --no-pager

echo "=== Containers em execução ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "=== Docker Compose status ==="
cd /home/ec2-user/n8n-project
docker compose ps

echo "=== Espaço em disco ==="
df -h

echo "=== Memória disponível ==="
free -h

echo "=== Processos Docker ==="
ps aux | grep docker

# Verificação final de funcionamento
echo "=== Verificação final de funcionamento ==="
FINAL_CHECK_N8N=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:5678 2>/dev/null || echo "000")
FINAL_CHECK_TRAEFIK=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:80 2>/dev/null || echo "000")

if [ "$FINAL_CHECK_N8N" != "000" ] || [ "$FINAL_CHECK_TRAEFIK" != "000" ]; then
    echo "✅ SUCESSO: Serviços N8N estão funcionando!"
else
    echo "❌ ERRO: Serviços N8N não estão respondendo"
    echo "=== Debug final ==="
    docker compose logs --tail 20
fi

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