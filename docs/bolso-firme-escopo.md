# BOLSO FIRME
## Documento de Escopo Final
**Versao 3.0 — Marco 2026 — Solo / Monorepo**

---

| Campo | Detalhe |
|---|---|
| Projeto | BolsoFirme |
| Status | Escopo fechado — pré-desenvolvimento |
| Plataforma | Web (prioridade) + Mobile React Native (Fase 7) |
| Modelo | Freemium — gratuito com recursos pagos |
| Usuários | Individual + Compartilhado (casal/família) |
| Trabalho | Solo, Monorepo gerenciado com Turborepo |

---

## 1. Visao Geral do Projeto

### 1.1 Problema que Resolve

Pessoas que ganham dinheiro mas nao sabem para onde ele vai. A falta de visibilidade, estrutura e motivacao faz com que elas desistam de controlar as financas.

O BolsoFirme resolve 3 problemas ao mesmo tempo:

- **Visibilidade:** mostra exatamente onde o dinheiro esta indo
- **Estrutura:** organiza limites por categoria com base no salario
- **Motivacao:** torna os sonhos financeiros visiveis e alcancaveis

### 1.2 Diferencial Competitivo

> **Por que o BolsoFirme e diferente de Mobills, Organizze e Guiabolso?**
>
> A maioria dos apps mostra dados de forma tecnica e fria.
>
> O BolsoFirme vai de macro para micro: voce ve o ano inteiro primeiro, depois afunila para mes, semana e dia — como dar zoom num mapa.
>
> Alem disso, une Carteira de Investimentos + Metas de Sonho + Orcamento, tudo num dashboard visual interativo — sem precisar abrir o app do banco.

### 1.3 Origem do Nome

> **Por que Bolso Firme?**
>
> O nome anterior era "Controle na Marra", que tem personalidade mas pode soar agressivo para pessoas que ja se sentem mal com financas.
>
> **Bolso Firme:** transmite controle sem ser agressivo, e facil de lembrar, soa como algo que se conquista aos poucos, e brasileiro sem ser gira.
>
> Outras opcoes consideradas: Dinheiro na Regua, Vira o Jogo, Fio do Dinheiro, Grana Certa.

### 1.4 Publico-Alvo

- Pessoas entre 18 e 40 anos, renda entre R$2.000 e R$15.000/mes
- Que ja tentaram controlar financas mas desistiram por complexidade
- Que tem compulsoes financeiras (compras por impulso, parcelamentos)
- Que querem juntar dinheiro para um objetivo concreto (viagem, carro, casa)
- Casais e familias que querem organizar as financas juntos

---

## 2. Decisoes de Projeto

Todas as decisoes foram tomadas durante a fase de escopo e estao registradas abaixo com justificativa.

| Decisao | Escolha | Justificativa |
|---|---|---|
| Trabalho | Solo, Monorepo | Controle total, sem overhead de equipe |
| Gerenciador de Monorepo | Turborepo | Builds rapidos, cache inteligente |
| Frontend | React + Vite + React Router | Componentes reutilizaveis, erros pegos antes de rodar |
| Estilo | Tailwind CSS puro | Classes prontas, rapido, consistente no design |
| Graficos | Recharts | Graficos bonitos com animacao e responsividade |
| Estado e chamadas de API | TanStack Query (React Query) | Cache automatico, loading/error states faceis |
| Backend | Node.js + TypeScript | Mesmo idioma do front, ecossistema enorme |
| Arquitetura | DDD (Domain-Driven Design) | Separa regras de negocio, facilita crescimento |
| Validacao de dados | Zod | Compartilhado front e back, uma unica definicao |
| Autenticacao | JWT (registro, login, refresh) | Token seguro, padrao para APIs REST |
| ORM (acesso ao banco) | Prisma | Escreve queries como codigo normal, sem SQL bruto |
| Banco de dados | PostgreSQL | Robusto, gratuito, otimo para dados financeiros |
| Testes | Vitest + TDD | Rapido, compativel com TypeScript |
| Infra local | Docker Compose | Sobe todos os servicos com um comando |
| Infra futura (planejada) | AWS ou Azure | Mesmo container local vai para a nuvem |
| Mobile (Fase 7) | React Native + Expo | Reutiliza 70-80% do codigo web, iOS + Android |
| Integracao bancaria — MVP | Manual + importacao OFX/CSV | Pronto em semanas, funciona com qualquer banco |
| Integracao bancaria — Futuro | Open Finance automatico | Requer certificacao Banco Central |

