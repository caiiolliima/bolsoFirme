# Fase 1 — MVP: Produto Funcionando

> **Estimativa:** 4–6 semanas | **Pré-requisito:** Fase 0 concluída | **Desbloquia:** Fase 2
>
> Esta fase entrega o MVP real: o usuário consegue se registrar, lançar transações, importar extratos e ver um dashboard com gráfico. É o produto mínimo que já tem valor. Tudo versão gratuita.

---

## T1.1 — Setup Frontend *(sintetizado — React + Vite + Tailwind + Router + TanStack Query)*

**Status:** [ ] Pendente

**O que é:** Configurar toda a base do frontend de uma vez. São 5 ferramentas que trabalham juntas e se configuram de forma parecida, então faz sentido fazer tudo junto antes de escrever qualquer tela.

**Prompt para IA:**
```
Preciso configurar o frontend do BolsoFirme em apps/web dentro de um monorepo Turborepo.

Stack: React 18 + TypeScript + Vite + Tailwind CSS + React Router v6 + TanStack Query v5

Me mostre:
1. Como criar o app Vite em apps/web: `npm create vite@latest web -- --template react-ts`
2. Instalar e configurar Tailwind CSS (tailwind.config.js + index.css com @tailwind directives)
3. Instalar React Router v6 e criar a estrutura de rotas:
   - /login, /register → sem autenticação
   - /dashboard, /transactions, /categories, /goals, /investments → protegidas (redireciona para /login se não autenticado)
4. Instalar e configurar TanStack Query (QueryClient + QueryClientProvider no main.tsx)
5. Criar um arquivo src/lib/api.ts com uma instância do axios apontando para http://localhost:3000, com interceptor para adicionar o Bearer token no header de toda requisição

Estrutura de pastas sugerida para src/:
  pages/      → componentes de páginas
  components/ → componentes reutilizáveis
  hooks/      → custom hooks (useAuth, useTransactions...)
  lib/        → configurações (api.ts, queryClient.ts)
  types/      → tipos TypeScript
```

**Subtasks:**
- [ ] Criar app Vite em `apps/web` com template `react-ts`
- [ ] Instalar e configurar Tailwind CSS
- [ ] Instalar React Router e criar arquivo de rotas com `PrivateRoute`
- [ ] Instalar TanStack Query e configurar o `QueryClientProvider` no `main.tsx`
- [ ] Instalar axios e criar `src/lib/api.ts` com interceptor de token
- [ ] Criar a estrutura de pastas: `pages/`, `components/`, `hooks/`, `lib/`, `types/`
- [ ] Confirmar que `npm run dev` abre o app em `http://localhost:5173`

---

## T1.2 — Layout Base (Sidebar, Header, Rotas Protegidas)

**Status:** [ ] Pendente

**O que é:** Criar o "esqueleto" visual que vai envolver todas as páginas do app: a barra lateral de navegação, o cabeçalho com nome do usuário, e a lógica que redireciona para login quando não autenticado.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind CSS), preciso criar o layout base do app.

