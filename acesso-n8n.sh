#!/bin/bash

echo "🌐 Como Acessar o N8N na EC2 Privada"
echo "===================================="

# Obter informações da infraestrutura
echo "📋 Obtendo informações da infraestrutura..."
INSTANCE_ID=$(terraform output -raw instance_ids | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g' | tr -d ' ')
PRIVATE_IP=$(terraform output -raw instance_private_ips | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g' | tr -d ' ')
VPC_ID=$(terraform output -raw vpc_id)

echo "🖥️  Instance ID: $INSTANCE_ID"
echo "🔒 Private IP: $PRIVATE_IP"
echo "🏗️  VPC ID: $VPC_ID"

echo ""
echo "🔍 Verificando status da instância..."
INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text)
echo "📊 Status: $INSTANCE_STATE"

if [ "$INSTANCE_STATE" != "running" ]; then
    echo "❌ Instância não está rodando. Status: $INSTANCE_STATE"
    exit 1
fi

echo ""
echo "🚀 Opções de Acesso ao N8N:"
echo ""
echo "1️⃣  ACESSO VIA AWS SESSION MANAGER (Recomendado)"
echo "   aws ssm start-session --target $INSTANCE_ID"
echo ""
echo "2️⃣  VERIFICAR STATUS DOS CONTAINERS"
echo "   Executar via SSM para ver se N8N está rodando"
echo ""
echo "3️⃣  PORT FORWARDING VIA SSM"
echo "   Criar túnel para acessar N8N localmente"
echo ""

read -p "Escolha uma opção (1/2/3): " option

case $option in
    1)
        echo "🔗 Conectando via AWS Session Manager..."
        echo "💡 Após conectar, execute:"
        echo "   cd /home/ec2-user/n8n-project"
        echo "   docker ps"
        echo "   docker compose ps"
        echo "   curl http://localhost:5678"
        echo ""
        aws ssm start-session --target $INSTANCE_ID
        ;;
        
    2)
        echo "📊 Verificando status dos containers via SSM..."
        
        COMMAND_ID=$(aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=["cd /home/ec2-user/n8n-project && echo \"=== Docker Status ===\" && docker ps && echo \"\" && echo \"=== Docker Compose Status ===\" && docker compose ps && echo \"\" && echo \"=== Testing N8N ===\" && curl -I http://localhost:5678 && echo \"\" && echo \"=== Testing Traefik ===\" && curl -I http://localhost:80"]' \
            --query 'Command.CommandId' \
            --output text)
        
        echo "📝 Command ID: $COMMAND_ID"
        echo "⏳ Aguardando execução..."
        
        sleep 5
        aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID"
        
        echo "📋 Resultado:"
        aws ssm get-command-invocation \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
            --query 'StandardOutputContent' \
            --output text
        ;;
        
    3)
        echo "🔀 Configurando Port Forwarding via SSM..."
        echo ""
        echo "🚀 Para acessar N8N localmente:"
        echo "1. Execute o comando abaixo em um terminal:"
        echo ""
        echo "   aws ssm start-session --target $INSTANCE_ID \\"
        echo "     --document-name AWS-StartPortForwardingSession \\"
        echo "     --parameters '{\"portNumber\":[\"5678\"],\"localPortNumber\":[\"8080\"]}'"
        echo ""
        echo "2. Depois acesse no navegador:"
        echo "   http://localhost:8080"
        echo ""
        echo "🔧 Para acessar Traefik Dashboard:"
        echo "   aws ssm start-session --target $INSTANCE_ID \\"
        echo "     --document-name AWS-StartPortForwardingSession \\"
        echo "     --parameters '{\"portNumber\":[\"8080\"],\"localPortNumber\":[\"8081\"]}'"
        echo ""
        echo "   Acesse: http://localhost:8081"
        echo ""
        
        read -p "Deseja executar port forwarding para N8N? (y/N): " confirm
        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            echo "🔗 Iniciando port forwarding N8N (porta local 8080)..."
            aws ssm start-session --target $INSTANCE_ID \
                --document-name AWS-StartPortForwardingSession \
                --parameters '{"portNumber":["5678"],"localPortNumber":["8080"]}'
        fi
        ;;
        
    *)
        echo "❌ Opção inválida"
        exit 1
        ;;
esac

echo ""
echo "ℹ️  INFORMAÇÕES IMPORTANTES:"
echo ""
echo "🔒 A EC2 agora está em subnet PRIVADA - mais segura!"
echo "✅ Acesso apenas via AWS Session Manager"
echo "🌐 N8N roda na porta 5678 (interno)"
echo "🔀 Traefik proxy na porta 80 (interno)"
echo "🔧 Traefik dashboard na porta 8080 (interno)"
echo ""
echo "📝 PRÓXIMOS PASSOS:"
echo "- Implementar ALB público (Fase 2)"
echo "- Configurar CloudFront CDN (Fase 3)"
echo "- URLs públicas serão disponibilizadas após ALB"
echo ""
echo "🛠️  Para troubleshooting:"
echo "   ./fix-502.sh"
