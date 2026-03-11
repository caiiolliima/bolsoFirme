# Fase 5 — Multiusuário: Casal e Família

> **Estimativa:** 3–4 semanas | **Pré-requisito:** Fase 4 concluída | **Desbloquia:** Fase 6
>
> Esta fase permite que casais e famílias gerenciem as finanças juntos. Um membro cria o grupo, convida os outros, e todos visualizam um dashboard compartilhado. Recurso exclusivo da versão Premium.

---

## T5.1 — Backend: Grupos Familiares e Convites

**Status:** [ ] Pendente

**O que é:** Criar a estrutura de grupos no banco de dados e os endpoints para criar grupos, convidar membros por email e aceitar convites.

**Prompt para IA:**
```
No BolsoFirme (Node.js + Express + TypeScript + Prisma + Zod), com arquitetura DDD, preciso implementar grupos familiares com sistema de convites.

Novos modelos no Prisma:
- Group: id, name, createdBy (userId), createdAt
- GroupMember: id, groupId, userId, role ("ADMIN" | "MEMBER"), joinedAt
- GroupInvite: id, groupId, email, token (UUID único), status ("PENDING" | "ACCEPTED" | "EXPIRED"), expiresAt, createdAt

Endpoints:
- POST /groups                    → criar grupo (cria GroupMember com role ADMIN)
- GET  /groups                    → listar grupos do usuário logado
- GET  /groups/:id                → detalhes do grupo + membros
- POST /groups/:id/invites        → convidar por email (gera token + envia email)
- GET  /invites/:token            → verificar convite (retorna dados do grupo)
- POST /invites/:token/accept     → aceitar convite (cria GroupMember)
- DELETE /groups/:id/members/:userId → remover membro (apenas ADMIN)

Regras:
- Usuário só pode estar em 1 grupo por vez
- Convite expira em 7 dias
- Não pode convidar alguém que já está em um grupo

Email de convite (básico):
- Usar Nodemailer com SMTP (configurável via .env)
- Template simples: "Você foi convidado para o grupo [nome] no BolsoFirme. Clique aqui para aceitar."

Me mostre use case, repository, controller e schemas Zod.
```

**Subtasks:**
- [ ] Criar tabelas `Group`, `GroupMember`, `GroupInvite` no schema Prisma e rodar migration
- [ ] Instalar `nodemailer` e configurar SMTP no `.env`
- [ ] Criar `GroupRepository` e `GroupInviteRepository` com Prisma
- [ ] Implementar use case `CreateGroup` com membro admin automático
- [ ] Implementar use case `InviteMember` com envio de email
- [ ] Implementar use case `AcceptInvite` com validação de expiração
- [ ] Testar o fluxo completo: criar grupo → convidar email → aceitar convite → ver membro no grupo

---

## T5.2 — Sistema de Permissões (Admin/Membro)

**Status:** [ ] Pendente

**O que é:** Definir o que cada tipo de usuário pode fazer dentro de um grupo. O Admin vê tudo e gerencia o grupo; o Membro vê apenas suas próprias transações no contexto do grupo.

**Prompt para IA:**
```
No BolsoFirme, preciso implementar o sistema de permissões para grupos.

Regras de permissão:

ADMIN do grupo:
- Ver todas as transações de todos os membros no dashboard compartilhado
- Definir orçamentos compartilhados por categoria
- Remover membros
- Editar nome do grupo
- Ver relatório de gastos por membro

MEMBRO do grupo:
- Ver apenas as próprias transações
- Ver o dashboard compartilhado (totais do grupo, mas sem ver o individual dos outros)
- Ver orçamentos compartilhados (mas não editar)

Implementação:

1. Middleware `requireGroupRole(role)`:
   - Verificar se usuário está no grupo e tem a role necessária
   - Retornar 403 Forbidden se não tiver permissão

2. Contexto de grupo nas transações:
   - Adicionar campo opcional `groupId` nas transações
   - Transação com groupId → aparece no dashboard compartilhado
   - Transação sem groupId → apenas pessoal

3. Endpoint GET /groups/:id/dashboard → agregado de todos os membros (apenas ADMIN)

Me mostre middleware, modificações nas rotas e no schema Prisma.
```