---

## 3. Modulos do Produto

O BolsoFirme e dividido em 6 modulos. Os modulos 1 a 5 compoe o MVP. O modulo 6 (Multiusuario) fica para versao futura.

| # | Modulo | Status |
|---|---|---|
| 1 | Dashboard Principal | **MVP** |
| 2 | Lancamento de Transacoes | **MVP** |
| 3 | Categorias e Orcamento | **MVP** |
| 4 | Metas e Sonhos | **MVP** |
| 5 | Carteira de Investimentos | **MVP** |
| 6 | Multiusuario (Casal/Familia) | Futuro |

### Modulo 1 — Dashboard Principal

A tela central do app. Como um painel de controle de aviao: tudo que o usuario precisa saber de relance.

- Visao macro-para-micro: selecionar periodo (1 dia ate varios anos)
- Grafico de rosca mostrando percentual de cada categoria
- Barra de progresso das metas de sonho
- Resumo: quanto entrou, quanto saiu, quanto sobrou
- Alertas visuais quando uma categoria ultrapassa o limite definido
- Atalhos rapidos para lancamento de gastos

### Modulo 2 — Lancamento de Transacoes

Formulario rapido e inteligente para registrar qualquer movimentacao financeira.

- Campos: valor, categoria, data e descricao (opcional)
- Reconhecimento de padroes: "Ifood" vai automaticamente para "Alimentacao"
- Edicao e exclusao de lancamentos
- Importacao de arquivos OFX e CSV
- Filtros por periodo, categoria e valor

### Modulo 3 — Categorias e Orcamento

Estrutura de categorias com limites mensais para cada uma.

- Categorias padrao pre-configuradas: Moradia, Alimentacao, Transporte, Lazer, etc.
- Criacao de categorias personalizadas com cor e emoji
- Definir percentual do salario por categoria (ex: 30% moradia, 15% alimentacao)
- Calculo automatico ao informar o salario mensal
- Alerta automatico ao atingir o limite de uma categoria

### Modulo 4 — Metas e Sonhos

Torna os objetivos financeiros visiveis e acompanhaveis.

- Criar meta com nome, valor total, prazo e imagem (ex: "Moto Honda CB500 — R$30.000")
- Classificacao: curto prazo (ate 1 ano), medio (1 a 3 anos), longo (mais de 3 anos)
- Aportes mensais automaticos ou manuais
- Projecao visual: "no ritmo atual, voce alcanca em X meses"
- Barra de progresso colorida e celebracao ao completar a meta

### Modulo 5 — Carteira de Investimentos

Visao consolidada do patrimonio investido.

- Adicionar ativos manualmente: acoes, FIIs, CDB, Tesouro Direto, etc.
- Grafico de alocacao da carteira por tipo de ativo
- Historico de aportes
- Rentabilidade geral com calculo automatico via preco medio
- Visao do patrimonio total: dinheiro disponivel + investido

### Modulo 6 — Multiusuario (Casal/Familia) — Versao Futura

Fora do MVP. Sera desenvolvido apos a estabilizacao dos modulos 1 a 5.

- Criar grupo familiar com convite por email ou link
- Dashboard compartilhado com gastos de todos os membros
- Permissoes: admin (ve tudo) e membro (ve so o proprio)
- Orcamentos compartilhados por categoria
- Historico de quem lancou cada transacao

---

## 4. Arquitetura Tecnica

### 4.1 Camadas DDD (Domain-Driven Design)

O backend e organizado em camadas. Cada camada tem uma responsabilidade clara e independente, facilitando crescimento e manutencao.

| Camada | Responsabilidade | Exemplo |
|---|---|---|
| **Domain** | Regras do negocio | Um gasto nao pode ter valor negativo |
| **Application** | Casos de uso | Criar transacao, calcular orcamento mensal |
| **Infrastructure** | Conexao com banco, APIs externas, arquivos | Prisma + PostgreSQL, OFX parser |
| **Interface** | Controllers da API REST, validacao, respostas HTTP | Zod + Express controllers |

### 4.2 Como as Pecas se Encaixam

