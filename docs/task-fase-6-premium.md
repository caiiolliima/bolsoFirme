# Fase 6 — Premium: Pagamento e Freemium

> **Estimativa:** 2–3 semanas | **Pré-requisito:** Fase 5 concluída | **Desbloquia:** Fase 7
>
> Esta fase monetiza o produto. Integra o Stripe para processamento de pagamento, implementa os gates de freemium (o que é gratuito vs pago) e cria o fluxo de upgrade do usuário.

---

## T6.1 — Integração Stripe (Checkout + Webhook)

**Status:** [ ] Pendente

**O que é:** Conectar o app com o Stripe para processar assinaturas. O usuário clica em "Assinar Premium", vai para a página de pagamento do Stripe, paga e volta automaticamente como Premium.

**Prompt para IA:**
```
No BolsoFirme (Node.js + Express + TypeScript + Prisma), preciso integrar o Stripe para assinaturas.

Planos:
- Individual: R$19,90/mês ou R$159,90/ano (criar os produtos no Stripe Dashboard)
- Família: R$34,90/mês ou R$279,90/ano

Backend:
1. Instalar: stripe (Node SDK)

2. Novos campos no User (Prisma):
   - stripeCustomerId: string (nullable)
   - plan: "FREE" | "PREMIUM" (default: FREE)
   - planExpiresAt: DateTime (nullable)

3. Endpoints:
   - POST /billing/checkout   → cria Stripe Checkout Session e retorna a URL
   - POST /billing/webhook    → recebe eventos do Stripe (assinatura paga, cancelada, renovada)
   - GET  /billing/portal     → cria Stripe Customer Portal session (gerenciar assinatura)
   - GET  /billing/status     → retorna plano atual do usuário

4. No webhook:
   - checkout.session.completed → marcar user como PREMIUM
   - customer.subscription.deleted → voltar para FREE
   - invoice.payment_failed → notificar usuário

Segurança: verificar assinatura do webhook com STRIPE_WEBHOOK_SECRET do .env

Me mostre o código completo com TypeScript e instruções de configuração do Stripe Dashboard.
```

**Subtasks:**
- [ ] Criar conta no Stripe e criar os 4 produtos/preços (individual mensal/anual, família mensal/anual)
- [ ] Instalar `stripe` em `apps/api` e configurar variáveis no `.env`
- [ ] Adicionar campos `stripeCustomerId`, `plan`, `planExpiresAt` no schema Prisma e rodar migration
- [ ] Implementar endpoint `POST /billing/checkout`
- [ ] Implementar endpoint `POST /billing/webhook` com verificação de assinatura
- [ ] Implementar endpoint `GET /billing/portal`
- [ ] Testar com Stripe CLI (`stripe listen --forward-to localhost:3000/billing/webhook`)
- [ ] Confirmar que após pagamento de teste, `plan` do usuário muda para PREMIUM

---

## T6.2 — Feature Flags (Freemium Gates)

**Status:** [ ] Pendente

**O que é:** Implementar as restrições do plano gratuito. O usuário gratuito pode usar o app com limites; ao tentar usar um recurso Premium, vê uma tela de upgrade.

**Prompt para IA:**
```
No BolsoFirme, preciso implementar os feature gates do freemium.

Limites do plano FREE:
- Categorias personalizadas: máximo 3
- Metas ativas: máximo 2
- Histórico de transações: apenas 3 meses
- Sem: divisão automática do salário, carteira de investimentos, modo família, alertas premium

Backend:
1. Middleware `requirePlan(plan)`:
   - Verifica se usuário tem o plano necessário
   - Se não → retorna 403 com { error: "PLAN_REQUIRED", requiredPlan: "PREMIUM" }

2. Middleware `requireLimit(resource, limit)`:
   - Para categorias: conta quantas o usuário tem, se >= 3 → bloqueia
   - Para metas: conta quantas ativas, se >= 2 → bloqueia

3. Aplicar nos endpoints relevantes:
   - POST /categories → verificar limite de 3 se FREE
   - POST /goals → verificar limite de 2 se FREE
   - GET /transactions → filtrar por 3 meses se FREE
   - POST /categories/auto-distribute → requirePlan("PREMIUM")
   - GET /assets → requirePlan("PREMIUM")

Frontend:
1. Hook usePlan() → retorna { plan, isPremium, limits }

2. Componente PremiumGate:
   - Envolve qualquer funcionalidade premium
   - Se usuário FREE → mostra modal de upgrade no lugar do conteúdo
   - Modal: "Este recurso é exclusivo do Premium" + botão "Assinar agora"

3. Locks visuais nas funcionalidades bloqueadas (ícone 🔒 discreto)

Me mostre middleware, hook e componente PremiumGate com TypeScript.
```

