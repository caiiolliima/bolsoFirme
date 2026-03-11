# Fase 0 — Setup: Fundação do Projeto

> **Estimativa:** 2–3 semanas | **Pré-requisito:** nenhum | **Desbloquia:** Fase 1
>
> Esta fase cria toda a estrutura que o projeto vai precisar: monorepo organizado, banco de dados rodando, servidor básico funcionando e autenticação completa. Não tem nenhuma tela ainda — só fundação sólida.

---

## T0.1 — Monorepo Turborepo + Estrutura de Pastas

**Status:** [ ] Pendente

**O que é:** Criar o repositório com Turborepo para gerenciar os pacotes (frontend, backend, código compartilhado) num único lugar, com builds rápidos e cache inteligente.

**Prompt para IA:**
```
Estou iniciando um projeto chamado BolsoFirme — um app de controle financeiro pessoal.
Preciso criar um monorepo com Turborepo contendo a seguinte estrutura:

apps/
  web/       → React + Vite + TypeScript (frontend)
  api/       → Node.js + TypeScript + Express (backend)
packages/
  shared/    → Tipos TypeScript e schemas Zod compartilhados entre web e api

Me mostre:
1. Como inicializar o monorepo com `npx create-turbo@latest`
2. A estrutura final de pastas com os arquivos necessários
3. O conteúdo do turbo.json com os pipelines: build, dev, lint, test
4. O package.json raiz com os workspaces configurados
5. Um script de `dev` que suba web e api ao mesmo tempo
```

**Subtasks:**
- [ ] Rodar `npx create-turbo@latest bolsoFirme` e escolher npm/pnpm
- [ ] Apagar os apps de exemplo que o Turborepo cria (docs/, web/ padrão)
- [ ] Criar a estrutura `apps/web`, `apps/api`, `packages/shared` manualmente
- [ ] Configurar o `turbo.json` com pipelines: `build`, `dev`, `lint`, `test`
- [ ] Testar que `npm run dev` (na raiz) sobe web e api ao mesmo tempo
- [ ] Fazer o primeiro commit: `git init` + `git commit -m "chore: monorepo setup"`

---

## T0.2 — TypeScript, ESLint e Prettier *(sintetizado — as 3 configs juntas)*

**Status:** [ ] Pendente

**O que é:** Configurar a linguagem TypeScript e as ferramentas de qualidade de código. São 3 ferramentas simples que se configuram de forma parecida — por isso estão numa task só.

**Prompt para IA:**
```
No monorepo BolsoFirme (Turborepo + npm workspaces), preciso configurar TypeScript, ESLint e Prettier de forma compartilhada.

Stack: Node.js 20, React 18, TypeScript 5.

Me mostre:
1. tsconfig.json base na raiz (strict: true, target: ES2022)
2. tsconfig.json para apps/api (extende o base, adiciona paths do Node)
3. tsconfig.json para apps/web (extende o base, adiciona JSX)
4. .eslintrc.json na raiz com regras para TypeScript + React
5. .prettierrc na raiz (singleQuote: true, semi: false, tabWidth: 2)
6. Script "lint" no package.json raiz que roda eslint em todos os packages
```

**Subtasks:**
- [ ] Criar `tsconfig.base.json` na raiz com configurações strict compartilhadas
- [ ] Criar `tsconfig.json` em `apps/api` e `apps/web` extendendo o base
- [ ] Instalar e configurar ESLint + plugins (TypeScript, React)
- [ ] Instalar e configurar Prettier + `.prettierrc`
- [ ] Rodar `npm run lint` na raiz e confirmar que não há erros
- [ ] Adicionar `.prettierignore` e `.eslintignore` para excluir `node_modules` e `dist`

---

## T0.3 — Docker Compose (PostgreSQL + Prisma Studio)

**Status:** [ ] Pendente

**O que é:** Criar um arquivo Docker Compose que sobe o banco de dados PostgreSQL e o Prisma Studio (interface visual para ver os dados) com um único comando, sem precisar instalar o Postgres na máquina.

**Prompt para IA:**
```
No projeto BolsoFirme preciso de um docker-compose.yml que suba:

1. PostgreSQL 16
   - Banco: bolsofirme_db
   - Usuário: bolsofirme_user
   - Senha: bolsofirme_pass
   - Porta: 5432
   - Volume persistente para os dados não se perderem ao reiniciar

2. Prisma Studio
   - Interface visual para o banco de dados
   - Porta: 5555

Me mostre também:
- O arquivo .env com as variáveis de ambiente (DATABASE_URL)
- O .env.example para o repositório (sem valores reais)
- Como rodar: `docker-compose up -d` e verificar que está funcionando
```

**Subtasks:**
- [ ] Criar `docker-compose.yml` na raiz do projeto
- [ ] Criar `.env` com `DATABASE_URL` apontando para o container
- [ ] Criar `.env.example` com as chaves mas sem valores (para commitar)
- [ ] Adicionar `.env` no `.gitignore` (nunca commitar secrets)
- [ ] Rodar `docker-compose up -d` e confirmar que PostgreSQL está de pé
- [ ] Confirmar que Prisma Studio abre em `http://localhost:5555`

---

## T0.4 — Schema do Banco com Prisma

**Status:** [ ] Pendente

**O que é:** Definir todas as tabelas do banco de dados usando Prisma. É como desenhar a planta da casa antes de construir — define o que vai ser guardado e como as peças se relacionam.

