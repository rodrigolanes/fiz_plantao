# Notas de Versão - Fiz Plantão

## Versão 1.6.0 (Build 29) - 11 de novembro de 2025

### 📄 Exportação de Relatórios em PDF

**Nova funcionalidade de exportação**
- Geração de relatórios profissionais em formato PDF
- Botão de exportação na tela de relatórios
- Dados agrupados por local e data de pagamento
- Filtros aplicados automaticamente ao PDF (local e período)
- Compartilhamento direto do arquivo gerado
- Layout otimizado para impressão

**Estrutura do relatório**
- Tabela resumo com total por local
- Listagem detalhada de plantões
- Valores formatados em R$ (pt_BR)
- Datas formatadas no padrão brasileiro
- Status visual com badges coloridas

### 🔄 Sincronização Aprimorada

**Carregamento automático de dados**
- Sincronização automática após login bem-sucedido
- Dados carregados via Splash Screen antes de mostrar interface
- Correção de bug: locais e plantões agora aparecem imediatamente após login
- Garantia de dados atualizados em todos os dispositivos

**Fluxo de autenticação melhorado**
- Login com email redireciona para Splash Screen
- Google Sign-In redireciona para Splash Screen
- Verificação de email redireciona para Splash Screen
- Carregamento de dados antes de exibir tela principal

### 🎨 Melhorias de Interface

**Interface simplificada**
- Removidos botões de edição/exclusão dos cards de plantões
- Card agora responde ao toque para editar (mais intuitivo)
- Botão de exclusão movido para a tela de edição (AppBar)
- Interface mais limpa e moderna

**Relatórios redesenhados**
- Removidas métricas desnecessárias (média e percentual)
- Badges de status substituem ícones (mais claras)
- Badge "Pago" com fundo verde e borda verde
- Badge "Pendente" com fundo laranja e borda laranja
- Layout de 3 colunas: Data/Hora | Status | Valor
- Ícone de filtro colorido e visível

### 🔧 Melhorias Técnicas

**CI/CD Aprimorado**
- Geração automática de símbolos de depuração nativos
- Compatibilidade com múltiplas versões do Android Gradle Plugin
- Fallback inteligente para localizar bibliotecas nativas
- Resolve avisos do Google Play Console sobre símbolos faltantes
- Deploy mais confiável para produção

**Otimizações de código**
- Métodos de exclusão otimizados
- Melhor organização de métodos nos services
- Código mais manutenível e testável

### 🐛 Correções

- **Sincronização**: Dados agora carregam corretamente após login
- **Filtros**: Ícone de filtro agora é visível nos relatórios
- **Navegação**: Fluxo de autenticação corrigido para carregar dados
- **CI/CD**: Símbolos nativos agora são incluídos no build

---

## Versão 1.4.2 (Build 20) - 10 de novembro de 2025

### 🔧 Melhorias Técnicas

**Autenticação Google**
- Removido `signOut()` forçado antes do login para evitar perda de tokens
- Adicionados logs detalhados para debug do fluxo OAuth
- Corrigido problema de "Token Google ausente" em alguns cenários
- Melhor tratamento de cancelamento de login

**CI/CD**
- Geração automática do `supabase_config.dart` no GitHub Actions
- Campo `enableGoogleIntegrations` adicionado ao config gerado
- Suporte completo a secrets do Supabase (URL, Anon Key, Google Client ID)

**Documentação**
- Instruções de configuração de secrets do GitHub
- Processo de deploy simplificado

---

## Versão 1.4.0 (Build 18) - 8 de novembro de 2025

### 📅 Integração Google Calendar

**Sincronização Automática de Plantões**
- Calendário dedicado "Fiz Plantão" criado automaticamente
- Eventos de plantão com informações completas:
  - Horário de início e término baseado na duração
  - Local (apelido e nome completo)
  - Valor do plantão formatado em R$
  - Data prevista de pagamento
  - Status de pagamento (✅ Pago / ⏳ Pendente)
- Lembretes automáticos: 1 hora e 1 dia antes do plantão
- Cor personalizada (azul) para fácil identificação

**Eventos de Pagamento Agrupados**
- Um único evento por data de pagamento prevista
- Lista todos os plantões com pagamento na mesma data
- Mostra total a receber e valores individuais
- Atualização automática quando plantões são marcados como pagos
- Evento de dia inteiro no calendário
- Cor personalizada (verde) para pagamentos

**Gerenciamento Inteligente de Eventos**
- Criação automática ao salvar novo plantão
- Atualização de eventos existentes ao editar plantão
- Detecção de eventos deletados manualmente no Google Calendar
- Recriação automática de eventos deletados quando plantão é editado
- Remoção de evento ao deletar plantão
- Verificação de status (cancelled) para eventos deletados
- Sincronização dos IDs de eventos no Hive e Supabase

**OAuth e Segurança**
- Autenticação via Google Sign-In
- SHA-1 fingerprint configurado para Android
- Firebase + Google Cloud Console integrados
- Permissão apenas para escopo de calendário (CalendarApi.calendarScope)
- Configuração documentada em `GOOGLE_CALENDAR_SETUP.md`

**Correções de Timezone**
- Ajuste automático de 3 horas para compensar interpretação UTC
- Eventos aparecem no horário correto (Brasil UTC-3)
- Datas de pagamento sem horário (formato dd/MM/yyyy)

**Logs e Debug**
- Sistema centralizado de logging com `LogService.calendar()`
- Logs detalhados de criação, atualização e remoção de eventos
- Identificação de IDs de eventos e calendários nos logs
- Rastreamento de falhas e exceções

### 🗄️ Banco de Dados

