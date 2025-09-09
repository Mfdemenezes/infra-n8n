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
echo "🔄 Reiniciando a instância EC2..."
echo "Isso vai forçar o restart de todos os serviços"
read -p "Confirma restart da instância? (y/N): " confirm

if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "🔄 Reiniciando instância..."
    aws ec2 reboot-instances --instance-ids $INSTANCE_ID
    
    echo "✅ Comando de restart enviado!"
    echo ""
    echo "⏱️  Aguarde 5-10 minutos e teste novamente:"
    echo "   - ALB: http://$ALB_DNS"
    echo "   - CloudFront: https://d1p60smd1gqw8i.cloudfront.net"
    echo ""
    echo "🔍 Para monitorar o progresso:"
    echo "   aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name'"
else
    echo "❌ Restart cancelado"
fi

echo ""
echo "📝 Outras opções de diagnóstico:"
echo "1. Aguardar mais tempo (pode demorar até 30 min)"
echo "2. Verificar logs via AWS Console"
echo "3. Recriar a infraestrutura se necessário"