> **Analogia simples: o restaurante**
>
> `Front-end React`     = O salao, onde o cliente (voce) ve o cardapio e faz o pedido.
>
> `API REST`            = O garcom, que leva o pedido para a cozinha e traz o resultado.
>
> `Back-end Node.js`    = A cozinha, onde as regras de negocio sao executadas.
>
> `PostgreSQL + Prisma` = A despensa, onde todos os dados ficam guardados.
>
> `Docker`              = A caixa de entrega que garante que tudo funcione em qualquer lugar.
>
> `JWT`                 = O cracha do cliente que prova que ele esta logado sem pedir senha toda vez.

---

## 5. Stack Tecnica Detalhada

### 5.1 Frontend

| Tecnologia | Para que serve | Por que escolhemos |
|---|---|---|
| React + TypeScript + Vite | Construir as telas | Componentes reutilizaveis, erros pegos antes de rodar, build rapido |
| React Router | Navegacao entre paginas | Padrao do ecossistema React |
| Tailwind CSS | Estilizar tudo | Classes prontas, rapido, consistente no design |
| Recharts | Graficos interativos | Graficos bonitos com animacao e responsividade |
| TanStack Query | Gerenciar estado e chamadas de API | Cache automatico, loading/error states simples |
| Zod (shared) | Validar formularios | Garante que nenhum dado invalido entra no sistema |

### 5.2 Backend

| Tecnologia | Para que serve | Por que escolhemos |
|---|---|---|
| Node.js + TypeScript | Servidor da aplicacao | Mesmo idioma do front, ecossistema enorme |
| API REST | Comunicacao front-back | Padrao da industria, simples e confiavel |
| Prisma ORM | Acessar banco de dados | Escreve queries como codigo normal, sem SQL bruto |
| PostgreSQL | Banco de dados | Robusto, gratuito, otimo para dados financeiros |
| JWT | Autenticacao | Token seguro, padrao para login em APIs REST |
| Zod (shared) | Validacao de dados | Compartilhado entre front e back, uma unica definicao |

### 5.3 Infraestrutura e Qualidade

| Tecnologia | Para que serve | Por que escolhemos |
|---|---|---|
| Turborepo | Gerenciar monorepo | Builds rapidos, cache inteligente |
| Docker Compose | Empacotar a aplicacao localmente | Sobe todos os servicos com um unico comando |
| AWS ou Azure (futuro) | Hospedagem na nuvem | O mesmo container local vai direto para a nuvem |
| Vitest | Testes automatizados | Rapido, compativel com TypeScript, integra com TDD |
| React Native + Expo (Fase 7) | App mobile | Reutiliza 70-80% do codigo web, iOS e Android juntos |

---

## 6. Integracao Bancaria

O produto e entregue em duas versoes de integracao, de forma progressiva.

| Aspecto | Versao 1 — MVP (agora) | Versao 2 — Futuro |
|---|---|---|
| Metodo | Manual + importacao OFX/CSV | Open Finance automatico |
| Como funciona | Usuario baixa o extrato do banco e importa no app. O app le e organiza tudo automaticamente. | Usuario autoriza o app a LER os dados bancarios diretamente, como dar uma chave de leitura sem dar a chave da conta. |
| Complexidade | Baixa — sem API bancaria, sem certificacao | Alta — requer certificacao no Banco Central |
| Custo extra | Nenhum | R$10k a R$50k em certificacoes + 3 a 6 meses de dev |
| Vantagem | Funciona com qualquer banco do Brasil, pronto em semanas | Totalmente automatico, dados em tempo real |
| Desvantagem | Usuario precisa importar manualmente (1 clique no banco) | Manutencao constante das APIs dos bancos, LGPD avancada |

---

## 7. Modelo de Negocio — Freemium

A logica do freemium e: dar o suficiente para a pessoa experimentar e ver valor, e cobrar pelos recursos que fazem diferenca para quem e serio com as financas.

| Recurso | Gratuito | Premium |
|---|:---:|:---:|
| Dashboard e lancamento de transacoes | ✓ | ✓ |
| Categorias personalizadas | Ate 3 | Ilimitadas |
| Metas de sonho ativas | Ate 2 | Ilimitadas |
| Importacao OFX/CSV | ✓ | ✓ |
| Historico de transacoes | 3 meses | Completo (anos) |
| Percentuais personalizados por categoria | ✗ | ✓ |
| Divisao automatica do salario por categoria | ✗ | ✓ |
| Carteira de investimentos completa | ✗ | ✓ |
| Relatorios avancados e exportacao PDF/Excel | ✗ | ✓ |
| Modo multiusuario (casal/familia) | ✗ | ✓ |
| Open Finance automatico (versao futura) | ✗ | ✓ |
| Alertas de gastos por categoria | ✗ | ✓ |
| Suporte prioritario | ✗ | ✓ |

