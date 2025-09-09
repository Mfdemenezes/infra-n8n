#!/bin/bash

echo "🔧 Script para Corrigir Docker Compose YAML"
echo "============================================"

# Navegar para o diretório do projeto
cd /home/ec2-user/n8n-project || {
    echo "❌ Diretório n8n-project não encontrado"
    exit 1
}

echo "📂 Atual diretório: $(pwd)"
echo "📋 Arquivos atuais:"
ls -la

# Fazer backup do arquivo problemático
if [ -f docker-compose.yml ]; then
    echo "💾 Fazendo backup do docker-compose.yml atual..."
    cp docker-compose.yml docker-compose.yml.backup
fi

# Criar novo docker-compose.yml corrigido
echo "✨ Criando novo docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
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
EOF

echo "✅ Novo docker-compose.yml criado!"

# Verificar se o YAML está válido
echo "🔍 Validando YAML..."
docker compose config > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ YAML válido!"
else
    echo "❌ YAML ainda tem problemas. Verificando..."
    docker compose config
    exit 1
fi

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker compose down --remove-orphans

# Iniciar containers
echo "🚀 Iniciando containers..."
docker compose up -d

echo "⏱️  Aguardando containers iniciarem..."
sleep 30

echo "📊 Status dos containers:"
docker compose ps

echo "🔍 Logs recentes:"
docker compose logs --tail 10

echo "🌐 Testando conectividade:"
curl -I http://localhost:5678 2>/dev/null && echo "✅ N8N OK" || echo "❌ N8N Fail"
curl -I http://localhost:80 2>/dev/null && echo "✅ Traefik OK" || echo "❌ Traefik Fail"

echo "✅ Script concluído!"
EOF