1. Componente AppLayout (envolve todas as páginas autenticadas):
   - Sidebar fixa à esquerda com links de navegação:
     → Dashboard, Transações, Categorias, Metas, Investimentos
   - Ícone + nome de cada item na sidebar (pode usar heroicons ou lucide-react)
   - Header no topo com: nome do usuário logado + botão de logout
   - Área de conteúdo principal (children) que ocupa o restante da tela
   - Design: fundo cinza escuro (#1a1a2e) ou similar, sidebar em tom mais escuro, clean e moderno

2. Componente PrivateRoute:
   - Lê o token do localStorage
   - Se não existe token → redireciona para /login
   - Se existe → renderiza o AppLayout com a página filha

3. Hook useAuth:
   - Armazena user + token no localStorage
   - Expõe: user, isAuthenticated, login(token, user), logout()

Me mostre os arquivos completos com TypeScript.
```

**Subtasks:**
- [ ] Instalar `lucide-react` para ícones
- [ ] Criar hook `useAuth` com localStorage
- [ ] Criar componente `PrivateRoute` que lê o token e redireciona
- [ ] Criar componente `AppLayout` com Sidebar e Header
- [ ] Aplicar `AppLayout` em todas as rotas protegidas no arquivo de rotas
- [ ] Confirmar que acessar `/dashboard` sem token redireciona para `/login`
- [ ] Confirmar que o layout aparece corretamente com a navegação lateral

---

## T1.3 — Telas de Login e Registro

**Status:** [ ] Pendente

**O que é:** As primeiras telas reais do app. O usuário digita email e senha para criar conta ou entrar. Ao fazer login com sucesso, é redirecionado para o dashboard.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind + TanStack Query + Zod), preciso criar as telas de Login e Registro.

Tela de Login (/login):
- Campos: email + senha
- Validação com Zod: email válido, senha não vazia
- Ao submeter: POST /auth/login → salva token no localStorage via useAuth → redireciona para /dashboard
- Link "Não tem conta? Criar conta" que vai para /register
- Mostrar mensagem de erro em vermelho se credenciais inválidas

Tela de Registro (/register):
- Campos: nome, email, senha, confirmar senha
- Validação: email válido, senha mínimo 8 chars, senhas iguais
- Ao submeter: POST /auth/register → faz login automático → redireciona para /dashboard
- Link "Já tem conta? Entrar" que vai para /login

Estilo:
- Centralizado na tela, card branco/escuro com sombra
- Logo "Bolso Firme" no topo
- Botão de submit com loading state (spinner enquanto aguarda a API)

Me mostre os componentes completos com tratamento de erro e tipos TypeScript.
```

**Subtasks:**
- [ ] Instalar `react-hook-form` para gerenciar os formulários
- [ ] Criar componente de formulário `LoginPage`
- [ ] Criar componente de formulário `RegisterPage`
- [ ] Conectar ambos ao hook `useAuth` para salvar o token após sucesso
- [ ] Testar o fluxo completo: registrar → ver dashboard → recarregar página → continuar logado
- [ ] Testar logout: clicar em logout → voltar para /login

---

## T1.4 — Backend: CRUD de Transações

**Status:** [ ] Pendente

**O que é:** Criar os endpoints da API que permitem criar, listar, editar e deletar transações financeiras. É a funcionalidade central do app — tudo gira em torno das transações.

**Prompt para IA:**
```
No BolsoFirme (Node.js + Express + TypeScript + Prisma + Zod), com arquitetura DDD, preciso implementar o CRUD completo de Transações.

Endpoints (todos autenticados com JWT middleware):
- POST   /transactions      → criar transação
- GET    /transactions      → listar com filtros (query params: startDate, endDate, categoryId, type)
- GET    /transactions/:id  → buscar uma transação
- PATCH  /transactions/:id  → editar transação
- DELETE /transactions/:id  → deletar

Campos da transação:
- amount: número positivo (Decimal)
- type: "INCOME" ou "EXPENSE"
- categoryId: UUID (opcional)
- date: data ISO string
- description: texto (opcional)

Regras de negócio:
- Transação só pode ser vista/editada/deletada pelo próprio usuário (userId do token JWT)
- amount deve ser maior que 0
- Retornar 404 se transação não pertence ao usuário logado

Validação: schemas Zod em packages/shared para reutilizar no frontend

Me mostre: use case, repository, controller, rotas e schemas Zod.
```

**Subtasks:**
- [ ] Criar schemas Zod em `packages/shared/src/schemas/transaction.ts`
- [ ] Criar `TransactionRepository` em `apps/api/src/infrastructure/` usando Prisma
- [ ] Criar use cases: `CreateTransaction`, `ListTransactions`, `UpdateTransaction`, `DeleteTransaction`
- [ ] Criar controller e rotas em `apps/api/src/interface/`
- [ ] Aplicar middleware `authenticate` em todas as rotas
- [ ] Testar todos os endpoints com Postman/Insomnia
- [ ] Confirmar que não é possível ver transações de outro usuário

---

## T1.5 — Formulário de Lançamento de Transação

**Status:** [ ] Pendente

**O que é:** A tela onde o usuário registra um gasto ou receita. Deve ser rápida e intuitiva — o usuário entra, preenche 3 campos, salva e volta para o que estava fazendo.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind + TanStack Query + React Hook Form + Zod), preciso criar o formulário de lançamento de transação.

