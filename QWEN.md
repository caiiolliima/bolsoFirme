# 🤖 Contexto do Projeto: Bolso Firme

Este documento fornece ao Qwen Code o contexto essencial para operar de forma alinhada com a engenharia de produção do projeto **Bolso Firme**.

## 🎯 Visão de Engenharia
- Construir com **rigor de produção desde o dia 1**, evitando `vibe coding`.
- LLMs são **copilotos controlados**, nunca geradores cegos. Cada feature deve entrar com teste, validação de schema, observabilidade e fallback determinístico.

## 🏗️ Stack Técnica
- **Frontend:** Next.js 14+ (App Router), React, TypeScript.
- **Backend:** NestJS 10+, TypeScript.
- **Banco:** PostgreSQL 16 com Prisma ORM.
- **Validação:** Zod (pacote compartilhado).
- **Infra Local:** Docker Compose, Turborepo.
- **Arquitetura:** Monolito Modular no backend, com separação em camadas DDD (`domain`, `application`, `infrastructure`, `interface`).

## 🔐 Segurança & Compliance
- Autenticação: JWT + Refresh Token (HttpOnly, SameSite=Strict).
- Autorização: RBAC via decoradores NestJS (`@Roles`).
- Dados Financeiros: Criptografia em repouso (AES-256), máscara em logs.
- Segredos: `.env` local → AWS Secrets Manager/Vault em produção.
- Validação: `Zod` com `ValidationPipe` configurado para `whitelist: true` e `forbidNonWhitelisted: true`.

## 🤖 Integração de IA/LLMs
- **No Produto:** Auto-categorização, Insights Inteligentes e Projeção de Metas, todos com prompts versionados e fallback obrigatório.
- **No Desenvolvimento:** Prompts críticos versionados no Git (`/packages/prompts/`), `temperature ≤ 0.3` para finanças, Chain-of-Verification (Gerar → Validar → Corrigir → Entregar) e fallback obrigatório.

## 📦 Estrutura do Monorepo
```
├── apps/
│   ├── web/ # Next.js (Frontend)
│   └── api/ # NestJS (Backend)
├── packages/
│   ├── shared/ # Zod schemas, types, utils
│   ├── prompts/ # Versionamento de prompts
│   └── config/ # ESLint, Prettier, TSConfig, Jest/Vitest
└── turbo.json
```

## 🛡️ Guardrails Anti-`Vibe Coding`
1. Zero merge sem `test → lint → schema validation → code review manual`.
2. Prompts críticos devem estar versionados no Git.
3. Métricas obrigatórias: `tokens_usados`, `custo_usd`, `latencia_ms`, `taxa_validacao`.
4. Fallback determinístico é obrigatório se o LLM falhar.
5. Explicabilidade obrigatória: se não consegue explicar uma linha gerada, não mescle.
6. CI/CD não negociável: `lint → test:coverage(≥70%) → build → scan → deploy`.

## 📊 Métricas & Observabilidade
- **Backend:** Latência p95, error rate 5xx, throughput req/s, DB pool usage.
- **IA/LLM:** Tokens por feature, custo USD/mês, taxa de validação schema, fallback rate.
- **Qualidade:** Coverage %, PR review time, CI fail rate, dependency vulns.