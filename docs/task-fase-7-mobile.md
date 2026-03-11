# Fase 7 — Mobile: React Native + Expo

> **Estimativa:** 6–8 semanas | **Pré-requisito:** Fase 6 concluída (app web estável)
>
> Esta fase porta o BolsoFirme para iOS e Android usando React Native + Expo. A grande vantagem é que a API backend já está pronta e o código de lógica de negócio já existe em `packages/shared` — o trabalho aqui é principalmente de interface.

---

## T7.1 — Setup React Native + Expo

**Status:** [ ] Pendente

**O que é:** Criar o app mobile dentro do monorepo, configurado para compartilhar código com o app web. O Expo simplifica muito o processo de build e publicação.

**Prompt para IA:**
```
No monorepo BolsoFirme (Turborepo), preciso criar um app React Native com Expo dentro de apps/mobile.

Stack: React Native + Expo SDK 51 + TypeScript + Expo Router (navegação baseada em arquivos)

Configurações necessárias:
1. Criar app: npx create-expo-app@latest mobile --template blank-typescript
2. Configurar Turborepo para incluir apps/mobile no pipeline
3. Instalar e configurar NativeWind (Tailwind para React Native) para reutilizar classes de estilo

Estrutura de pastas em apps/mobile/src/:
  app/          → páginas com Expo Router (equivalente ao pages/ do web)
  components/   → componentes React Native reutilizáveis
  hooks/        → custom hooks (reutilizados de packages/shared quando possível)
  lib/          → api.ts (mesma lógica do web, adaptada para React Native)

Compartilhamento de código:
- packages/shared já tem: tipos TypeScript, schemas Zod, funções utilitárias
- O apps/mobile vai importar de packages/shared diretamente
- NÃO compartilhar componentes visuais (React vs React Native têm APIs diferentes)

Me mostre:
1. Como adicionar apps/mobile ao turbo.json
2. Configuração do NativeWind
3. Configuração do Expo Router com autenticação (redirecionar para /login se não autenticado)
4. Como apontar a API para localhost:3000 no desenvolvimento
```

**Subtasks:**
- [ ] Criar app Expo em `apps/mobile` com template TypeScript
- [ ] Adicionar `apps/mobile` ao `turbo.json` pipeline
- [ ] Instalar e configurar NativeWind
- [ ] Configurar Expo Router com estrutura de rotas: `(auth)/login`, `(app)/dashboard`, etc.
- [ ] Criar `apps/mobile/src/lib/api.ts` reutilizando a lógica de `packages/shared`
- [ ] Confirmar que `npx expo start` abre o app no Expo Go (celular) ou simulador

---

## T7.2 — Telas de Auth e Layout Base Mobile

**Status:** [ ] Pendente

**O que é:** Adaptar as telas de login/registro e o layout de navegação para mobile. No mobile, a navegação é por abas na parte inferior, não sidebar.

**Prompt para IA:**
```
No BolsoFirme mobile (React Native + Expo Router + NativeWind + TypeScript), preciso criar:

1. Telas de autenticação:
   - (auth)/login.tsx: campos de email + senha, botão entrar, link para registro
   - (auth)/register.tsx: nome, email, senha, botão criar conta
   - Mesma lógica de chamada de API do web (usar packages/shared/src/hooks/useAuth)
   - Guardar token com SecureStore (Expo) ao invés de localStorage

2. Layout base autenticado (app/(app)/_layout.tsx):
   - Tab Navigator na parte inferior com 4 abas:
     → 🏠 Dashboard | 💸 Transações | 🎯 Metas | 📊 Investimentos
   - Ícones com lucide-react-native
   - Design: fundo escuro, tab ativa destacada

3. Redirecionar para /login se não autenticado (usar expo-router/protected-routes)

Diferenças importantes vs web:
- Usar KeyboardAvoidingView nos formulários
- Usar TouchableOpacity ao invés de button
- SafeAreaView para respeitar o notch
- react-native-toast-message ao invés de react-hot-toast

Me mostre os arquivos completos com TypeScript.
```

**Subtasks:**
- [ ] Instalar `expo-secure-store` e adaptar `useAuth` para mobile
- [ ] Criar telas `login.tsx` e `register.tsx`
- [ ] Criar Tab Navigator com 4 abas na parte inferior
- [ ] Implementar proteção de rotas com Expo Router
- [ ] Testar fluxo completo: login → ver abas → logout → voltar para login
- [ ] Confirmar que o teclado não cobre os campos de formulário

---

## T7.3 — Telas Principais no Mobile

**Status:** [ ] Pendente

**O que é:** Adaptar as 4 telas principais (Dashboard, Transações, Metas, Investimentos) para a experiência mobile. O conteúdo é o mesmo; o layout muda para telas menores e touch.

