# Fase 3 — Metas e Sonhos: Objetivos Financeiros

> **Estimativa:** 3–4 semanas | **Pré-requisito:** Fase 2 concluída | **Desbloquia:** Fase 4
>
> Esta fase torna os sonhos financeiros do usuário visíveis e mensuráveis. Uma moto, uma viagem, a entrada de um apartamento — o usuário vê o progresso em tempo real e recebe o prazo estimado para alcançar.

---

## T3.1 — Backend: CRUD de Metas

**Status:** [ ] Pendente

**O que é:** Criar os endpoints para gerenciar metas financeiras. Cada meta tem um valor alvo, um prazo estimado e um saldo atual que cresce conforme o usuário faz aportes.

**Prompt para IA:**
```
No BolsoFirme (Node.js + Express + TypeScript + Prisma + Zod), com arquitetura DDD, preciso implementar o CRUD de Metas (Goals).

Endpoints (todos autenticados):
- GET    /goals           → listar todas as metas do usuário
- GET    /goals/:id       → buscar uma meta
- POST   /goals           → criar meta
- PATCH  /goals/:id       → editar meta
- DELETE /goals/:id       → deletar meta
- POST   /goals/:id/contributions → registrar um aporte manual

Campos da Goal:
- name: string (ex: "Moto Honda CB500")
- targetAmount: Decimal (ex: 30000)
- currentAmount: Decimal (começa em 0, cresce com aportes)
- deadline: Date (nullable)
- imageUrl: string (nullable — URL de imagem da meta)
- term: "SHORT" | "MEDIUM" | "LONG" (calculado: <1 ano | 1-3 anos | >3 anos)
- monthlyContribution: Decimal (nullable — aporte mensal automático)

Cálculo de projeção (retornar junto com cada meta):
- percentComplete: (currentAmount / targetAmount) × 100
- monthsRemaining: ((targetAmount - currentAmount) / monthlyContribution) se monthlyContribution > 0
- estimatedCompletion: data estimada com base no ritmo atual

Me mostre use case, repository, controller e schemas Zod em packages/shared.
```

**Subtasks:**
- [ ] Criar schemas Zod para Goal e Contribution em `packages/shared`
- [ ] Criar tabela `GoalContribution` no schema Prisma e rodar migration
- [ ] Criar `GoalRepository` com Prisma
- [ ] Implementar use cases: `CreateGoal`, `UpdateGoal`, `DeleteGoal`, `AddContribution`
- [ ] Implementar cálculo de projeção no use case de listagem
- [ ] Criar controller e rotas
- [ ] Testar: criar meta, adicionar aportes e verificar que percentComplete atualiza

---

## T3.2 — Tela de Metas (Criar, Listar, Detalhar)

**Status:** [ ] Pendente

**O que é:** A página onde o usuário vê todos os seus sonhos na forma de cards visuais, com foto, barra de progresso e prazo estimado. Também pode criar novas metas com um formulário.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind + TanStack Query), preciso criar a página de Metas e Sonhos.

Página principal (/goals):
1. Header: "Metas e Sonhos" + botão "+ Nova Meta"
2. Grid de cards (2 ou 3 colunas):
   - Card de Meta: imagem de fundo (se tiver) + gradiente escuro
   - Nome da meta em destaque
   - Valor atual / Valor total (ex: "R$ 8.500 / R$ 30.000")
   - Barra de progresso colorida (cor muda conforme progresso: cinza → azul → verde)
   - Prazo estimado: "Concluída em ~14 meses" ou "Prazo: Jul/2027"
   - Tag de prazo: curto / médio / longo (cor diferente)
   - Botão "Aportar" (abre modal rápido)

Modal "+ Nova Meta":
- Campos: nome, valor total, prazo (data, opcional), foto (URL, opcional)
- Preview da foto ao digitar a URL
- Aporte mensal sugerido (calculado: valor_total / meses_até_prazo)