Campos:
- Tipo: toggle visual ENTRADA / SAÍDA (verde/vermelho)
- Valor: input numérico com formatação de moeda (R$ 1.500,00) em tempo real
- Categoria: dropdown com as categorias do usuário (carregadas da API GET /categories)
- Data: input de data (padrão: hoje)
- Descrição: texto livre (opcional)

Comportamento:
- Validação com Zod (valor > 0, tipo obrigatório)
- Ao salvar: POST /transactions → invalida cache TanStack Query → fecha o formulário
- Loading state no botão durante o POST
- Toast de sucesso/erro (pode usar react-hot-toast)
- Campo de valor com máscara: ao digitar "150000" mostra "R$ 1.500,00"

Reconhecimento de padrão (básico):
- Se descrição contém "ifood", "rappi", "uber eats" → pré-selecionar categoria "Alimentação"
- Se contém "uber", "99", "combustível" → pré-selecionar "Transporte"

Me mostre o componente completo com TypeScript e a lógica de reconhecimento de padrão.
```

**Subtasks:**
- [ ] Instalar `react-hot-toast` para notificações
- [ ] Criar componente `TransactionForm` com toggle ENTRADA/SAÍDA
- [ ] Implementar máscara de valor em tempo real (R$ formatado)
- [ ] Carregar categorias da API com TanStack Query para o dropdown
- [ ] Implementar reconhecimento básico de padrão na descrição
- [ ] Conectar formulário ao `POST /transactions` com TanStack Mutation
- [ ] Confirmar que após salvar a lista de transações atualiza automaticamente

---

## T1.6 — Lista de Transações com Filtros

**Status:** [ ] Pendente

**O que é:** A tela que mostra todas as transações do usuário, com opção de filtrar por período, categoria e tipo. O usuário pode editar ou deletar qualquer lançamento.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind + TanStack Query), preciso criar a página de listagem de transações.

Layout:
- Header da página com botão "+ Nova Transação" (abre o TransactionForm em modal)
- Barra de filtros:
  → Período: seletor de mês/ano (padrão: mês atual)
  → Tipo: Todos / Entradas / Saídas
  → Categoria: dropdown (Todas + lista de categorias)
- Lista de transações agrupadas por data (ex: "Hoje — 11/03", "Ontem — 10/03")
- Cada item da lista mostra: ícone da categoria, descrição, valor colorido (verde=entrada, vermelho=saída), data
- Ao clicar em uma transação: abre modal de edição
- Botão de deletar com confirmação (para não deletar por acidente)

Paginação:
- Carregar 20 transações por vez
- Botão "Carregar mais" no final da lista

Me mostre os componentes com TypeScript e os hooks TanStack Query para busca com filtros.
```

**Subtasks:**
- [ ] Criar página `TransactionsPage` com layout de header + filtros + lista
- [ ] Implementar seletor de mês/ano como filtro de período
- [ ] Criar hook `useTransactions(filters)` com TanStack Query
- [ ] Agrupar transações por data
- [ ] Criar modal de edição reutilizando `TransactionForm`
- [ ] Implementar confirmação de exclusão (modal simples "Deseja deletar?")
- [ ] Confirmar que filtros atualizam a lista sem reload

---

## T1.7 — Importação OFX/CSV

**Status:** [ ] Pendente

**O que é:** Permite ao usuário baixar o extrato do banco e importar no app com um clique. O backend lê o arquivo e cria as transações automaticamente.

