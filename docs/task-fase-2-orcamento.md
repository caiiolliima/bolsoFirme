# Fase 2 — Orçamento: Controle por Categorias

> **Estimativa:** 3–4 semanas | **Pré-requisito:** Fase 1 concluída | **Desbloquia:** Fase 3
>
> Esta fase dá ao usuário o poder de definir quanto pode gastar em cada área da vida. O app avisa quando está chegando no limite e mostra visualmente onde o dinheiro realmente vai.

---

## T2.1 — Backend: CRUD de Categorias com Percentuais

**Status:** [ ] Pendente

**O que é:** Criar os endpoints para gerenciar categorias. Cada categoria tem cor, emoji e um percentual do salário que o usuário decide destinar a ela. O backend também precisa criar as categorias padrão quando um usuário se registra.

**Prompt para IA:**
```
No BolsoFirme (Node.js + Express + TypeScript + Prisma + Zod), com arquitetura DDD, preciso implementar o CRUD de Categorias.

Endpoints (todos autenticados):
- GET    /categories              → listar categorias do usuário (padrão + personalizadas)
- POST   /categories              → criar categoria personalizada
- PATCH  /categories/:id          → editar nome, cor, emoji, budgetPercent
- DELETE /categories/:id          → deletar (apenas categorias personalizadas, não as padrão)

Campos da Category:
- name: string
- color: string (hex, ex: "#FF6B6B")
- emoji: string (ex: "🍔")
- budgetPercent: number (0-100, nullable — percentual do salário)
- isDefault: boolean (padrão = true → não pode deletar)

Categorias padrão a criar quando usuário se registra:
🏠 Moradia, 🍔 Alimentação, 🚗 Transporte, 🎮 Lazer, 💊 Saúde,
👕 Vestuário, 📚 Educação, 💰 Investimento, 💳 Dívidas, 📦 Outros

Regra de negócio:
- A soma dos budgetPercent de todas as categorias não pode ultrapassar 100%
- Se budgetPercent não definido → categoria não tem limite de orçamento

Me mostre use case, repository, controller e schemas Zod em packages/shared.
```

**Subtasks:**
- [ ] Criar schemas Zod para Category em `packages/shared`
- [ ] Criar `CategoryRepository` com Prisma
- [ ] Criar use case de seed de categorias padrão (chamado após RegisterUser)
- [ ] Implementar CRUD de categorias com validação de soma de percentuais
- [ ] Conectar o seed ao fluxo de registro (criar categorias padrão automaticamente)
- [ ] Testar: registrar novo usuário → listar categorias → ver as 10 padrão criadas

---

## T2.2 — Tela de Categorias e Orçamento

**Status:** [ ] Pendente

**O que é:** A tela onde o usuário vê e gerencia suas categorias, com a opção de definir quanto vai gastar em cada uma por mês. Visualmente clara, com cores e emojis.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind + TanStack Query), preciso criar a página de Categorias e Orçamento.

Layout:
1. Header: "Categorias e Orçamento" + botão "+ Nova Categoria"

2. Input de salário mensal no topo:
   - Campo: "Meu salário mensal: R$ ____"
   - Ao alterar: todos os valores em reais recalculam automaticamente
   - Salvar em localStorage (por enquanto, não precisa ir ao banco)

3. Lista de categorias:
   - Cada item: emoji + cor + nome + percentual + valor calculado (salário × percentual)
   - Ex: 🏠 Moradia — 30% — R$ 900,00 (de R$ 3.000,00)
   - Slider de percentual (0% a 60%) para ajustar em tempo real
   - Indicador visual: barra de progresso mostrando %  gasto do orçamento este mês vs limite

4. Barra de distribuição total no rodapé:
   - Mostra: X% distribuído, Y% livre
   - Fica vermelha se ultrapassar 100%

5. Modal "+ Nova Categoria":
   - Campos: nome, emoji (picker simples), cor (palette de 12 cores)
   - Salva via POST /categories

