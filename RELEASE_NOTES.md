# Notas de Versão - Fiz Plantão

## Versão 1.2.4 (Build 12) - 7 de novembro de 2025

### 🔗 Deep Links e Autenticação

**Email de Confirmação**
- Corrigido redirect URL para usar deep link no mobile (`br.com.rodrigolanes.fizplantao://login-callback/`)
- Emails de confirmação agora abrem o app automaticamente ao clicar no link
- Configurado `emailRedirectTo` explícito em cadastro, reset de senha e reenvio de confirmação

**Deep Linking**
- Implementado suporte completo a deep links para callbacks de autenticação
- Adicionado intent-filter no AndroidManifest.xml
- Scheme configurado: `br.com.rodrigolanes.fizplantao://`

### 🗑️ Remoções

**Página de Perfil**
- Removida funcionalidade de vinculação de contas Google
- Supabase Flutter ainda não suporta `linkIdentity()` para mobile
- Interface simplificada: mantidos apenas botões de Sincronização, Relatórios, Locais e Logout

### ⚙️ Configuração Necessária

**Supabase Dashboard**
- Adicionar em Authentication → URL Configuration → Redirect URLs:
  - `br.com.rodrigolanes.fizplantao://**`
- Documentação completa em `CONFIGURAR_DEEP_LINK.md`

---

## Versão 1.2.3 (Build 11) - 7 de novembro de 2025

### 🔐 Correções de Autenticação

**Google Sign-In Production**
- Atualizado Google Web Client ID nos secrets do GitHub
- Configuração correta de OAuth Clients para debug e release
- Login com Google agora funciona em builds da Play Store

### 🛠️ Melhorias de CI/CD

**Flutter**
- Atualizado Flutter no GitHub Actions para 3.35.6
- Alinhado com versão local para compatibilidade
- Habilitado cache para builds mais rápidos

---

## Versão 1.2.2 (Build 10) - 7 de novembro de 2025

### 🐛 Correções

**Autenticação Google Android**
- Corrigido erro "Token Google ausente" no login Android
- Adicionado `serverClientId` (Web Client ID) na configuração do GoogleSignIn
- Login com Google agora funciona corretamente em dispositivos Android físicos e emuladores

**Configuração**
- `SupabaseConfig` agora inclui `googleWebClientId`
- GitHub Actions atualizado para incluir `GOOGLE_WEB_CLIENT_ID` nos secrets
- Documentação atualizada com instruções para SHA-1/SHA-256 no Google Cloud Console

### 📝 Para Desenvolvedores

Se estiver configurando o projeto:
1. Adicione SHA-1 e SHA-256 do keystore no Google Cloud Console
2. Configure o secret `GOOGLE_WEB_CLIENT_ID` no GitHub
3. Atualize `lib/config/supabase_config.dart` localmente com o Web Client ID

---

## Versão 1.2.1 (Build 9) - 7 de novembro de 2025

### 🐛 Correções Críticas

**Sincronização de Dados**
- Corrigido problema de duplicação de registros durante sincronização
- Implementada geração local de UUID v4 antes de salvar dados
- IDs agora são estáveis desde criação (não mudam após sync)
- Removida lógica de atualização de ID após insert no Supabase
- Eliminada cascata de atualização de referências

**Melhorias Técnicas**
- Adicionado package `uuid` para geração confiável de identificadores
- `DatabaseService.saveLocal()` e `savePlantao()` geram UUID automaticamente
- `SyncService` envia UUID local diretamente para Supabase
- Chaves do Hive sempre consistentes com IDs dos objetos

### 🔐 Autenticação Web

**Google Sign-In para Web**
- Implementado fluxo OAuth correto para plataforma web
- Configurado `redirectTo` para localhost:3000
- Separação de lógica: OAuth web vs token exchange mobile
- Porta fixa (3000) para desenvolvimento local web

### ⚠️ Importante

Se você experimentou duplicação de dados:
1. Faça logout
2. Limpe dados locais (IndexedDB no navegador ou pasta AppData no Android)
3. Faça login novamente
4. Sincronize - agora funcionará corretamente

---

## Versão 1.1.0 (Build 7) - 7 de novembro de 2025

### 🔐 Autenticação e Segurança

**Autenticação Firebase**
- Sistema de login e cadastro com Firebase Auth
- Suporte a login por email/senha
- Integração com Google Sign-In (Web e Android)
- Splash screen com verificação automática de autenticação
- Logout seguro com limpeza de cache

**Verificação de Email Obrigatória**
- Email de verificação enviado automaticamente após cadastro
- Tela dedicada para verificação de email
- Verificação automática a cada 3 segundos
- Botão para reenviar email (com cooldown de 60s)
- Bloqueio de acesso até confirmação do email
- Proteção contra sequestro de contas

**Isolamento de Dados por Usuário**
- Campo `userId` adicionado aos modelos Local e Plantão
- Cada usuário visualiza apenas seus próprios dados
- DatabaseService filtra automaticamente por usuário logado
- Migração automática de dados existentes