**Prompt para IA:**
```
No projeto BolsoFirme (Node.js + TypeScript + Prisma + PostgreSQL), preciso criar o schema inicial do Prisma com as seguintes entidades:

- User: id, email, name, passwordHash, createdAt, updatedAt
- Transaction: id, userId, amount (Decimal), type (INCOME/EXPENSE), categoryId, date, description, createdAt
- Category: id, userId, name, color, emoji, budgetPercent (opcional), isDefault, createdAt
- Goal: id, userId, name, targetAmount (Decimal), currentAmount (Decimal), deadline, imageUrl, term (SHORT/MEDIUM/LONG), createdAt
- Asset: id, userId, name, type (STOCK/FII/CDB/TREASURY/OTHER), quantity (Decimal), avgPrice (Decimal), createdAt

Relacionamentos:
- User tem muitas Transactions, Categories, Goals e Assets
- Transaction pertence a um Category

Me mostre:
1. O arquivo schema.prisma completo
2. Como rodar `npx prisma migrate dev --name init` para criar as tabelas
3. Como rodar `npx prisma generate` para gerar o client TypeScript
```

**Subtasks:**
- [ ] Instalar Prisma: `npm install prisma @prisma/client` em `apps/api`
- [ ] Rodar `npx prisma init` para criar o arquivo `schema.prisma`
- [ ] Escrever o schema com as 5 entidades (User, Transaction, Category, Goal, Asset)
- [ ] Rodar `npx prisma migrate dev --name init` para criar as tabelas no banco
- [ ] Rodar `npx prisma generate` para gerar o client TypeScript
- [ ] Abrir o Prisma Studio e confirmar que as tabelas aparecem vazias

---

## T0.5 — Autenticação JWT (Registro, Login, Refresh)

**Status:** [ ] Pendente

**O que é:** Criar os endpoints de autenticação. O usuário se registra, faz login, recebe um token JWT, e usa esse token para provar que está autenticado em todas as outras chamadas. Inclui refresh token para não precisar logar toda hora.

**Prompt para IA:**
```
No projeto BolsoFirme (Node.js + Express + TypeScript + Prisma + Zod), preciso implementar autenticação JWT completa com arquitetura DDD.

Preciso de:

1. Endpoints:
   - POST /auth/register — cria conta (name, email, password)
   - POST /auth/login — retorna accessToken (15min) + refreshToken (7 dias)
   - POST /auth/refresh — troca o refreshToken por novo accessToken
   - POST /auth/logout — invalida o refreshToken

2. Segurança:
   - Senha hasheada com bcrypt (salt rounds: 10)
   - AccessToken JWT válido por 15 minutos
   - RefreshToken armazenado no banco (tabela RefreshToken)
   - Middleware `authenticate` que valida o Bearer token em rotas protegidas

3. Validação com Zod:
   - Schema de registro: email válido, senha mínimo 8 chars
   - Erros claros em português

4. Organização DDD:
   - Domain: entidade User, regras de negócio
   - Application: use cases (RegisterUser, LoginUser)
   - Infrastructure: UserRepository com Prisma
   - Interface: controllers Express + rotas

Me mostre os arquivos e como estruturar as pastas.
```

**Subtasks:**
- [ ] Instalar dependências: `express`, `jsonwebtoken`, `bcryptjs`, `zod`, `cors`, `helmet`
- [ ] Criar estrutura DDD em `apps/api/src/`: `domain/`, `application/`, `infrastructure/`, `interface/`
- [ ] Adicionar tabela `RefreshToken` no schema Prisma e rodar nova migration
- [ ] Implementar use case `RegisterUser` (hash de senha + salvar no banco)
- [ ] Implementar use case `LoginUser` (validar senha + gerar tokens)
- [ ] Implementar endpoint `POST /auth/refresh`
- [ ] Criar middleware `authenticate` que valida o Bearer token
- [ ] Testar todos os endpoints com Postman/Insomnia ou `curl`
- [ ] Verificar que rota sem token retorna `401 Unauthorized`

---

## T0.6 — CI/CD Básico com GitHub Actions *(sintetizado)*

**Status:** [ ] Pendente

**O que é:** Configurar uma verificação automática que roda sempre que você faz push no GitHub. Se o código tiver erro de lint ou teste falhando, você sabe na hora antes de quebrar o projeto.

**Prompt para IA:**
```
No monorepo BolsoFirme (Turborepo + Node.js + React + TypeScript), preciso criar um workflow GitHub Actions que:

1. Roda em todo push e pull request para a branch main
2. Passos:
   - Checkout do código
   - Setup Node.js 20
   - Instalar dependências (npm ci)
   - Rodar lint em todos os packages (npm run lint)
   - Rodar build em todos os packages (npm run build)
   - Rodar testes (npm run test) quando existirem

Me mostre o arquivo `.github/workflows/ci.yml` completo e como ativar cache do Turborepo no GitHub Actions para builds mais rápidos.
```

**Subtasks:**
- [ ] Criar pasta `.github/workflows/` na raiz
- [ ] Criar arquivo `ci.yml` com os passos: checkout, setup-node, install, lint, build
- [ ] Adicionar cache do Turborepo (remote caching desabilitado por enquanto — apenas local)
- [ ] Fazer push para o GitHub e confirmar que o workflow aparece na aba Actions
- [ ] Verificar que o check fica verde ✅

---

## Checklist Final da Fase 0

Antes de avançar para a Fase 1, confirme:

- [ ] `docker-compose up -d` sobe PostgreSQL sem erro
- [ ] `npm run dev` (raiz) sobe a API na porta 3000
- [ ] `POST /auth/register` cria um usuário no banco
- [ ] `POST /auth/login` retorna accessToken e refreshToken
- [ ] Rota protegida com middleware retorna 401 sem token
- [ ] GitHub Actions roda e fica verde no push
- [ ] Nenhum secret está commitado (`.env` no `.gitignore`)

---

*Fase 0 concluída → abrir [task-fase-1-mvp.md](task-fase-1-mvp.md)*
