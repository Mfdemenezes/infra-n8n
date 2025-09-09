# 🚀 Infraestrutura N8N na AWS

Projeto Terraform para deploy automatizado do N8N com arquitetura segura na AWS.

## 🏗️ Arquitetura

```
Internet → CloudFront → ALB → EC2 (subnet privada)
```

### Componentes:
- **EC2**: Instância em subnet privada executando N8N via Docker
- **ALB**: Application Load Balancer em subnets públicas  
- **CloudFront**: CDN global para acesso seguro e performático
- **VPC**: Rede privada com subnets públicas e privadas
- **Security Groups**: Regras de firewall restritivas

## 🌐 URLs de Acesso

### Principal (Produção):
```
https://d1p60smd1gqw8i.cloudfront.net
```

### Debug (ALB direto):
```
http://n8n-server-alb-360419528.us-east-1.elb.amazonaws.com
```

## 🔧 Deploy

### Via GitHub Actions:
1. Configure os secrets no GitHub:
   - `CLI_USER_ACCESS_KEY_ID`
   - `CLI_USER_SECRET_ACCESS_KEY`

2. Execute o workflow:
   - Acesse: Actions → "🚀 Terraform CI/CD Pipeline"
   - Selecione: "Run workflow" → "apply"

### Via CLI Local:
```bash
terraform init
terraform plan
terraform apply
```

## 📋 Configurações

### Principais variáveis (terraform.tfvars):
```hcl
ec2_name = "n8n-server"
region = "us-east-1"
vpc_cidr = "10.0.0.0/16"
generic_timezone = "America/Sao_Paulo"
enable_cloudfront = true
```

## 🚨 Troubleshooting

### Erro 502 (Bad Gateway):
1. **Aguarde**: N8N demora 10-15 min para inicializar
2. **Reinicie EC2**: `aws ec2 reboot-instances --instance-ids <instance-id>`
3. **Verifique logs**: Acesse via AWS Console → EC2 → System Log

### Comandos úteis:
```bash
# Ver outputs da infraestrutura
terraform output

# Status da instância
aws ec2 describe-instances --instance-ids <id> --query 'Reservations[0].Instances[0].State.Name'

# Logs do user-data
# (via AWS Console → EC2 → Instance → Actions → Monitor and troubleshoot → Get system log)
```

## 📁 Estrutura do Projeto

```
├── main.tf                    # Configuração principal
├── variables.tf               # Variáveis globais
├── terraform.tfvars          # Valores das variáveis
├── outputs.tf                # Outputs da infraestrutura
├── modules/
│   ├── network/              # VPC, subnets, gateways
│   ├── ec2/                  # Instâncias e configuração N8N
│   ├── alb/                  # Application Load Balancer
│   ├── cloudfront/           # CloudFront distribution
│   ├── s3/                   # Buckets S3
│   └── sg/                   # Security Groups
└── .github/
    └── workflows/            # GitHub Actions pipelines
```

## 🔒 Segurança

- EC2 em subnet privada (sem IP público)
- Acesso externo apenas via CloudFront
- Security Groups com regras mínimas
- Volumes EBS criptografados
- IAM roles com princípio do menor privilégio

## ⚡ Performance

- CloudFront para cache global
- ALB para balanceamento de carga
- Instância otimizada com swap
- Docker Compose para gestão de containers

## 👨‍💻 Autor

**Marcelo Menezes**
- GitHub: [@Mfdemenezes](https://github.com/Mfdemenezes)
