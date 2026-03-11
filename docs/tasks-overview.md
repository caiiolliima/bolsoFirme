# BolsoFirme — Índice de Tasks

> **Como usar:** abra o arquivo da fase atual, copie o prompt da task que vai trabalhar, cole no Copilot/Claude/ChatGPT e siga as subtasks em ordem. Marque `[x]` quando concluir cada item.
>
> **Regra de ouro:** nunca abra mais de uma task ao mesmo tempo. Termine uma, depois começa a próxima.

---

## Progresso Geral

| Fase | Arquivo | Estimativa | Status |
|---|---|---|---|
| Fase 0 — Setup | [task-fase-0-setup.md](task-fase-0-setup.md) | 2–3 semanas | ⏳ Próximo passo |
| Fase 1 — MVP | [task-fase-1-mvp.md](task-fase-1-mvp.md) | 4–6 semanas | 🔒 Aguardando Fase 0 |
| Fase 2 — Orçamento | [task-fase-2-orcamento.md](task-fase-2-orcamento.md) | 3–4 semanas | 🔒 Aguardando Fase 1 |
| Fase 3 — Metas | [task-fase-3-metas.md](task-fase-3-metas.md) | 3–4 semanas | 🔒 Aguardando Fase 2 |
| Fase 4 — Investimentos | [task-fase-4-investimentos.md](task-fase-4-investimentos.md) | 3–4 semanas | 🔒 Aguardando Fase 3 |
| Fase 5 — Multiusuário | [task-fase-5-multiusuario.md](task-fase-5-multiusuario.md) | 3–4 semanas | 🔒 Futuro |
| Fase 6 — Premium | [task-fase-6-premium.md](task-fase-6-premium.md) | 2–3 semanas | 🔒 Futuro |
| Fase 7 — Mobile | [task-fase-7-mobile.md](task-fase-7-mobile.md) | 6–8 semanas | 🔒 Futuro |

---

## Resumo das Tasks por Fase

### Fase 0 — Setup (Fundação)
- T0.1 — Monorepo Turborepo + estrutura de pastas
- T0.2 — TypeScript, ESLint e Prettier *(sintetizado — 1 task)*
- T0.3 — Docker Compose (PostgreSQL + Prisma Studio)
- T0.4 — Schema do banco com Prisma
- T0.5 — Autenticação JWT (registro, login, refresh + middleware)
- T0.6 — CI/CD básico com GitHub Actions *(sintetizado — 1 task)*

### Fase 1 — MVP (Produto funcionando)
- T1.1 — Setup Frontend (React + Vite + Tailwind + Router + TanStack Query) *(sintetizado)*
- T1.2 — Layout base (Sidebar, Header, rotas protegidas)
- T1.3 — Telas de Login e Registro
- T1.4 — Backend: CRUD de Transações
- T1.5 — Formulário de lançamento de transação
- T1.6 — Lista de transações com filtros
- T1.7 — Importação OFX/CSV
- T1.8 — Dashboard mensal (gráfico de rosca + resumo financeiro)

### Fase 2 — Orçamento
- T2.1 — Backend: CRUD de Categorias com percentuais
- T2.2 — Tela de Categorias e Orçamento
- T2.3 — Divisão automática do salário por categoria
- T2.4 — Alertas de limite por categoria

### Fase 3 — Metas e Sonhos
- T3.1 — Backend: CRUD de Metas
- T3.2 — Tela de Metas (criar, listar, detalhar)
- T3.3 — Aportes e projeção de prazo
- T3.4 — Barra de progresso e celebração ao completar

### Fase 4 — Investimentos
- T4.1 — Backend: CRUD de Ativos
- T4.2 — Tela da Carteira de Investimentos
- T4.3 — Cálculo de preço médio e rentabilidade
- T4.4 — Gráfico de alocação + patrimônio total

### Fase 5 — Multiusuário
- T5.1 — Backend: Grupos familiares e convites
- T5.2 — Sistema de permissões (admin/membro)
- T5.3 — Dashboard compartilhado
- T5.4 — Orçamentos por grupo

### Fase 6 — Premium
- T6.1 — Integração Stripe (checkout + webhook)
- T6.2 — Feature flags (freemium gates)
- T6.3 — Onboarding e telas de planos

### Fase 7 — Mobile
- T7.1 — Setup React Native + Expo
- T7.2 — Compartilhamento de código (packages/shared)
- T7.3 — Telas principais no mobile
- T7.4 — Build e publicação nas lojas

---

*Documento gerado em Março de 2026 — BolsoFirme v3.0*