**Subtasks:**
- [ ] Adicionar campo opcional `groupId` na tabela Transaction e rodar migration
- [ ] Criar middleware `requireGroupRole` para verificar permissões
- [ ] Criar endpoint `GET /groups/:id/dashboard` (apenas ADMIN)
- [ ] Atualizar formulário de transação no frontend para associar ao grupo (checkbox opcional)
- [ ] Testar que MEMBRO não consegue acessar o dashboard completo do grupo

---

## T5.3 — Dashboard Compartilhado

**Status:** [ ] Pendente

**O que é:** Uma tela especial que o Admin do grupo vê, com os gastos consolidados de todos os membros da família, separados por pessoa e por categoria.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind + Recharts + TanStack Query), preciso criar o Dashboard Compartilhado do grupo.

Página /groups/:id/dashboard (apenas ADMIN):

1. Header: "Família [nome do grupo]" + lista de avatares dos membros + mês selecionado

2. Cards de resumo do grupo:
   - Total de entradas (soma de todos)
   - Total de saídas (soma de todos)
   - Saldo do grupo

3. Gráfico de barras agrupadas (Recharts BarChart):
   - Eixo X: categorias
   - Barras: uma barra por membro (cor diferente por pessoa)
   - Mostra quanto cada um gastou em cada categoria

4. Lista "Quem gastou mais este mês" (ranking dos membros com total de gastos)

5. Seção "Últimas transações do grupo":
   - Lista as transações de todos, com o nome de quem lançou
   - Filtro por membro

Me mostre os componentes completos com TypeScript.
```

**Subtasks:**
- [ ] Criar página `GroupDashboardPage`
- [ ] Criar componente de gráfico de barras agrupadas por membro
- [ ] Criar ranking de gastos por membro
- [ ] Criar lista de transações do grupo com filtro por membro
- [ ] Adicionar link "Ver grupo" na sidebar quando usuário pertencer a um grupo

---

## T5.4 — Orçamentos por Grupo

**Status:** [ ] Pendente

**O que é:** O Admin define um orçamento compartilhado para cada categoria que vale para o grupo todo. Os alertas funcionam com os gastos somados de todos os membros.

**Prompt para IA:**
```
No BolsoFirme, preciso implementar orçamentos compartilhados por grupo.

Backend:
- Novo modelo: GroupBudget: id, groupId, categoryId, budgetAmount, month (YYYY-MM)
- Endpoint POST /groups/:id/budgets → definir orçamento de uma categoria para o grupo no mês
- Endpoint GET /groups/:id/budgets?month=YYYY-MM → listar orçamentos + gasto atual de cada um
- Lógica de alerta: igual ao individual (WARNING em 80%, EXCEEDED em 100%)

Frontend:
- Aba "Orçamento" na página do grupo (apenas ADMIN pode editar)
- Tabela: categoria + orçamento definido + gasto atual (soma do grupo) + status (OK/⚠️/🔴)
- Botão "Definir orçamento" por categoria

Me mostre backend e frontend com TypeScript.
```

**Subtasks:**
- [ ] Criar tabela `GroupBudget` no schema Prisma e rodar migration
- [ ] Criar endpoints de orçamento por grupo
- [ ] Criar aba "Orçamento" na página do grupo
- [ ] Reutilizar lógica de alertas da Fase 2 mas aplicada ao contexto do grupo
- [ ] Confirmar que alerta aparece quando o grupo inteiro ultrapassa o orçamento

---

## Checklist Final da Fase 5

Antes de avançar para a Fase 6, confirme:

- [ ] É possível criar um grupo e convidar por email
- [ ] Convite chega por email e pode ser aceito via link
- [ ] Admin vê o dashboard completo com gastos de todos
- [ ] Membro vê apenas suas próprias transações
- [ ] Orçamento compartilhado gera alertas para o grupo

---

*Fase 5 concluída → abrir [task-fase-6-premium.md](task-fase-6-premium.md)*
