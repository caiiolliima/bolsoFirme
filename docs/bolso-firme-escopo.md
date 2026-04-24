# 📘 ESCOPO TÉCNICO REESTRUTURADO: `Bolso Firme`

**Versão 4.0 — Engenharia de Produção + IA Controlada — Solo / Monorepo**

---

## 🎯 1. Visão & Objetivo de Engenharia

**Problema:** Pessoas perdem controle financeiro por falta de visibilidade, estrutura e motivação.  
**Solução:** Dashboard macro→micro, orçamento por categoria, metas visíveis, carteira consolidada.  
**Diferencial:** Clareza progressiva (zoom temporal), design motivacional, unificação de gastos + metas + investimentos.  
**Objetivo de Engenharia:** Construir com **rigor de produção desde o dia 1**. LLMs são copilotos controlados, nunca geradores cegos. Cada feature entra com teste, validação de schema, observabilidade e fallback determinístico. Zero `vibe coding`.

---

## 🏗️ 2. Stack & Arquitetura Técnica

|
Camada
|
Tecnologia
|
Justificativa
|
|

---

## |

## |

|
|
**
Frontend
**
|
`Next.js 14+`
(App Router) +
`React`

- `TypeScript`
  |
  SSR/SSG, roteamento file-based, ecossistema maduro, fácil deploy.
  |
  |
  **
  Backend
  **
  |
  `NestJS 10+`
- `TypeScript`
  |
  Arquitetura modular, DI nativa, pipes/guards, testável, escalável.
  |
  |
  **
  Banco
  **
  |
  `PostgreSQL 16`
- `Prisma ORM`
  |
  Transações, JSONB, índices, extensão
  `pgvector`
  (futuro IA), tipagem segura.
  |
  |
  **
  Validação
  **
  |
  `Zod`
  (shared package)
  |
  Contrato único front/back, validação runtime + TS inference.
  |
  |
  **
  Infra Local
  **
  |
  `Docker Compose`
- `Turborepo`
  |
  Ambiente reproduzível, cache inteligente, builds paralelos.
  |
  |
  **
  Infra Cloud
  **
  |
  AWS/Azure (Futuro)
  |
  Containers idênticos ao local, escalabilidade sob demanda.
  |

> 💡 **Decisão Arquitetural:** Iniciar como **Monolito Modular** no backend. Separação de serviços só ocorrerá quando métricas justificarem (ex: latência > 2s, deploy bloqueado, necessidade de escalonamento independente).

---

## 🔐 3. Segurança, Compliance & Shift-Left

|
Domínio
|
Implementação
|
|

---

## |

|
|
**
Autenticação
**
|
JWT + Refresh Token (HttpOnly, SameSite=Strict, rotação automática)
|
|
**
Autorização
**
|
RBAC via Decorators (
`@Roles('admin')`
), guards por rota
|
|
**
Dados Financeiros
**
|
Criptografia em repouso (AES-256), máscara em logs, exclusão LGPD garantida
|
|
**
Segredos
**
|
`.env`
local →
`AWS Secrets Manager`
/
`Vault`
em produção. Zero hardcode.
|
|
**
Validação
**
|
`Zod`

- `NestJS ValidationPipe`
  .
  `whitelist: true`
  ,
  `forbidNonWhitelisted: true`
  |
  |
  **
  Ameaças
  **
  |
  Threat Modeling (STRIDE) por módulo. Rate limiting, CORS restrito, sanitização de input
  |
  |
  **
  Auditoria
  **
  |
  Logs estruturados (JSON),
  `x-request-id`
  por fluxo, tabela
  `audit_log`
  imutável
  |

---

## 🤖 4. Integração de IA/LLMs (Produto + Desenvolvimento)

### 🔹 No Produto (Fase 3+)

|
Feature
|
Implementação Técnica
|
|

---

## |

|
|
**
Auto-categorização
**
|
Parser OFX/CSV → extrai descrição → LLM com prompt versionado → fallback para regra estática se
`confidence < threshold`
|
|
**
Insights Inteligentes
**
|
Agregação mensal → prompt de resumo hierárquico → JSON validado por Zod → exibição condicional
|
|
**
Projeção de Metas
**
|
Cálculo determinístico + simulação de cenários via LLM (temperature ≤ 0.2)
|

### 🔹 No Desenvolvimento (Anti-Vibe Coding)

|
Prática
|
Regra
|
|

---

## |

|
|
**
Prompt Registry
**
|
Prompts críticos versionados no Git (
`/packages/prompts/`
), nunca em variáveis soltas
|
|
**
Chain-of-Verification
**
|
Gerar → validar schema → corrigir → entregar. Se falhar, rota para fallback
|
|
**
Temperatura
**
|
≤ 0.3 para análise/finanças. Nunca > 0.5 em dados sensíveis
|
|
**
Observabilidade
**
|
Log estruturado:
`tokens_in`
,
`tokens_out`
,
`cost_usd`
,
`latency_ms`
,
`validation_status`
|
|
**
Fallback Obrigatório
**
|
Se LLM timeout/erro/output inválido → regra determinística ou modelo menor. Nunca bloqueia UX
|