**Subtasks:**
- [ ] Criar middleware `requirePlan` no backend
- [ ] Criar middleware `requireLimit` no backend
- [ ] Aplicar middlewares em todos os endpoints relevantes
- [ ] Criar hook `usePlan()` no frontend
- [ ] Criar componente `PremiumGate` que mostra modal de upgrade
- [ ] Adicionar ícone 🔒 em funcionalidades bloqueadas na sidebar e nas páginas
- [ ] Testar: usuário FREE tentando criar 4ª categoria → ver modal de upgrade

---

## T6.3 — Onboarding e Telas de Planos *(sintetizado)*

**Status:** [ ] Pendente

**O que é:** O fluxo de boas-vindas para novos usuários (configuram salário e categorias no primeiro acesso) e as telas de preços para quem quer fazer upgrade.

**Prompt para IA:**
```
No BolsoFirme (React + TypeScript + Tailwind), preciso criar:

1. Fluxo de Onboarding (apenas no primeiro login):
   Passo 1: "Bem-vindo ao Bolso Firme! Qual é o seu salário mensal?" (input de valor)
   Passo 2: "Quanto você quer destinar para cada área?" (sliders de categorias com sugestão 50/30/20)
   Passo 3: "Quer criar uma primeira meta?" (opcional — nome + valor)
   Passo 4: "Tudo pronto! Vamos lá." (redirect para dashboard)

   - Verificar se é primeiro acesso por campo firstLoginAt no User (null = nunca fez onboarding)
   - Pular para o dashboard se onboarding já foi feito

2. Página de Planos (/pricing):
   - Cards lado a lado: Gratuito vs Premium
   - Tabela de comparação com os recursos (ícone ✓ e ✗)
   - Preços: R$19,90/mês ou R$159,90/ano (destacar o anual como "2 meses grátis")
   - Botão "Assinar" → chama POST /billing/checkout e redireciona para Stripe
   - Se já for Premium → mostrar "Gerenciar assinatura" → chama GET /billing/portal

Me mostre os componentes de onboarding (wizard multi-step) e a página de planos com TypeScript.
```

**Subtasks:**
- [ ] Adicionar campo `onboardingCompletedAt` no User (Prisma migration)
- [ ] Criar componente de wizard multi-step `OnboardingFlow`
- [ ] Redirecionar automaticamente para onboarding no primeiro login
- [ ] Criar página `/pricing` com cards de planos e tabela de comparação
- [ ] Conectar botão "Assinar" ao `POST /billing/checkout`
- [ ] Testar fluxo completo: novo usuário → onboarding → dashboard → upgrade → Premium

---

## Checklist Final da Fase 6

Antes de avançar para a Fase 7, confirme:

- [ ] Pagamento via Stripe funciona no modo de teste (cartão `4242 4242 4242 4242`)
- [ ] Após pagamento, plano do usuário muda para PREMIUM no banco
- [ ] Usuário FREE vê modal de upgrade ao tentar criar 4ª categoria
- [ ] Usuário FREE vê apenas 3 meses de histórico de transações
- [ ] Onboarding aparece apenas no primeiro acesso
- [ ] Webhook de cancelamento funciona (plano volta para FREE)

---

*Fase 6 concluída → abrir [task-fase-7-mobile.md](task-fase-7-mobile.md)*