> **Sugestao de Preco Premium**
>
> Individual: R$19,90/mes ou R$159,90/ano (2 meses gratis)
>
> Familia (ate 5 usuarios): R$34,90/mes ou R$279,90/ano
>
> Benchmark: Mobills cobra R$15,90/mes, Organizze R$16,90/mes. Com mais recursos visuais e o modo familia, R$19,90 e competitivo.

---

## 8. Ambiente de Desenvolvimento e Deploy

### 8.1 Ambiente Local (agora)

Docker Compose sobe todos os servicos com um unico comando: `docker-compose up`

- API (Node.js)
- Banco de dados (PostgreSQL)
- Prisma Studio (interface visual do banco)

Frontend roda separado com: `npm run dev` (porta 5173)

Sem custo — tudo na maquina do desenvolvedor.

### 8.2 Deploy Futuro (planejado)

Plataforma: **AWS ou Azure.**

A arquitetura em containers (Docker) facilita a migracao — o mesmo container que roda local vai para a nuvem. A decisao de plataforma e configuracao ficam para uma fase posterior.

---

## 9. Roadmap de Desenvolvimento

Dividido em fases para nao tentar fazer tudo de uma vez. Cada fase entrega valor real para o usuario.

| Fase | O que faz | Tech principal | Tempo estimado |
|---|---|---|---|
| **Fase 0** | Setup: monorepo, Docker, banco, auth JWT, CI/CD basico | TypeScript, Node, Prisma, PostgreSQL, Docker | 2-3 semanas |
| **Fase 1** | MVP: lancamentos, categorias, dashboard mensal basico (versao gratuita) | React, Tailwind, Recharts, API REST, TanStack Query | 4-6 semanas |
| **Fase 2** | Orcamento: percentuais por categoria, divisao automatica do salario, alertas | Zod, regras de negocio DDD, notificacoes | 3-4 semanas |
| **Fase 3** | Metas e sonhos: metas com prazo, aportes, projecao visual, barra de progresso | Animacoes Tailwind, calculos DDD | 3-4 semanas |
| **Fase 4** | Investimentos: carteira manual, patrimonio total, graficos de alocacao | Recharts avancado | 3-4 semanas |
| **Fase 5** | Multiusuario: grupos familiares, permissoes, orcamento compartilhado | JWT roles, convites por email | 3-4 semanas |
| **Fase 6** | Premium: pagamento, freemium gates, onboarding | Stripe API, feature flags | 2-3 semanas |
| **Fase 7** | Mobile: React Native com codigo compartilhado do web | React Native, Expo | 6-8 semanas |
| **Fase 8 (futuro)** | Open Finance: integracao automatica com bancos brasileiros | Open Banking API, certificacao BCB | 3-6 meses |

> **Estimativas de tempo**
>
> MVP (Fases 0 a 2): trabalhando consistentemente, 9 a 13 semanas (~3 meses)
>
> Produto completo ate Fase 6: 6 a 7 meses
>
> App mobile (Fase 7): mais 2 meses
>
> Recomendacao: comece pelas Fases 0 e 1, lance o MVP, consiga usuarios, depois construa as proximas fases com feedback real.

---

## 10. Proximos Passos

Com o escopo fechado, os proximos entregaveis sao:

| # | Entregavel | Descricao | Status |
|---|---|---|---|
| 1 | Escopo Final v3.0 (este documento) | Sintese dos escopos v1 e v2 | ✅ Concluido |
| 2 | Estrutura do repositorio (monorepo) | Turborepo + TypeScript + ESLint + Prettier | Proximo passo |
| 3 | Docker Compose inicial | Node + PostgreSQL + Prisma Studio | Em breve |
| 4 | Schema inicial do banco de dados | Entidades: User, Transaction, Category, Goal, Asset | Em breve |
| 5 | Autenticacao JWT completa | Registro, login, refresh token | Em breve |
| 6 | Primeiro endpoint da API | POST /transactions | Em breve |
| 7 | Tasks e subtasks por fase | Detalhamento tecnico de cada fase do roadmap | Em breve |
| 8 | Wireframes das telas principais | Dashboard, lancamento, metas | A definir |

---

*Documento gerado em Marco de 2026. Versao 3.0 — Escopo Final.*