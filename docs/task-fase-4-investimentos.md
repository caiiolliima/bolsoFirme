# Fase 4 — Investimentos: Carteira e Patrimônio

> **Estimativa:** 3–4 semanas | **Pré-requisito:** Fase 3 concluída | **Desbloquia:** Fase 5
>
> Esta fase dá ao usuário uma visão consolidada de tudo que ele tem investido — ações, FIIs, renda fixa — e calcula rentabilidade automaticamente. Sem integração com corretora: o usuário informa os dados manualmente.

---

## T4.1 — Backend: CRUD de Ativos

**Status:** [ ] Pendente

**O que é:** Criar os endpoints para gerenciar os ativos da carteira de investimentos. O usuário informa o que comprou, quando e por qual preço — o app calcula o preço médio e a rentabilidade.

**Prompt para IA:**
```
No BolsoFirme (Node.js + Express + TypeScript + Prisma + Zod), com arquitetura DDD, preciso implementar o CRUD de Ativos (Assets).

Endpoints (todos autenticados):
- GET    /assets           → listar ativos do usuário (com totais calculados)
- POST   /assets           → adicionar ativo
- PATCH  /assets/:id       → editar ativo
- DELETE /assets/:id       → deletar ativo
- POST   /assets/:id/purchases → registrar nova compra (atualiza preço médio)
- GET    /assets/summary   → resumo da carteira (alocação por tipo, patrimônio total)

Campos do Asset:
- name: string (ex: "ITSA4", "HGLG11", "CDB Nubank")
- ticker: string (opcional, ex: "ITSA4")
- type: "STOCK" | "FII" | "CDB" | "TREASURY" | "CRYPTO" | "OTHER"
- quantity: Decimal (total de cotas/unidades)
- avgPrice: Decimal (preço médio de compra, atualizado a cada nova compra)
- currentPrice: Decimal (nullable — informado manualmente pelo usuário)

Cálculo de preço médio ponderado ao registrar nova compra:
  novoAvgPrice = (quantity × avgPrice + novaQtd × novoPreco) / (quantity + novaQtd)

Retornar junto com cada ativo:
- totalInvested: quantity × avgPrice
- currentValue: quantity × currentPrice (se currentPrice informado)
- profitLoss: currentValue - totalInvested
- profitLossPercent: (profitLoss / totalInvested) × 100

Me mostre use case, repository, controller e schemas Zod.
```

**Subtasks:**
- [ ] Criar schemas Zod para Asset e Purchase em `packages/shared`
- [ ] Criar tabela `AssetPurchase` no schema Prisma e rodar migration
- [ ] Criar `AssetRepository` com Prisma
- [ ] Implementar cálculo de preço médio ponderado no use case `AddPurchase`
- [ ] Implementar endpoint `GET /assets/summary` com totais por tipo
- [ ] Testar: adicionar ativo, registrar 2 compras com preços diferentes, verificar preço médio

---

## T4.2 — Tela da Carteira de Investimentos

**Status:** [ ] Pendente

**O que é:** A página que mostra todos os investimentos do usuário organizados por tipo, com o valor atual, preço médio e rentabilidade de cada um.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind + TanStack Query), preciso criar a página de Carteira de Investimentos.

Página /investments:
1. Cards de resumo no topo:
   - Total investido (sum de quantity × avgPrice de todos os ativos)
   - Valor atual (sum de quantity × currentPrice quando disponível)
   - Rentabilidade total (R$ e %)

2. Lista de ativos agrupados por tipo:
   - Títulos de grupo: "Ações", "FIIs", "Renda Fixa", "Outros"
   - Cada ativo: nome/ticker + quantidade + preço médio + preço atual + rentabilidade
   - Rentabilidade: verde com ↑ se positiva, vermelha com ↓ se negativa
   - Botão de editar preço atual (campo inline editável)

3. Botão "+ Adicionar ativo" (abre modal)

Modal "+ Adicionar Ativo":
- Campos: nome, ticker (opcional), tipo (dropdown), quantidade, preço médio
- Ou: adicionar como "nova compra" (informa quantidade + preço → calcula médio)