**Novos Campos no Modelo Plantao**
- `calendarEventId`: ID do evento do plantão no Google Calendar
- `calendarPaymentEventId`: ID do evento de pagamento
- Campos opcionais (nullable) para compatibilidade
- Migração SQL criada para Supabase
- Índices para otimizar consultas

**SyncService Atualizado**
- Sincronização bidirecional dos IDs de eventos do Calendar
- Campos preservados em insert, update e realtime
- Compatibilidade com dados antigos (sem IDs de eventos)

### 🧪 Dados de Teste

**Locais Atualizados**
- Hospital São Lucas (HSL)
- CTICor (CTICor)
- Hospital da Mulher Heloneida Studart (HMHS)

**Plantões de Teste**
- Datas espalhadas entre outubro e dezembro de 2025
- Mix de plantões pagos e pendentes
- Diferentes valores e durações (12h e 24h)
- Datas de pagamento variadas para testar agrupamento

### 📚 Documentação

**Novo Arquivo: GOOGLE_CALENDAR_SETUP.md**
- Guia completo de configuração OAuth em português
- Comandos para gerar SHA-1 fingerprint
- Passo a passo no Firebase Console
- Configuração do Google Cloud Console
- Troubleshooting para erro 12500

---

## Versão 1.3.3 (Build 17) - 8 de novembro de 2025

### 🧪 Qualidade de Testes

**Correções de Testes**
- Adicionado override de `userId` em `AuthService` para compatibilidade com testes
- Setter `AuthService.userId` permite mocking de usuário durante testes
- Método `clearTestOverride()` para limpeza entre testes
- Inicialização do Hive com diretório temporário nos testes (sem depender de path_provider)

**Cobertura Completa**
- 39 testes unitários executados com sucesso
- DatabaseService completamente testado (ordenação, filtros, soft delete)
- Models validados (copyWith, timestamps, campos opcionais)
- CI/CD integrado: testes obrigatórios antes de build

### 🔧 DevOps

**Build e Deploy**
- Workflow migrado para rodar em branch `main` ao invés de `develop`
- Trigger automático em commits com mudanças de código
- Filtros para ignorar commits de documentação/estilo
- Builds bloqueados se testes falharem
- Symbols nativos Android inclusos no AAB (melhor crash reporting)

---

## Versão 1.3.2 (Build 16) - 8 de novembro de 2025

### 🧩 Símbolos Nativos

**Android Debug Symbols**
- Configurado `ndk { debugSymbolLevel = "FULL" }` no build.gradle.kts
- Símbolos nativos automaticamente inclusos no App Bundle
- Melhora significativa nos relatórios de crash e ANR no Play Console
- Opcional: Dart split-debug-info com `--split-debug-info=build/symbols`

**Documentação**
- README atualizado com guia de configuração
- Instruções de build e verificação no App Bundle Explorer
- Passos para upload manual se necessário

---

## Versão 1.3.1 (Build 15) - 8 de novembro de 2025

### 💰 Pagamento em Massa

**Toggle de Pagamento por Data**
- Marque todos os plantões de uma data como pagos com um único toggle
- Diálogo de confirmação mostrando quantos plantões serão afetados
- Indicadores visuais: ícone de check verde e texto riscado para plantões pagos
- Aviso quando alguns plantões já foram pagos
- Função de desmarcar pagamento também disponível

**Relatórios Aprimorados**
- Visualização clara do status de pagamento por data
- Facilita reconciliação bancária
- Totais pagos/pendentes sempre visíveis

### 🧪 Qualidade e Testes

**Testes Unitários**
- 36 testes implementados para models (Local e Plantao)
- Cobertura completa de construtores, copyWith() e validações
- Testes executados automaticamente no CI antes de cada deploy
- Build só acontece se todos os testes passarem

**Melhorias no Gerador de Dados de Teste**
- Correção de IDs para usar UUID padrão
- Limpeza completa (delete físico) de dados locais e remotos
- Geração de massa de dados realista com status de pagamento variado

### 🔧 DevOps

**CI/CD**
- Testes automatizados no GitHub Actions
- Relatório de cobertura enviado para Codecov
- Deploy bloqueado se testes falharem
- Workflow otimizado para feedback rápido

---

## Versão 1.3.0 (Build 14) - 8 de novembro de 2025

### ✨ Rastreamento de Pagamentos

**Campo Pago**
- Novo campo para marcar plantões como pagos
- Switch intuitivo para alternar status do pagamento
- Badge visual na lista de plantões
- Sincronização bidirecional do status
- Campo preservado durante versões antigas do app
- Persistência local via Hive e remota via Supabase

**Novos Filtros**
- Filtro por status de pagamento na lista
- Totais separados para valores pagos/pendentes
- Relatórios com segmentação por status de pagamento

### 🔧 Melhorias Técnicas

**Supabase**
- Migração SQL para adicionar coluna pago
- Índice otimizado para consultas por status
- Campo com valor padrão false para compatibilidade
- RLS policies mantidas (apenas dados do próprio usuário)

**Sync Service**
- Tratamento resiliente do campo pago
- Suporte a versões antigas do app
- Conversão inteligente de tipos
- Download/Upload bidirecional do status

---

## Versão 1.2.5 (Build 13) - 8 de novembro de 2025

### ⚡ Sincronização em Tempo Real

**Supabase Realtime**
- Implementada sincronização instantânea via Supabase Realtime
- Mudanças em outros dispositivos são recebidas automaticamente
- Estratégia Last-Write-Wins: timestamp mais recente prevalece
- Handlers implementados para Locais e Plantões com merge inteligente

**Como Funciona**
- Ao modificar dados em qualquer dispositivo, todos os outros sincronizam automaticamente
- Não é mais necessário aguardar 30 minutos ou sincronizar manualmente
- Funciona mesmo com o app em segundo plano
- Conflitos resolvidos automaticamente pelo timestamp de atualização

---

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
