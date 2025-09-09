#!/bin/bash

echo "🔧 Script de Diagnóstico e Correção do N8N"
echo "=========================================="

# Obter informações da infraestrutura
echo "📋 Obtendo informações da infraestrutura..."
INSTANCE_ID=$(terraform output -raw instance_ids | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g' | tr -d ' ')
ALB_DNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?starts_with(LoadBalancerName, `n8n-server`)].DNSName' --output text)

echo "🖥️  Instance ID: $INSTANCE_ID"
echo "⚖️  ALB DNS: $ALB_DNS"

echo ""
echo "🔍 Verificando status da instância..."
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].{State:State.Name,LaunchTime:LaunchTime}' --output table

echo ""
echo "�️  Opções de correção:"
echo "1. Corrigir Docker Compose via SSM (recomendado)"
echo "2. Reiniciar instância EC2 (força novo user_data)"
echo "3. Apenas verificar status"
echo ""
read -p "Escolha uma opção (1/2/3): " option

case $option in
    1)
        echo "🔧 Corrigindo Docker Compose via SSM..."
        
        # Criar script de correção
        cat > temp-fix-compose.sh << 'EOFFIX'
#!/bin/bash
echo "=== Corrigindo Docker Compose ==="
cd /home/ec2-user/n8n-project || exit 1

# Backup do arquivo atual
cp docker-compose.yml docker-compose.yml.backup 2>/dev/null || true

# Criar novo docker-compose.yml corrigido
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
      - traefik.http.routers.n8n.rule=Host(\`localhost\`) || PathPrefix(\`/\`)
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

echo "✅ Docker Compose YAML corrigido!"

# Validar YAML
echo "🔍 Validando YAML..."
docker compose config > /dev/null 2>&1 && echo "✅ YAML válido!" || echo "❌ YAML ainda tem problemas"

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker compose down --remove-orphans 2>/dev/null || true

# Limpar recursos órfãos
echo "🧹 Limpando recursos..."
docker system prune -f

# Iniciar containers
echo "🚀 Iniciando containers..."
docker compose up -d

# Aguardar containers iniciarem
echo "⏱️  Aguardando containers iniciarem..."
sleep 30

# Verificar status
echo "📊 Status dos containers:"
docker ps
echo ""
docker compose ps

echo "🔍 Logs recentes:"
docker compose logs --tail 10

echo "🌐 Testando conectividade:"
curl -I http://localhost:5678 2>/dev/null && echo "✅ N8N OK" || echo "❌ N8N Fail"
curl -I http://localhost:80 2>/dev/null && echo "✅ Traefik OK" || echo "❌ Traefik Fail"

echo "✅ Correção concluída!"
EOFFIX

        # Executar via SSM
        echo "📤 Enviando script para instância via SSM..."
        COMMAND_ID=$(aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters "commands=['$(cat temp-fix-compose.sh)']" \
            --query 'Command.CommandId' \
            --output text)
        
        echo "📝 Command ID: $COMMAND_ID"
        echo "⏳ Aguardando execução..."
        
        # Aguardar comando completar
        sleep 5
        aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID"
        
        # Obter resultado
        echo "📋 Resultado da execução:"
        aws ssm get-command-invocation \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
            --query 'StandardOutputContent' \
            --output text
        
        # Limpar arquivo temporário
        rm -f temp-fix-compose.sh
        
        echo ""
        echo "✅ Correção via SSM concluída!"
        ;;
        
    2)
        echo "🔄 Reiniciando a instância EC2..."
        echo "Isso vai forçar o restart de todos os serviços"
        read -p "Confirma restart da instância? (y/N): " confirm

        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            echo "🔄 Reiniciando instância..."
            aws ec2 reboot-instances --instance-ids $INSTANCE_ID
            
            echo "✅ Comando de restart enviado!"
        else
            echo "❌ Restart cancelado"
        fi
        ;;
        
    3)
        echo "📊 Verificando apenas status..."
        ;;
        
    *)
        echo "❌ Opção inválida"
        exit 1
        ;;
esac

echo ""
echo "⏱️  Aguarde alguns minutos e teste novamente:"
echo "   - ALB: http://$ALB_DNS"
echo "   - CloudFront: https://d1p60smd1gqw8i.cloudfront.net"
echo ""
echo "� Para monitorar o progresso:"
echo "   aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name'"
echo ""
echo "�📝 Outras opções de diagnóstico:"
echo "1. Aguardar mais tempo (pode demorar até 30 min)"
echo "2. Verificar logs via AWS Console"
echo "3. Conectar via SSM: aws ssm start-session --target $INSTANCE_ID"
echo "4. Recriar a infraestrutura se necessário"