Me mostre os componentes completos com TypeScript.
```

**Subtasks:**
- [ ] Criar página `InvestmentsPage` com cards de resumo
- [ ] Criar componente de lista agrupada por tipo de ativo
- [ ] Implementar campo de preço atual editável inline (com `PATCH /assets/:id`)
- [ ] Criar modal "+ Adicionar Ativo"
- [ ] Criar hook `useAssets()` e `useAssetsSummary()` com TanStack Query
- [ ] Confirmar que rentabilidade atualiza ao editar o preço atual

---

## T4.3 — Cálculo de Preço Médio e Rentabilidade

**Status:** [ ] Pendente

**O que é:** Histórico de compras de cada ativo e como o preço médio foi formado ao longo do tempo. O usuário entende de onde vem cada número.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind + Recharts), preciso criar a tela de detalhe de um ativo.

Página /investments/:id:
1. Header: nome do ativo + ticker + badge do tipo
2. Métricas principais (cards):
   - Quantidade total
   - Preço médio de compra
   - Preço atual (editável)
   - Rentabilidade total (R$ e %)

3. Tabela de histórico de compras:
   - Colunas: data, quantidade, preço unitário, valor total, preço médio após
   - Linha de total no rodapé

4. Gráfico de linha (Recharts) mostrando evolução do preço médio ao longo das compras

5. Botão "+ Nova Compra" (abre modal para registrar nova compra e recalcular o médio)

Backend:
- Endpoint: GET /assets/:id/history → retorna lista de compras com o preço médio após cada compra

Me mostre backend e frontend com TypeScript e Recharts.
```

**Subtasks:**
- [ ] Criar endpoint `GET /assets/:id/history`
- [ ] Criar página de detalhe `/investments/:id`
- [ ] Criar tabela de histórico de compras
- [ ] Criar gráfico de evolução do preço médio (Recharts LineChart)
- [ ] Criar modal "+ Nova Compra" com cálculo do novo preço médio em tempo real (preview)

---

## T4.4 — Gráfico de Alocação + Patrimônio Total

**Status:** [ ] Pendente

**O que é:** Uma visão consolidada que junta dinheiro disponível (saldo em conta) + dinheiro investido = patrimônio total. Também mostra como está distribuído o patrimônio entre os tipos de ativo.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind + Recharts), preciso criar o gráfico de alocação da carteira e a visão de patrimônio total.

1. Gráfico de rosca - Alocação por tipo (Recharts PieChart):
   - Fatias: Ações, FIIs, Renda Fixa, Criptomoedas, Outros
   - Mostrar: % e valor em R$ de cada tipo
   - Cores diferentes por tipo (paleta consistente)
   - Tooltip detalhado ao passar o mouse

2. Card de Patrimônio Total:
   - Dinheiro disponível: calculado como total de entradas - saídas de todos os tempos
   - Total investido: soma de todos os ativos
   - Patrimônio total: disponível + investido
   - Mini gráfico de barras: proporção disponível vs investido

3. Integrar na Dashboard principal:
   - Adicionar mini-card "Patrimônio" na dashboard com link para /investments
   - Mostrar patrimônio total + variação do mês

Me mostre os componentes completos com TypeScript e Recharts.
```

**Subtasks:**
- [ ] Criar componente `AllocationChart` com PieChart (Recharts)
- [ ] Criar card de Patrimônio Total com breakdown disponível vs investido
- [ ] Integrar mini-card de patrimônio no Dashboard principal
- [ ] Confirmar que gráfico de alocação atualiza ao adicionar ou editar ativos

---

## Checklist Final da Fase 4

Antes de avançar para a Fase 5, confirme:

- [ ] É possível adicionar um ativo com quantidade e preço
- [ ] Registrar segunda compra atualiza o preço médio corretamente
- [ ] Rentabilidade calcula corretamente (verde/vermelho)
- [ ] Gráfico de alocação mostra % por tipo de ativo
- [ ] Dashboard principal mostra o patrimônio total

---

*Fase 4 concluída → abrir [task-fase-5-multiusuario.md](task-fase-5-multiusuario.md)*