**Segurança**
- Redefinição de senha via email
- Account linking automático do Firebase (mesmo email = mesma conta)
- Dados preservados ao trocar método de autenticação
- Cache seguro de credenciais no Hive

### 🎨 Interface de Autenticação

- Telas de Login e Cadastro com design Material 3
- Validação de formulários em tempo real
- Indicadores de carregamento durante operações
- Mensagens de erro contextualizadas
- Toggle de visibilidade de senha
- "Esqueci minha senha" funcional
- Botões com Google branding

### 🔧 Infraestrutura

- Firebase configurado para Web e Android
- OAuth Client ID configurado para Google Sign-In
- TypeAdapters regenerados para novos campos
- AuthService centralizado para todas operações de autenticação

### ⚠️ Breaking Changes

- **Requer autenticação:** Usuários devem criar conta ou fazer login
- **Dados migrados:** Dados locais existentes vinculados ao primeiro usuário logado
- **Email obrigatório:** Verificação de email necessária para acessar o app

### 📝 Próximos Passos

- Sincronização de dados com Firestore (em desenvolvimento)
- Backup e restauração em nuvem
- Suporte a múltiplos dispositivos

---

## Versão 1.0.0 (Build 5) - 7 de novembro de 2025

### ✨ Novidades

**📊 Relatórios e Estatísticas**
- Nova tela de Relatórios acessível pelo ícone de gráfico no menu principal
- Relatório de Plantões por Local com:
  - Total geral destacado com quantidade de plantões
  - Toggle "Apenas pagamentos futuros" (ativado por padrão)
  - Percentual e barra de progresso de cada local em relação ao total
  - Valor médio por plantão
  - Detalhamento expandível com plantões agrupados por data de pagamento
  - Data/hora e valor individual de cada plantão

**🎨 Melhorias de Interface**
- Filtro de período agora é um IconButton compacto
- Indicador visual mostrando período filtrado quando ativo
- Toggle para mostrar/ocultar locais inativos na lista
- Locais inativos com destaque visual diferenciado (badge + cores)

### 🔧 Melhorias Técnicas
- Configurações do VS Code adicionadas ao repositório
- Instruções atualizadas com checklist obrigatório antes de commits
- Versionamento obrigatório antes de push para develop

---

## Versão 1.0.0 (Build 4) - 6 de novembro de 2025

### 🐛 Correções

**Configuração Android**
- Corrigido targetSdk para 34 no AndroidManifest.xml
- Garantida compatibilidade com requisitos da Google Play Store
- Build e deploy via GitHub Actions funcionando corretamente

---

## Versão 1.0.0 (Build 3) - 6 de novembro de 2025

### 🔧 Melhorias Técnicas

**Configuração de Build**
- Definidas configurações explícitas de SDK no build.gradle.kts
- minSdk: 21, targetSdk: 34, compileSdk: 36
- Corrigidas versões para compatibilidade com Play Store

---

## Versão 1.0.0 (Build 2) - 6 de novembro de 2025

### 🔧 Correções Técnicas

**Dependências**
- Corrigida versão do pacote intl para ^0.19.0 (compatibilidade com flutter_localizations)
- Resolvido conflito de dependências no GitHub Actions

**CI/CD**
- Atualizado Flutter para versão 3.27.0 no GitHub Actions
- Configurado deploy automático para teste interno no Google Play

---

## Versão 1.0.0 (Build 1) - 6 de novembro de 2025

### 🎉 Lançamento Inicial

Primeira versão do **Fiz Plantão** - o aplicativo essencial para profissionais de saúde gerenciarem seus plantões de forma simples e organizada.

### ✨ Funcionalidades

**Gestão de Locais**
- Cadastre seus locais de trabalho com apelido e nome completo
- Edite e gerencie seus locais de forma prática
- Visualização em cards intuitivos

**Gestão de Plantões**
- Registre plantões com data, hora e duração (12h ou 24h)
- Defina valor e previsão de pagamento
- Visualize status de pagamento com cores intuitivas
- Lista ordenada por data (mais recentes primeiro)
- Edite ou exclua plantões quando necessário

**Privacidade e Segurança**
- Todos os dados salvos localmente no seu dispositivo
- Nenhuma informação enviada para servidores externos
- Funciona 100% offline
- Seus dados são exclusivamente seus

**Interface**
- Design moderno seguindo Material Design 3
- Cores suaves e profissionais (tema teal)
- Navegação intuitiva e fácil de usar
- Feedback visual em todas as ações

### 💡 Por que usar o Fiz Plantão?

- **Simples**: Interface limpa e direta ao ponto
- **Privado**: Seus dados nunca saem do seu celular
- **Offline**: Funciona sem internet
- **Gratuito**: Sem anúncios ou cobranças ocultas

### 📝 Próximas Atualizações

Estamos trabalhando em:
- Filtros e busca avançada
- Dashboard com estatísticas
- Exportação de dados (PDF/Excel)
- Notificações de pagamentos
- E muito mais!

### 🐛 Encontrou algum problema?

Entre em contato: rodrigolanes@gmail.com

---

**Desenvolvedores e profissionais de saúde, obrigado por escolher o Fiz Plantão!** 💚
