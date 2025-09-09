# Projeto Terraform - Infraestrutura AWS

Este projeto contém configurações Terraform para provisionar uma infraestrutura completa na AWS, incluindo instâncias EC2, buckets S3, redes e grupos de segurança.

**✅ Backend remoto S3 configurado para gerenciamento de state**

## 📋 Descrição

O projeto utiliza uma arquitetura modular do Terraform para criar uma infraestrutura escalável e reutilizável na AWS. A infraestrutura inclui:

- **EC2**: Instâncias configuráveis com suporte ao SSM Session Manager
- **VPC/Networking**: VPC personalizada com subnets públicas
- **Security Groups**: Grupos de segurança configuráveis
- **S3**: Buckets com configurações de segurança e criptografia
- **EBS**: Volumes criptografados anexados às instâncias

## 🏗️ Arquitetura

```
├── main.tf              # Configuração principal e módulos
├── variables.tf         # Variáveis de entrada
├── outputs.tf          # Outputs dos recursos criados
├── terraform.tfvars    # Valores específicos das variáveis
└── modules/
    ├── ec2/           # Módulo para instâncias EC2
    ├── network/       # Módulo para VPC e networking
    ├── s3/           # Módulo para buckets S3
    └── sg/           # Módulo para security groups
```

## 🚀 Como usar

### Pré-requisitos

1. **Terraform** instalado (versão 1.0+)
2. **AWS CLI** configurado com credenciais válidas
3. Permissões adequadas na AWS para criar os recursos

### Configuração

1. Clone o repositório:
```bash
git clone <repository-url>
cd terraform
```

2. Configure suas variáveis no arquivo `terraform.tfvars`:
```hcl
# Exemplo de configuração
region = "us-east-1"
environment = "development"
ec2_name = "meu-projeto"
ec2_instance_type = "t2.micro"
vpc_cidr = "10.0.0.0/16"
```

### Deploy

1. Inicialize o Terraform:
```bash
terraform init
```

2. Revise o plano de execução:
```bash
terraform plan
```

3. Aplique as configurações:
```bash
terraform apply
```

### Destruição

Para remover todos os recursos:
```bash
terraform destroy
```

## 📝 Variáveis Principais

| Variável | Descrição | Tipo | Padrão |
|----------|-----------|------|--------|
| `region` | Região AWS | string | us-east-1 |
| `environment` | Ambiente (dev/prod/staging) | string | development |
| `ec2_instance_type` | Tipo da instância EC2 | string | t2.micro |
| `ec2_count` | Número de instâncias | number | 1 |
| `vpc_cidr` | CIDR da VPC | string | 10.0.0.0/16 |
| `enable_ssm` | Habilitar SSM Session Manager | bool | true |
| `s3_enable_encryption` | Criptografia do S3 | bool | true |

## 📊 Outputs

O projeto retorna os seguintes outputs após o deploy:

- **EC2 Instance IDs**: IDs das instâncias criadas
- **Public IPs**: IPs públicos das instâncias
- **VPC ID**: ID da VPC criada
- **S3 Bucket Name**: Nome do bucket S3 criado
- **Security Group ID**: ID do grupo de segurança

## 🔧 Customização

### Security Groups

As regras do security group podem ser customizadas através da variável `sg_ingress_rules`:

```hcl
sg_ingress_rules = [
  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }
]
```

### User Data

Você pode fornecer scripts personalizados via variável `custom_user_data`:

```hcl
custom_user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
EOF
```

## 🛡️ Segurança

- **EBS**: Volumes criptografados por padrão
- **S3**: Buckets com acesso público bloqueado
- **SSM**: Session Manager habilitado para acesso seguro
- **Security Groups**: Regras configuráveis por protocolo

## 📋 Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0
- Credenciais AWS configuradas
- Permissões IAM adequadas

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👨‍💻 Autor

**Marcelo Menezes**

- GitHub: [@Mfdemenezes](https://github.com/Mfdemenezes)
- Email: seu.email@exemplo.com

## 📚 Recursos Úteis

- [Documentação do Terraform](https://developer.hashicorp.com/terraform/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

⭐ Se este projeto foi útil para você, considere dar uma estrela no repositório!
