# Documentação Completa: n8n no Render com PostgreSQL

## Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura](#arquitetura)
3. [Pré-requisitos](#pré-requisitos)
4. [Quick Start](#quick-start)
5. [Implantação no Render](#implantação-no-render)
6. [Configuração do PostgreSQL](#configuração-do-postgresql)
7. [Variáveis de Ambiente](#variáveis-de-ambiente)
8. [Acessando o n8n](#acessando-o-n8n)
9. [Troubleshooting](#troubleshooting)

---

## Quick Start

Se você está com pressa, siga estes passos para colocar n8n funcionando rapidamente:

### 1. Crie o PostgreSQL (2 min)
- Dashboard Render → **New** → **PostgreSQL**
- Name: `n8n-database`, Region: `oregon`
- Clique em **Create Database**

### 2. Configure as Permissões (3 min) ⚠️ IMPORTANTE
- Na página do PostgreSQL, clique em **Shell**
- Execute: `psql -U postgres -d n8n`
- Cole os comandos SQL (veja seção de permissões acima)
- Saia com `\q`

### 3. Crie o Blueprint do n8n (5 min)
- Dashboard Render → **New** → **Blueprint**
- Conecte seu repositório GitHub/GitLab
- Clique em **Create Blueprint**
- Clique em **Apply** e depois **Deploy**

### 4. Faça Deploy Manual (10 min)
- Após o PostgreSQL estar pronto
- Clique em **n8n** → **Manual Deploy**
- Aguarde os logs: "n8n ready on ::, port 5678"

### 5. Acesse o n8n (1 min)
- Acesse a URL fornecida pelo Render
- Crie sua conta de administrador
- Comece a criar workflows!

---

## Visão Geral

Este projeto facilita a implantação do n8n, uma plataforma poderosa de automação de fluxos de trabalho, na plataforma Render. O n8n funciona com um banco de dados para armazenar workflows, credenciais, histórico de execução e outras informações essenciais.

### O que é n8n?

n8n é uma ferramenta open-source de automação que permite criar workflows complexos conectando centenas de aplicações e serviços sem código ou com código customizado.

### Por que usar PostgreSQL?

O SQLite (padrão do n8n) é adequado para desenvolvimento, mas para produção, PostgreSQL oferece:
- Melhor performance com múltiplos workflows
- Escalabilidade
- Backup e recuperação robustos
- Suporte a múltiplos usuários simultâneos

---

## Arquitetura

```
┌─────────────────────────────────────────┐
│          Render Platform                │
├─────────────────────────────────────────┤
│  ┌──────────────────────────────────┐   │
│  │  n8n (Web Service - Docker)      │   │
│  │  Port: 5678                      │   │
│  └──────────────┬───────────────────┘   │
│                 │                       │
│                 ▼                       │
│  ┌──────────────────────────────────┐   │
│  │  PostgreSQL (Database Service)   │   │
│  │  Port: 5432                      │   │
│  └──────────────────────────────────┘   │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │  Persistent Storage (Disk)       │   │
│  │  Path: /home/node/.n8n           │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## Pré-requisitos

- Conta ativa no [Render.com](https://render.com)
- Repositório GitHub ou GitLab com este projeto
- Conhecimento básico de variáveis de ambiente
- Acesso às credenciais e informações de conexão

---

## Implantação no Render

### Passo 1: Preparar o Repositório

Certifique-se de que seu repositório contém os seguintes arquivos:

```
projeto/
├── Dockerfile
├── render.yaml
├── README.md
└── .gitignore (opcional)
```

### Passo 2: Criar o Blueprint no Render

1. Acesse [dashboard.render.com](https://dashboard.render.com)
2. Clique em **"New" → "Blueprint"**
3. Conecte seu repositório GitHub ou GitLab
4. Nomeie o blueprint: `n8n-deployment`
5. Clique em **"Create Blueprint"**

### Passo 3: Revisar a Configuração

O Render lerá automaticamente o arquivo `render.yaml` e criará os serviços necessários. Você verá:
- **n8n Web Service**: Serviço web principal
- **n8n Database**: Banco de dados PostgreSQL (após configuração)

### Passo 4: Aprovar e Implantar

1. Clique em **"Apply"**
2. Revise as configurações
3. Clique em **"Deploy"**

A implantação começará e levará aproximadamente 5-10 minutos.

---

## Configuração do PostgreSQL

### Opção 1: Usar o PostgreSQL do Render (Recomendado)

#### Criar um Serviço PostgreSQL

1. No dashboard do Render, clique em **"New" → "PostgreSQL"**
2. Preencha os detalhes:
   - **Name**: `n8n-database`
   - **Database**: `n8n`
   - **User**: `n8n_user`
   - **Region**: `Oregon` (mesma região do n8n)
3. Selecione o plano (Starter é adequado para início)
4. Clique em **"Create Database"**

#### Obter Informações de Conexão

Após criação, anote as seguintes informações:
- **Host**: `dpg-xxxxx.render.internal`
- **Port**: `5432`
- **Database**: `n8n`
- **User**: `n8n_user`
- **Password**: Será gerado automaticamente

#### ⚠️ IMPORTANTE: Corrigir Permissões do PostgreSQL

Após criar o banco de dados, você **DEVE** configurar as permissões do usuário `n8n_user` na schema `public`. Sem isso, o n8n falhará com erro: `permission denied for schema public`

##### Passos para Corrigir Permissões:

1. **Acesse o Shell do PostgreSQL**
   - No dashboard do Render, clique em **n8n-database**
   - Clique em **"Shell"** na aba superior
   - Será aberto um terminal

2. **Conecte ao PostgreSQL como administrador**
   ```bash
   psql -U postgres -d n8n
   ```
   (Será solicitada a senha, use a do usuário postgres)

3. **Execute os comandos SQL para corrigir permissões**
   ```sql
   -- Dar permissões de conexão no banco de dados
   GRANT CONNECT ON DATABASE n8n TO n8n_user;

   -- Dar permissões na schema public
   GRANT USAGE ON SCHEMA public TO n8n_user;
   GRANT CREATE ON SCHEMA public TO n8n_user;

   -- Dar permissões em todas as tabelas (atuais e futuras)
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO n8n_user;
   GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO n8n_user;

   -- Definir permissões padrão para novas tabelas
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO n8n_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO n8n_user;

   -- Dar proprietário da schema public ao n8n_user (recomendado)
   ALTER SCHEMA public OWNER TO n8n_user;
   ```

4. **Verificar se funcionou**
   ```sql
   -- Listar permissões
   \dp
   
   -- Sair
   \q
   ```

5. **Fazer deploy manual do n8n**
   - Volte ao dashboard do Render
   - Clique em **n8n** (serviço web)
   - Clique em **"Manual Deploy"**
   - Aguarde a conclusão (deve levar 5-10 minutos)

### Opção 2: Atualizar `render.yaml` para Incluir PostgreSQL

Se preferir definir PostgreSQL via Blueprint, atualize seu `render.yaml`:

```yaml
services:
  - type: web
    name: n8n
    env: docker
    plan: starter
    region: oregon
    autoDeploy: true
    
    disk:
      name: n8n_data
      mountPath: /home/node/.n8n
      sizeGB: 1
    
    envVars:
      - key: DB_TYPE
        value: postgresdb
      - key: DB_POSTGRESDB_HOST
        fromService:
          name: n8n-database
          type: pserv
          property: host
      - key: DB_POSTGRESDB_PORT
        value: "5432"
      - key: DB_POSTGRESDB_DATABASE
        value: n8n
      - key: DB_POSTGRESDB_USER
        value: n8n_user
      - key: DB_POSTGRESDB_PASSWORD
        fromService:
          name: n8n-database
          type: pserv
          property: password

  - type: pserv
    name: n8n-database
    plan: starter
    region: oregon
    ipAllowList: []
    postgresMajorVersion: 15
```

---

## Variáveis de Ambiente

Configure as seguintes variáveis de ambiente no painel do Render:

### Variáveis Essenciais

| Variável | Valor | Descrição |
|----------|-------|-----------|
| `N8N_PORT` | `5678` | Porta da aplicação n8n |
| `N8N_PROTOCOL` | `https` | Use HTTPS em produção |
| `N8N_HOST` | `0.0.0.0` | Escuta em todos os IPs |
| `N8N_SECURE_COOKIE` | `true` | Cookies seguros (HTTPS) |

### Variáveis de Banco de Dados

| Variável | Valor | Descrição |
|----------|-------|-----------|
| `DB_TYPE` | `postgresdb` | Tipo de banco (PostgreSQL) |
| `DB_POSTGRESDB_HOST` | `dpg-xxxxx.render.internal` | Host do PostgreSQL |
| `DB_POSTGRESDB_PORT` | `5432` | Porta do PostgreSQL |
| `DB_POSTGRESDB_DATABASE` | `n8n` | Nome do banco |
| `DB_POSTGRESDB_USER` | `n8n_user` | Usuário do banco |
| `DB_POSTGRESDB_PASSWORD` | `[sua-senha]` | Senha do banco |

### Variáveis de Segurança

| Variável | Descrição |
|----------|-----------|
| `N8N_ENCRYPTION_KEY` | Chave para criptografar credenciais (será gerada automaticamente) |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | `true` - Garante permissões seguras |

### Variáveis Opcionais

| Variável | Valor | Descrição |
|----------|-------|-----------|
| `WEBHOOK_URL` | Sincronizar automaticamente | URL pública para webhooks |
| `N8N_TEMPLATES_ENABLED` | `true` | Habilita templates pré-prontos |
| `N8N_LOG_LEVEL` | `info` | Nível de log (info, debug, warn, error) |

#### Como Adicionar Variáveis no Render

1. Acesse seu serviço n8n no dashboard
2. Clique em **"Environment"**
3. Clique em **"Add Environment Variable"**
4. Preencha **Key** e **Value**
5. Clique em **"Save"**
6. Seu serviço será reiniciado automaticamente

---

## Acessando o n8n

### Primeira Execução

1. Acesse a URL fornecida pelo Render (ex: `https://n8n-xxxxx.onrender.com`)
2. Na primeira execução, será solicitado que você crie uma conta de administrador
3. Preencha os dados:
   - **Email**: Seu email
   - **Senha**: Uma senha segura
4. Clique em **"Get Started"**

### Login Subsequentes

1. Acesse a URL do seu n8n
2. Introduza suas credenciais
3. Clique em **"Sign In"**

### Usar a Instância

Após login, você terá acesso a:
- **Workflows**: Criar e gerenciar automações
- **Credentials**: Armazenar credenciais seguras
- **Executions**: Histórico de execuções
- **Templates**: Templates pré-prontos
- **Settings**: Configurações da instância

---

## Troubleshooting

### Problema: Erro "permission denied for schema public"

**Este é o erro mais comum ao configurar PostgreSQL no Render.**

**Sintomas:**
```
There was an error running database migrations
permission denied for schema public
```

**Solução:**

1. **Acesse o Shell do PostgreSQL no Render**
   - Dashboard → **n8n-database** → **Shell**

2. **Conecte como administrador**
   ```bash
   psql -U postgres -d n8n
   ```

3. **Execute os comandos para corrigir permissões**
   ```sql
   GRANT CONNECT ON DATABASE n8n TO n8n_user;
   GRANT USAGE ON SCHEMA public TO n8n_user;
   GRANT CREATE ON SCHEMA public TO n8n_user;
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO n8n_user;
   GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO n8n_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO n8n_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO n8n_user;
   ALTER SCHEMA public OWNER TO n8n_user;
   ```

4. **Saia do psql**
   ```sql
   \q
   ```

5. **Faça deploy manual do n8n**
   - Dashboard → **n8n** → **Manual Deploy**

### Problema: Erro de Conexão com PostgreSQL

**Solução:**
1. Verifique se o PostgreSQL está rodando no Render
2. Confirme que as variáveis de conexão estão corretas
3. Certifique-se de que host, porta, usuário e senha estão corretos
4. Verifique as permissões usando o comando `\dp` no psql
5. Reinicie o serviço n8n

### Problema: n8n Não Inicia

**Solução:**
1. Verifique os logs: Dashboard → Serviço n8n → **"Logs"**
2. Procure por erros de conexão ou configuração
3. Valide todas as variáveis de ambiente
4. Tente reconstruir a imagem Docker

### Problema: Workflows Lentos

**Solução:**
1. Verifique se o PostgreSQL está em regiões diferentes (coloque na mesma região)
2. Aumente o tamanho do plano se necessário
3. Verifique a CPU e memória nos logs do Render
4. Otimize os workflows para evitar loops infinitos

### Problema: Perda de Dados após Deploy

**Solução:**
1. Verifique se o disco persistente está configurado
2. Confirme que `render.yaml` contém:
   ```yaml
   disk:
     name: n8n_data
     mountPath: /home/node/.n8n
     sizeGB: 1
   ```
3. Verifique se PostgreSQL está salvando dados corretamente
4. Configure backups automáticos do PostgreSQL

### Problema: Erro 502 Bad Gateway

**Solução:**
1. Aguarde o serviço completar o deploy
2. Verifique se a porta está correta (5678)
3. Reinicie o serviço
4. Aumente o tempo de timeout se necessário

---

## Boas Práticas

### Segurança

- Use HTTPS em produção
- Altere a senha do administrador regularmente
- Armazene credenciais sensíveis como variáveis de ambiente
- Use chaves de criptografia fortes
- Habilite autenticação de dois fatores se disponível

### Performance

- Mantenha PostgreSQL na mesma região que n8n
- Use índices de banco de dados para queries frequentes
- Monitore o uso de CPU e memória
- Agende workflows para horários de baixo uso

### Backup e Recuperação

- Configure backups automáticos do PostgreSQL
- Faça download regular dos seus workflows
- Mantenha cópias das credenciais em local seguro
- Teste regularmente a recuperação de backups

### Monitoramento

- Verifique logs regularmente
- Configure alertas para falhas de execução
- Monitore o uso de armazenamento
- Acompanhe a performance dos workflows

---

## Próximas Etapas

1. **Criar seu primeiro workflow**: Conecte duas aplicações simples
2. **Explorar integrações**: Veja as centenas de apps disponíveis
3. **Automatizar tarefas**: Implemente suas primeiras automações
4. **Convidar usuários**: Adicione mais membros à sua equipe
5. **Configurar webhooks**: Acione workflows via URLs

---

## Recursos Úteis

- [Documentação Oficial do n8n](https://docs.n8n.io)
- [Documentação do Render](https://render.com/docs)
- [Comunidade n8n no Discord](https://discord.gg/n8n)
- [Blog n8n](https://blog.n8n.io)

---

## Suporte

Para problemas ou dúvidas:
- Consulte os logs no dashboard do Render
- Visite o [fórum da comunidade n8n](https://community.n8n.io)
- Abra uma issue no repositório do projeto
- Contacte o suporte do Render