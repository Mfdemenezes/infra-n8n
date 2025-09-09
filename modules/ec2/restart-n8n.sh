#!/bin/bash

echo "=== Script de Restart do N8N ==="
date

cd /home/ec2-user/n8n-project || exit 1

echo "=== Parando containers existentes ==="
docker compose down --remove-orphans

echo "=== Limpando recursos órfãos ==="
docker system prune -f
docker network prune -f

echo "=== Verificando arquivos de configuração ==="
ls -la
echo "--- Conteúdo do docker-compose.yml ---"
head -20 docker-compose.yml

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