Me mostre os componentes completos com TypeScript.
```

**Subtasks:**
- [ ] Criar página `CategoriesPage` com input de salário no topo
- [ ] Criar lista de categorias com slider de percentual
- [ ] Implementar cálculo em tempo real (percentual → valor em R$)
- [ ] Criar barra de distribuição total com indicador de 100%
- [ ] Criar modal de nova categoria com emoji picker e paleta de cores
- [ ] Conectar slider ao `PATCH /categories/:id` (com debounce de 500ms)
- [ ] Salvar salário no localStorage e aplicar em todos os cálculos

---

## T2.3 — Divisão Automática do Salário por Categoria

**Status:** [ ] Pendente

**O que é:** Um assistente que sugere automaticamente como dividir o salário entre as categorias, com base em regras conhecidas de finanças pessoais. O usuário pode aceitar a sugestão ou ajustar manualmente.

**Prompt para IA:**
```
No BolsoFirme, preciso criar uma funcionalidade de divisão automática do salário por categoria.

Regra base: Regra 50/30/20
- 50% Necessidades: Moradia, Alimentação, Transporte, Saúde
- 30% Desejos: Lazer, Vestuário, Assinaturas
- 20% Futuro: Investimento, Metas/Sonhos, Dívidas

Backend:
- Endpoint: POST /categories/auto-distribute
- Body: { salary: number, strategy: "50-30-20" }
- Retorna: lista de categorias com o budgetPercent sugerido
- Salva os valores no banco para o usuário logado

Frontend:
- Botão "✨ Distribuir automaticamente" na página de categorias
- Modal explicando a regra 50/30/20 de forma simples
- Preview das sugestões antes de confirmar
- Botão "Aplicar" que salva, botão "Cancelar" que descarta

Me mostre backend e frontend com TypeScript.
```

**Subtasks:**
- [ ] Criar endpoint `POST /categories/auto-distribute` no backend
- [ ] Implementar lógica da Regra 50/30/20 (mapear categorias por grupo)
- [ ] Criar modal no frontend explicando o método em português simples
- [ ] Mostrar preview dos percentuais sugeridos antes de confirmar
- [ ] Testar que ao aplicar, os sliders atualizam os valores calculados

---

## T2.4 — Alertas de Limite por Categoria

**Status:** [ ] Pendente

**O que é:** O sistema avisa o usuário quando está se aproximando (80%) ou ultrapassou (100%) o limite de uma categoria. Os alertas aparecem no dashboard e podem aparecer como notificação visual.

**Prompt para IA:**
```
No BolsoFirme, preciso implementar alertas de limite de orçamento por categoria.

Backend:
- Endpoint: GET /categories/alerts?month=YYYY-MM
- Para cada categoria com budgetPercent definido:
  → Calcular: orçamento = salary × budgetPercent / 100
  → Calcular: gasto = soma das transações daquela categoria no mês
  → Retornar: { categoryId, name, emoji, color, budget, spent, percentUsed, status }
  → status: "OK" | "WARNING" (>80%) | "EXCEEDED" (>100%)

Frontend:
1. No Dashboard: seção "Alertas" mostrando categorias em WARNING e EXCEEDED
   - WARNING: ícone amarelo ⚠️ + "Você usou 85% do orçamento de Lazer"
   - EXCEEDED: ícone vermelho 🔴 + "Você ultrapassou o orçamento de Alimentação em R$ 150"

2. Na lista de categorias: barra de progresso colorida
   - Verde: < 70%, Amarela: 70-100%, Vermelha: > 100%

3. No header do app: badge vermelho com o número de categorias estouradas

Me mostre backend e frontend completos com TypeScript.
```

**Subtasks:**
- [ ] Criar endpoint `GET /categories/alerts` com lógica de status
- [ ] Criar hook `useCategoryAlerts(month)` com TanStack Query
- [ ] Adicionar seção de alertas no Dashboard
- [ ] Atualizar barras de progresso na página de Categorias com cores dinâmicas
- [ ] Adicionar badge no header com o número de alertas ativos
- [ ] Confirmar que ao lançar uma transação que estoura o limite, o alerta aparece

---

## Checklist Final da Fase 2

Antes de avançar para a Fase 3, confirme:

- [ ] Categorias padrão são criadas automaticamente ao registrar
- [ ] É possível criar uma categoria personalizada com cor e emoji
- [ ] Slider de percentual calcula o valor em R$ em tempo real
- [ ] Distribuição automática 50/30/20 funciona corretamente
- [ ] Alerta aparece quando categoria ultrapassa 80% do limite
- [ ] Badge no header mostra número de categorias estouradas

---

*Fase 2 concluída → abrir [task-fase-3-metas.md](task-fase-3-metas.md)*