---

## 📦 5. Estrutura do Monorepo & Camadas DDD

bolso-firme/ ├── apps/ │ ├── web/ # Next.js (Frontend) │ └── api/ # NestJS (Backend) ├── packages/ │ ├── shared/ # Zod schemas, types, utils, constants │ ├── prompts/ # Versionamento de prompts (v1.0, v1.1, etc.) │ └── config/ # ESLint, Prettier, TSConfig, Jest/Vitest ├── docker-compose.yml └── turbo.json

### Camadas Backend (NestJS)

| Camada            | Responsabilidade                                                  | Exemplo                                                  |
| ----------------- | ----------------------------------------------------------------- | -------------------------------------------------------- |
| `domain/`         | Regras puras, entidades, value objects, interfaces de repositório | `Transaction.value > 0`, `Budget.isWithinLimit()`        |
| `application/`    | Casos de uso, DTOs, orquestração de regras                        | `CreateTransactionUseCase`, `CalculateBudgetProjection`  |
| `infrastructure/` | DB (Prisma), parsers (OFX/CSV), LLM clients, email, filas         | `PrismaTransactionRepo`, `OpenAIProvider`, `BullMQQueue` |
| `interface/`      | Controllers, guards, pipes, OpenAPI/Swagger                       | `TransactionController`, `JwtAuthGuard`                  |

---

## 🗺️ 6. Roadmap Técnico (Fases Evolutivas)

| Fase   | Foco                   | Entregáveis Técnicos                                                | Critério de Aceite                                          |
| ------ | ---------------------- | ------------------------------------------------------------------- | ----------------------------------------------------------- |
| **0**  | Fundação & CI/CD       | Monorepo, Docker, Prisma, Auth JWT, Zod shared, GitHub Actions      | CI verde, coverage ≥ 70%, `.env.example` sem secrets        |
| **1**  | Transações & Dashboard | CRUD transações, parser CSV/OFX, TanStack Query, Recharts básico    | Endpoint validado, importação funcional, p95 < 1s           |
| **2**  | Orçamento & Alertas    | Categorias personalizadas, percentuais, regras DDD, notificações    | Alerta dispara em tempo real, cálculo preciso, testes ≥ 80% |
| **3**  | Metas & Investimentos  | Carteira manual, projeção visual, LLM auto-categorização (gated)    | Fallback ativo, validação Zod 100%, token cost logado       |
| **4**  | Premium & Pagamentos   | Stripe/Asaas, feature flags, gates freemium, relatórios exportáveis | Checkout idempotente, webhook retry, audit log              |
| **5**  | Multi-Usuário          | Grupos, RBAC, convites, orçamento compartilhado, audit trail        | Permissões isoladas, nenhum vazamento cross-tenant          |
| **6**  | Otimização & Scale     | Cache Redis, OpenTelemetry, rate limiting, prep K8s/AWS             | Latência < 500ms, 0 secrets no repo, métricas visíveis      |
| **7+** | Mobile & Open Finance  | React Native/Expo, certificação BCB, sync offline                   | Reuso ≥ 70%, compliance LGPD, fallback offline              |

> ⏱️ **Estimativa Realista:** MVP (Fases 0–2) em 8–10 semanas. Produto completo até Fase 6 em 5–6 meses. Mobile + Open Finance: +3–4 meses.

---

## 🛡️ 7. Guardrails Anti-`Vibe Coding`

1. **Zero merge sem validação:** `test → lint → schema validation → code review manual`
2. **Prompt versionado:** Prompts críticos no Git. Mudanças exigem PR + teste de regressão.
3. **Métrica desde o dia 1:** `tokens_usados`, `custo_usd`, `latencia_ms`, `taxa_validacao`. Sem métrica = sem produção.
4. **Fallback determinístico:** Se LLM falha, rota para regra estática ou modelo menor. Nunca trava UX.
5. **Explicabilidade obrigatória:** Se não consegue explicar uma linha gerada, não mescle. Peça explicação, estude, adapte.
6. **CI/CD não negociável:** `lint → test:coverage(≥70%) → build → scan → deploy`. Verde = mescla. Vermelho = bloqueia.

---

## 📊 8. Métricas & Observabilidade

| Tipo          | Métrica                                                                    | Ferramenta                          |
| ------------- | -------------------------------------------------------------------------- | ----------------------------------- |
| **Produto**   | Conversão free→premium, retenção D30, ativação dashboard                   | PostHog / Mixpanel                  |
| **Backend**   | Latência p95, error rate 5xx, throughput req/s, DB pool usage              | Pino + OpenTelemetry + Grafana      |
| **IA/LLM**    | Tokens por feature, custo USD/mês, taxa de validação schema, fallback rate | LangSmith / Custom Logger           |
| **Qualidade** | Coverage %, PR review time, CI fail rate, dependency vulns                 | GitHub Actions + SonarQube (futuro) |

---