**Prompt para IA:**
```
No BolsoFirme, preciso implementar importação de arquivos OFX (padrão dos bancos brasileiros) e CSV.

Backend (Node.js + TypeScript + Prisma):
- Endpoint: POST /transactions/import
- Aceita: multipart/form-data com campo "file"
- Suporta: .ofx e .csv
- Para OFX: usar biblioteca `ofx-js` ou implementar parser básico (extrai: date, amount, memo)
- Para CSV: colunas esperadas: data, valor, descrição (aceitar variações comuns dos bancos)
- Para cada transação no arquivo:
  → Se já existe (mesmo valor + data + descrição) → ignorar (evitar duplicatas)
  → Caso contrário → criar no banco vinculada ao usuário logado
- Retornar: { importados: N, ignorados: N, erros: N }

Frontend (React + Tailwind):
- Botão "Importar extrato" na página de transações
- Modal com drag-and-drop de arquivo (ou clique para selecionar)
- Mostrar preview: "X transações encontradas — Importar?"
- Após importar: toast com resultado + atualiza a lista

Me mostre backend e frontend com TypeScript.
```

**Subtasks:**
- [ ] Instalar `multer` (upload de arquivos) e `ofx-js` (parser OFX) no backend
- [ ] Criar endpoint `POST /transactions/import` com Multer
- [ ] Implementar parser OFX
- [ ] Implementar parser CSV (usando biblioteca `csv-parse`)
- [ ] Implementar lógica de deduplicação (não importar duplicatas)
- [ ] Criar modal de importação no frontend com drag-and-drop
- [ ] Testar importando um extrato real de um banco brasileiro

---

## T1.8 — Dashboard Mensal (Gráfico de Rosca + Resumo)

**Status:** [ ] Pendente

**O que é:** A tela principal do app. O usuário vê de relance: quanto entrou, quanto saiu, quanto sobrou, e um gráfico de rosca mostrando para onde o dinheiro foi por categoria.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind + Recharts + TanStack Query), preciso criar o Dashboard principal.

Layout:
1. Seletor de período no topo (mês anterior / mês atual / próximo mês)

2. Cards de resumo (linha de 3 cards):
   - ENTRADAS: total de receitas do mês (em verde)
   - SAÍDAS: total de gastos do mês (em vermelho)
   - SALDO: entradas - saídas (verde se positivo, vermelho se negativo)

3. Gráfico de rosca (Recharts PieChart):
   - Cada fatia = uma categoria de gasto
   - Cor de cada fatia = cor da categoria
   - Tooltip mostrando: nome da categoria + valor + percentual
   - Legenda abaixo do gráfico

4. Lista das top 5 categorias que mais gastou no mês:
   - Barra de progresso mostrando % do total gasto
   - Nome, valor e percentual

5. Botão flutuante "+ Lançar" no canto inferior direito (atalho rápido)

Backend: criar endpoint GET /dashboard/summary?month=YYYY-MM que retorna os totais e o breakdown por categoria.

Me mostre backend e frontend completos com TypeScript e Recharts.
```

**Subtasks:**
- [ ] Criar endpoint `GET /dashboard/summary` no backend com Prisma aggregations
- [ ] Criar hook `useDashboardSummary(month)` com TanStack Query
- [ ] Criar os 3 cards de resumo (ENTRADAS / SAÍDAS / SALDO)
- [ ] Implementar gráfico de rosca com Recharts (PieChart + Tooltip)
- [ ] Criar lista das top 5 categorias com barra de progresso
- [ ] Implementar seletor de mês (← mês atual →)
- [ ] Adicionar botão flutuante de atalho para nova transação
- [ ] Confirmar que alterar o mês recarrega os dados automaticamente

---

## Checklist Final da Fase 1

Antes de avançar para a Fase 2, confirme:

- [ ] É possível se registrar, fazer login e manter sessão
- [ ] É possível lançar uma transação (entrada e saída)
- [ ] É possível editar e deletar uma transação
- [ ] Importação OFX funciona com um extrato real
- [ ] Dashboard mostra gráfico correto para o mês atual
- [ ] Nenhum dado de outro usuário é visível (isolamento por userId)

---

*Fase 1 concluída → abrir [task-fase-2-orcamento.md](task-fase-2-orcamento.md)*