Me mostre os componentes completos com TypeScript.
```

**Subtasks:**
- [ ] Criar página `GoalsPage` com grid de cards
- [ ] Criar componente `GoalCard` com imagem de fundo + gradiente
- [ ] Criar componente de barra de progresso colorida
- [ ] Criar modal "+ Nova Meta" com preview de imagem
- [ ] Criar hook `useGoals()` com TanStack Query
- [ ] Confirmar que cards aparecem na ordem: metas mais próximas de completar primeiro

---

## T3.3 — Aportes e Projeção de Prazo

**Status:** [ ] Pendente

**O que é:** O usuário define quanto vai depositar por mês em cada meta, e o app calcula automaticamente quando vai atingir o objetivo. Aportes manuais também são registrados com histórico.

**Prompt para IA:**
```
No BolsoFirme, preciso criar a funcionalidade de aportes em metas e o cálculo de projeção.

Modal de Aporte (aberto pelo botão "Aportar" no card da meta):
- Campo: valor do aporte (R$)
- Opção: "Definir aporte mensal recorrente: R$ ____"
- Histórico dos últimos 5 aportes (data + valor)
- Após salvar: currentAmount aumenta, barra de progresso anima

Tela de detalhe da Meta (/goals/:id):
- Todas as informações da meta
- Gráfico de linha (Recharts) mostrando evolução do saldo ao longo do tempo
- Projeção futura pontilhada no gráfico (linha tracejada)
- Campo para editar o aporte mensal
- Tabela com histórico completo de aportes

Backend — projeção:
- Simular mês a mês, somando monthlyContribution ao currentAmount
- Retornar array de pontos: [{ date, projectedAmount }] até atingir targetAmount
- Limitar a projeção a 10 anos

Me mostre backend e frontend com TypeScript e Recharts.
```

**Subtasks:**
- [ ] Criar endpoint `GET /goals/:id/projection` que retorna pontos para o gráfico
- [ ] Criar modal de aporte com histórico e opção de aporte recorrente
- [ ] Criar página de detalhe `/goals/:id`
- [ ] Implementar gráfico de linha com projeção futura pontilhada (Recharts)
- [ ] Animar a barra de progresso após registrar aporte (CSS transition)
- [ ] Confirmar que projeção recalcula ao alterar o aporte mensal

---

## T3.4 — Barra de Progresso e Celebração ao Completar

**Status:** [ ] Pendente

**O que é:** Quando o usuário atinge 100% de uma meta, o app celebra! Uma animação visual recompensa o esforço e marca o grande momento.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind), preciso implementar a celebração ao completar uma meta.

Comportamento quando currentAmount >= targetAmount:
1. Card da meta muda para aparência especial:
   - Badge "✅ Concluída!" em verde
   - Borda verde brilhante (CSS glow)
   - Texto riscado ou estilo diferente para indicar conclusão

2. Animação de celebração (disparada uma única vez quando atingir 100%):
   - Confetes caindo pela tela por 3 segundos (usar biblioteca canvas-confetti)
   - Toast especial: "🎉 Parabéns! Você atingiu sua meta: [nome da meta]!"

3. No backend:
   - Campo isCompleted: boolean na tabela Goal
   - Campo completedAt: DateTime
   - Quando addContribution faz currentAmount >= targetAmount → marcar como concluída

4. Filtro na tela: "Ativas" / "Concluídas" (tab ou toggle)
   - Metas concluídas aparecem em uma seção separada no final

Me mostre backend e frontend completos.
```

**Subtasks:**
- [ ] Adicionar campos `isCompleted` e `completedAt` no schema Prisma e rodar migration
- [ ] Atualizar use case `AddContribution` para marcar meta como concluída automaticamente
- [ ] Instalar `canvas-confetti` no frontend
- [ ] Detectar quando meta passa de <100% para >=100% para disparar a celebração
- [ ] Criar estilo especial para cards de metas concluídas
- [ ] Adicionar abas "Ativas" / "Concluídas" na página de metas

---

## Checklist Final da Fase 3

Antes de avançar para a Fase 4, confirme:

- [ ] É possível criar uma meta com nome, valor e prazo
- [ ] Barra de progresso atualiza após registrar aporte
- [ ] Projeção calcula a data estimada corretamente
- [ ] Gráfico de linha mostra histórico + projeção futura
- [ ] Animação de celebração dispara ao atingir 100%
- [ ] Meta concluída aparece na aba "Concluídas"

---

*Fase 3 concluída → abrir [task-fase-4-investimentos.md](task-fase-4-investimentos.md)*