**Prompt para IA:**
```
No BolsoFirme mobile (React Native + NativeWind + Recharts substituído por Victory Native), preciso criar as 4 telas principais.

1. Dashboard (/dashboard):
   - Cards de resumo (entrada, saída, saldo) em ScrollView horizontal
   - Gráfico de pizza (Victory Native PieChart substituindo Recharts)
   - Lista das top categorias com barra de progresso
   - FAB (Floating Action Button) para lançar transação

2. Transações (/transactions):
   - FlatList performática (não ScrollView) para a lista de transações
   - Pull-to-refresh para recarregar
   - Modal de nova transação como BottomSheet (Expo)

3. Metas (/goals):
   - Grid de cards com FlatList numColumns={2}
   - Animação ao atingir 100% (usando Animated da RN)

4. Investimentos (/investments):
   - Lista de ativos agrupados por tipo
   - Card de patrimônio total no topo

Reutilizar ao máximo de packages/shared: hooks de API (TanStack Query funciona no RN), schemas Zod, funções de cálculo.

Me mostre as telas completas com TypeScript e os componentes RN necessários.
```

**Subtasks:**
- [ ] Instalar `victory-native` para gráficos (Recharts não funciona em RN)
- [ ] Instalar `@gorhom/bottom-sheet` para o modal de nova transação
- [ ] Criar tela `Dashboard` com ScrollView + gráfico de pizza
- [ ] Criar tela `Transactions` com FlatList + pull-to-refresh + bottom sheet
- [ ] Criar tela `Goals` com FlatList numColumns={2} + animação
- [ ] Criar tela `Investments` com lista agrupada
- [ ] Confirmar que TanStack Query funciona corretamente e os dados carregam

---

## T7.4 — Build e Publicação nas Lojas *(sintetizado)*

**Status:** [ ] Pendente

**O que é:** Gerar os arquivos finais (.apk / .ipa) e publicar nas lojas. O Expo EAS (Expo Application Services) automatiza grande parte desse processo.

**Prompt para IA:**
```
No BolsoFirme mobile (Expo SDK 51), preciso configurar o build e publicação nas lojas.

1. Configurar EAS Build:
   - Instalar EAS CLI: npm install -g eas-cli
   - eas login + eas build:configure
   - Criar eas.json com profiles: development, preview, production

2. Configurar app.json:
   - name: "Bolso Firme"
   - slug: "bolso-firme"
   - version: "1.0.0"
   - ios.bundleIdentifier: "com.bolsofirme.app"
   - android.package: "com.bolsofirme.app"
   - Ícone e splash screen (assets a criar)

3. Build de produção:
   - Android: eas build --platform android --profile production → gera .aab
   - iOS: eas build --platform ios --profile production → gera .ipa

4. Publicação:
   - Google Play: fazer upload manual do .aab no Google Play Console
   - App Store: usar eas submit --platform ios

Me mostre o eas.json, o app.json completo e o passo a passo de publicação.
```

**Subtasks:**
- [ ] Criar ícone do app (1024×1024 px) e splash screen
- [ ] Configurar `app.json` com nome, bundle ID e assets
- [ ] Instalar EAS CLI e rodar `eas build:configure`
- [ ] Criar `eas.json` com profiles de development, preview e production
- [ ] Fazer build de preview para Android (.apk) e testar no celular real
- [ ] Criar conta no Google Play Console e fazer upload do .aab
- [ ] Criar conta no Apple Developer Program (necessário para iOS) e fazer upload via EAS Submit

---

## Checklist Final da Fase 7

Antes de considerar o mobile concluído, confirme:

- [ ] Login e registro funcionam no app mobile
- [ ] Dashboard carrega dados reais da API
- [ ] É possível lançar uma transação pelo FAB
- [ ] Gráficos aparecem corretamente no mobile
- [ ] App funciona sem crash no Android e iOS
- [ ] Build de produção gerado com sucesso pelo EAS

---

*Fase 7 concluída → Produto completo! Considerar Fase 8 (Open Finance) quando houver tração.*

---

## Fase 8 — Open Finance (Referência Futura)

> **Estimativa:** 3–6 meses | **Custo:** R$10k–R$50k em certificações | **Pré-requisito:** base de usuários estável

Esta fase integra automaticamente os dados bancários via Open Finance (Banco Central do Brasil). Não há tasks detalhadas aqui — é um projeto por si só que requer:

- Certificação como Iniciador de Pagamentos no Banco Central
- Implementação do protocolo FAPI (Financial-grade API Security Profile)
- Integração com os conectores OpenID Connect dos bancos participantes
- Conformidade com LGPD para dados financeiros sensíveis

**Referências:** [openfinancebrasil.org.br](https://openfinancebrasil.org.br) e documentação oficial do BACEN.
