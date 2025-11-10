# Fiz Plantão 🏥

Aplicativo mobile desenvolvido em Flutter para registro e gerenciamento de plantões médicos com persistência local de dados.

## 📋 Sobre o Projeto

O **Fiz Plantão** é uma solução prática para médicos registrarem e acompanharem seus plantões de forma organizada. O aplicativo permite o cadastro completo de informações sobre plantões, incluindo local, horários, duração e previsão de pagamento, com todos os dados salvos localmente usando Hive.

## ✨ Funcionalidades Implementadas

### 🔐 Autenticação e Segurança

- [x] **Firebase Authentication**
  - [x] Login com email e senha
  - [x] Cadastro de novos usuários
  - [x] Google Sign-In (Web e Android)
  - [x] Redefinição de senha via email
  - [x] Logout com limpeza de cache
- [x] **Verificação de Email**
  - [x] Email de verificação obrigatório
  - [x] Verificação automática em tempo real
  - [x] Reenvio de email com cooldown
  - [x] Proteção contra sequestro de contas
- [x] **Isolamento de Dados**
  - [x] Campo userId em todos os modelos
  - [x] Filtros automáticos por usuário
  - [x] Dados privados por conta
- [x] **Telas de Autenticação**
  - [x] Login Screen com validação
  - [x] Cadastro Screen com confirmação de senha
  - [x] Verificação de Email Screen
  - [x] Splash Screen com check de autenticação

### 🏥 Gestão de Locais

- [x] **Cadastro de Locais**
  - [x] Apelido e nome completo
  - [x] Validação de campos obrigatórios
  - [x] Soft delete (exclusão lógica)
- [x] **Listagem de Locais**
  - [x] Visualização em cards
  - [x] Ícones de edição e exclusão
  - [x] Apenas locais ativos são exibidos por padrão
  - [x] Toggle para mostrar/ocultar locais inativos
  - [x] Destaque visual para locais inativos

### 📅 Gestão de Plantões

- [x] **Integração Google Calendar**
  - [x] Sincronização automática de plantões com Google Calendar
  - [x] OAuth 2.0 com Google Sign-In
  - [x] Criação de calendário dedicado "Fiz Plantão"
  - [x] Eventos de plantão com horário, local e valor
  - [x] Eventos de pagamento agrupados por data
  - [x] Atualização inteligente de eventos existentes
  - [x] Detecção e recriação de eventos deletados manualmente
  - [x] Remoção automática ao deletar plantão
- [x] **Cadastro de Plantões**
  - [x] Seleção de local via dropdown
  - [x] Data e hora do plantão
  - [x] Duração (12h ou 24h)
  - [x] Valor e previsão de pagamento
- [x] **Listagem de Plantões**
  - [x] Ordenação por data (mais recentes primeiro)
  - [x] Cards com informações completas
  - [x] Status visual de pagamento
  - [x] Apenas plantões ativos são exibidos
  - [x] Filtro por local (dropdown)
  - [x] Filtro por período de datas
  - [x] Filtro padrão "Próximos" (hoje ou posterior)
  - [x] Contador de resultados filtrados
  - [x] IconButton de filtro compacto
  - [x] Indicador visual de filtro ativo
- [x] **Edição e Exclusão**
  - [x] Editar plantões existentes
  - [x] Soft delete com confirmação
  - [x] Feedback visual

### 📊 Relatórios e Estatísticas

- [x] **Relatório de Plantões por Local**
  - [x] Total geral destacado com quantidade de plantões
  - [x] Toggle "Apenas pagamentos futuros" (ativado por padrão)
  - [x] Listagem de locais ordenada por valor
  - [x] Percentual e barra de progresso por local
  - [x] Detalhes expansíveis:
    - [x] Valor médio por plantão
    - [x] Quantidade total
    - [x] Plantões agrupados por data de pagamento
    - [x] Data/hora e valor de cada plantão

### 💾 Persistência e Sincronização

- [x] **Hive Database**
  - [x] Persistência local offline
  - [x] TypeAdapters para modelos
  - [x] DatabaseService centralizado
  - [x] Soft delete para locais e plantões
  - [x] Locais desativados não aparecem no cadastro de novos plantões
  - [x] Plantões existentes com locais desativados continuam visíveis
- [x] **Supabase Backend**
  - [x] PostgreSQL com Row Level Security
  - [x] Sincronização bidirecional (up e down)
  - [x] Realtime Subscriptions
  - [x] Detecção automática de mudanças remotas
  - [x] Merge inteligente com Last-Write-Wins
  - [x] Sincronização instantânea entre dispositivos
  - [x] Fallback para polling a cada 30 minutos

### 🎨 Interface e UX

- [x] **Splash Screen**
  - [x] Animações de fade e scale
  - [x] Imagem de branding (planta)
  - [x] Navegação automática
- [x] **Ícone do App**
  - [x] Ícone customizado para Android
  - [x] Adaptive icon com background teal
  - [x] Geração automática via flutter_launcher_icons
  - [x] Nome exibido: "Fiz Plantão"

### 🌍 Internacionalização

- [x] **Localização PT-BR**
  - [x] Formatação de datas brasileira
  - [x] Formatação de valores monetários (R$)
  - [x] Intl para localização

## 🚀 Melhorias Futuras

### Recursos Planejados

- [x] **Filtros e Busca**

  - [x] Filtrar plantões por período (com opções rápidas: Próximos, Este mês)
  - [x] Filtrar por local
  - [ ] Filtrar por status de pagamento
  - [ ] Busca por texto

- [ ] **Estatísticas e Relatórios**

  - [x] Relatório de plantões por local
  - [x] Total geral e pagamentos futuros
  - [x] Detalhamento por data de pagamento
  - [ ] Dashboard com totalizadores
  - [ ] Gráficos de rendimentos mensais
  - [ ] Análise de pagamentos (recebidos/pendentes)

- [ ] **Exportação de Dados**

  - [ ] Exportar para PDF
  - [ ] Exportar para Excel/CSV
  - [ ] Compartilhar relatórios

- [ ] **Notificações**

  - [ ] Lembrete de plantões próximos
  - [ ] Alerta de pagamentos atrasados
  - [ ] Notificações programáveis

- [ ] **Funcionalidades Avançadas**

  - [ ] Backup e restore de dados
  - [x] Sincronização em nuvem (Supabase Realtime)
  - [ ] Modo escuro
  - [ ] Múltiplos usuários
  - [ ] Anexar documentos (contratos, comprovantes)
  - [ ] Calculadora de impostos
  - [ ] Observações e notas por plantão

- [ ] **UX/UI**
  - [ ] Onboarding para novos usuários
  - [ ] Tour guiado das funcionalidades
  - [ ] Atalhos e gestos
  - [ ] Personalização de cores/temas

## 🛠️ Tecnologias

- **Flutter 3.35.6** - Framework multiplataforma
- **Dart 3.9.2** - Linguagem de programação
- **Supabase** - Backend as a Service
  - PostgreSQL - Banco de dados relacional
  - Auth - Autenticação (email/senha e Google OAuth)
  - Realtime - Sincronização em tempo real
  - Row Level Security - Segurança a nível de linha
- **Hive 2.2.3** - Cache e persistência local
- **Intl** - Internacionalização e formatação (pt_BR)
- **flutter_launcher_icons** - Geração automática de ícones
- **Material Design 3** - Design system

## 💻 Ambiente de Desenvolvimento

### Requisitos de Sistema

**Flutter SDK**
- Versão: 3.35.6 (canal stable)
- Dart SDK: 3.9.2
- Constraint: `>=3.5.0 <4.0.0`

**Android Development**
- Android SDK: Platform API 34 (Android 14)
- Android SDK Build-Tools: 34.0.0
- Gradle: 8.11
- Java/JDK: 17 ou superior
- Kotlin: Plugin aplicado via Gradle

**Google Cloud Services**
- Firebase: 13.6.0
- Google Services Plugin: 4.4.2

**IDE Recomendadas**
- Android Studio Arctic Fox ou superior
- Visual Studio Code com extensões:
  - Flutter
  - Dart
  - Flutter Intl (para internacionalização)

**Ferramentas de Build**
- Git 2.x
- PowerShell (Windows) ou Bash (Linux/Mac)

### Verificar Ambiente

Execute os seguintes comandos para verificar se seu ambiente está configurado:

```bash
# Verificar Flutter
flutter --version
flutter doctor -v

# Verificar Dart
dart --version

# Verificar Java (deve ser 17+)
java -version

# Verificar variáveis de ambiente (opcional)
echo $ANDROID_HOME    # Linux/Mac
echo %ANDROID_HOME%   # Windows CMD
$env:ANDROID_HOME     # Windows PowerShell
```

**Saída esperada do `flutter doctor`:**
```
✓ Flutter (Channel stable, 3.35.6)
✓ Android toolchain - develop for Android devices (Android SDK version 34.0.0)
✓ Chrome - develop for the web
✓ Android Studio (version 2024.x)
✓ VS Code (version 1.x)
✓ Connected device
✓ Network resources
```

### Configuração Inicial

1. **Instalar Flutter SDK**
   ```bash
   # Baixar de https://flutter.dev/docs/get-started/install
   # Adicionar ao PATH do sistema
   ```

2. **Instalar Android Studio**
   ```bash
   # Baixar de https://developer.android.com/studio
   # Instalar Android SDK Platform 34
   # Instalar Android SDK Build-Tools
   ```

3. **Configurar variáveis de ambiente**
   ```bash
   # Windows (PowerShell)
   $env:ANDROID_HOME = "C:\Users\<seu-usuario>\AppData\Local\Android\Sdk"
   $env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
   
   # Linux/Mac (Bash)
   export ANDROID_HOME=$HOME/Android/Sdk
   export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
   ```

4. **Aceitar licenças Android**
   ```bash
   flutter doctor --android-licenses
   ```

### Dependências do Projeto

**Core**
- `flutter_localizations` (SDK) - Internacionalização
- `cupertino_icons: ^1.0.8` - Ícones iOS

**Persistência**
- `hive: ^2.2.3` - Database NoSQL local
- `hive_flutter: ^1.1.0` - Integração Flutter
- `path_provider: ^2.1.5` - Caminhos do sistema

**Backend & Auth**
- `supabase_flutter: ^2.8.0` - Backend (PostgreSQL + Auth + Realtime)
- `google_sign_in: ^6.2.2` - OAuth Google
- `googleapis: ^13.2.0` - Google Calendar API
- `extension_google_sign_in_as_googleapis_auth: ^2.0.12` - Bridge APIs

**Utilidades**
- `intl: ^0.20.2` - Formatação pt_BR
- `connectivity_plus: ^6.0.5` - Status de rede
- `uuid: ^4.5.1` - Geração de IDs únicos
- `logger: ^2.5.0` - Logs estruturados

**Dev Dependencies**
- `flutter_lints: ^5.0.0` - Linting
- `hive_generator: ^2.0.1` - Code generation
- `build_runner: ^2.4.13` - Build system
- `flutter_launcher_icons: ^0.14.4` - Geração de ícones

### Instalação do Projeto

```bash
# 1. Clonar repositório
git clone https://github.com/rodrigolanes/fiz_plantao.git
cd fiz_plantao

# 2. Instalar dependências
flutter pub get

# 3. Gerar código Hive (TypeAdapters)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Gerar ícones da aplicação (opcional)
dart run flutter_launcher_icons

# 5. Configurar secrets (copiar exemplos)
# Supabase: criar lib/config/supabase_config.dart com suas credenciais
# Android: criar android/key.properties para build release
# Google: adicionar android/app/google-services.json

# 6. Executar em modo debug
flutter run

# 7. Build release (local)
flutter build apk --split-per-abi
# ou
flutter build appbundle --release
```

### Troubleshooting Comum

**Erro: "Unable to locate Android SDK"**
```bash
# Configurar ANDROID_HOME
flutter config --android-sdk <caminho-do-sdk>
```

**Erro: "Gradle sync failed"**
```bash
# Limpar cache e rebuild
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ..
flutter run
```

**Erro: "CocoaPods not installed" (iOS/macOS)**
```bash
sudo gem install cocoapods
pod setup
```

**Erro: Build runner conflitos**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

**Erro: "Waiting for another flutter command"**
```bash
# Remover lock file
# Windows
del "%USERPROFILE%\.flutter_tool_state"
# Linux/Mac
rm ~/.flutter_tool_state
```

### Estrutura de Secrets

O projeto utiliza os seguintes arquivos de configuração que **NÃO** devem ser commitados:

**`lib/config/supabase_config.dart`**
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://seu-projeto.supabase.co';
  static const String supabaseAnonKey = 'sua-anon-key-aqui';
  static const String googleWebClientId = 'seu-web-client-id.apps.googleusercontent.com';
}
```

**`android/key.properties`**
```properties
storePassword=sua-senha-keystore
keyPassword=sua-senha-key
keyAlias=upload
storeFile=../upload-keystore.jks
```

**`android/app/google-services.json`**
```json
{
  "project_info": {
    "project_id": "seu-projeto-id"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abc...",
        "android_client_info": {
          "package_name": "br.com.rodrigolanes.fizplantao"
        }
      },
      "oauth_client": [
        {
          "client_id": "seu-web-client-id.apps.googleusercontent.com",
          "client_type": 3
        }
      ]
    }
  ]
}
```

**GitHub Secrets (para CI/CD)**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_SERVICES_JSON` (base64 encoded)
- `KEYSTORE_BASE64`
- `KEY_STORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`

## 🌐 Desenvolvimento em Diferentes Ambientes

### Build Local vs CI/CD

Este projeto foi configurado para funcionar em dois cenários:

**🏠 Em Casa (Build Local)**
- Build local funciona normalmente com configurações padrão do Flutter
- Comando: `flutter build appbundle --release` ou `flutter run`
- Repositórios: Google Maven e Maven Central padrão
- JDK: Detectado automaticamente pelo sistema

**🏢 Na Empresa (Apenas Desenvolvimento)**
- **Não é necessário fazer build na empresa**
- Apenas desenvolva e faça push para GitHub
- GitHub Actions faz todo o build e deploy automaticamente
- Se houver problemas com SSL corporativo, apenas trabalhe no código - o CI/CD resolve

### Deploy Automático

Todo push para a branch `main` aciona automaticamente:
1. ✅ Build do APK e AAB via GitHub Actions
2. ✅ Incremento automático da versão (se configurado)
3. ✅ Criação de release notes
4. ✅ Publicação de artefatos

**Importante**: Sempre incremente a versão no `pubspec.yaml` antes de fazer push para `main`.

### Pacotes Principais

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Persistência Local
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.5
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  google_sign_in: ^6.2.2
  # Internacionalização
  intl: ^0.19.0
  # Network
  connectivity_plus: ^6.0.5

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.13
  flutter_launcher_icons: ^0.14.4
```

## 📱 Estrutura do Aplicativo

```
Splash Screen
├── Logo animada (planta)
├── Nome do app
├── Verificação de autenticação
└── Redirecionamento (Login ou ListaPlantões)

Login Screen
├── Formulário de email/senha
├── Botão "Entrar"
├── Botão "Entrar com Google"
├── Link "Esqueci minha senha"
└── Link "Cadastre-se"

Cadastro Screen
├── Formulário de email/senha
├── Confirmação de senha
├── Botão "Cadastrar"
├── Botão "Entrar com Google"
└── Envio automático de email de verificação

Verificação de Email Screen
├── Ícone e instruções
├── Email do usuário
├── Verificação automática (3s)
├── Botão "Reenviar email" (cooldown 60s)
├── Botão "Cancelar e voltar" (logout)
└── Alerta de segurança

Tela Principal (Listagem de Plantões)
├── AppBar: "Fiz Plantão" + Gerenciar Locais
├── Área de Filtros
│   ├── Dropdown: Filtrar por Local
│   ├── Botão: Filtrar por Período (Próximos/Personalizado)
│   └── Contador e botão Limpar (quando filtros ativos)
├── Botão "Novo Plantão" (flutuante)
└── Lista de Cards (ordenados por data)
    └── Card do Plantão
        ├── Local (apelido e nome)
        ├── Data e hora formatadas
        ├── Duração (12h/24h)
        ├── Valor (R$)
        ├── Status de pagamento (colorido)
        └── Ícones de edição e exclusão

Tela de Cadastro/Edição de Plantão
├── Dropdown: Local (com botão gerenciar)
├── Campo: Data e Hora
├── Seletor: Duração (12h/24h)
├── Campo: Valor (R$)
├── Campo: Previsão de Pagamento
└── Botões: Salvar/Cancelar

Tela de Listagem de Locais
├── AppBar: "Locais"
├── Botão "Novo Local" (flutuante)
└── Lista de Cards
    └── Card do Local
        ├── Apelido
        ├── Nome completo
        └── Ícones de edição e exclusão

Tela de Cadastro/Edição de Local
├── Campo: Apelido (obrigatório)
├── Campo: Nome Completo (obrigatório)
└── Botões: Salvar/Cancelar
```

## 🚀 Como Executar

### Pré-requisitos

- Flutter SDK 3.x instalado
- Android Studio ou VS Code
- Emulador Android ou dispositivo físico

### Instalação

```bash
# Clone o repositório
git clone https://github.com/rodrigolanes/fiz_plantao.git
cd fiz_plantao

# Instale as dependências
flutter pub get

# Gere os adapters do Hive
flutter pub run build_runner build

# Execute o app
flutter run
```

### Gerar APK para Distribuição

```bash
# APK único (maior tamanho)
flutter build apk

# APKs separados por arquitetura (recomendado)
flutter build apk --split-per-abi
```

Os APKs estarão em `build/app/outputs/flutter-apk/`

**Importante:** Ao atualizar o app, incremente a versão no `pubspec.yaml`:

```yaml
version: 1.0.1+2 # formato: versionName+versionCode
```

## 📝 Modelo de Dados

### Local

| Campo        | Tipo     | Descrição                           |
| ------------ | -------- | ----------------------------------- |
| id           | String   | Identificador único (UUID)          |
| apelido      | String   | Nome curto (ex: HSL)                |
| nome         | String   | Nome completo do local              |
| userId       | String   | ID do usuário proprietário          |
| ativo        | bool     | Status (true=ativo, false=excluído) |
| criadoEm     | DateTime | Data de criação do registro         |
| atualizadoEm | DateTime | Data da última atualização          |

**Anotações Hive:** `@HiveType(typeId: 0)` com `@HiveField` em cada campo.

### Plantão

| Campo             | Tipo     | Descrição                            |
| ----------------- | -------- | ------------------------------------ |
| id                | String   | Identificador único (UUID)           |
| local             | Local    | Objeto Local completo                |
| dataHora          | DateTime | Data e hora do plantão               |
| duracao           | Duracao  | Enum: dozehoras ou vinteequatrohoras |
| valor             | double   | Valor do pagamento (R$)              |
| previsaoPagamento | DateTime | Data prevista para pagamento         |
| userId            | String   | ID do usuário proprietário           |
| ativo             | bool     | Status (true=ativo, false=excluído)  |
| criadoEm          | DateTime | Data de criação do registro          |
| atualizadoEm      | DateTime | Data da última atualização           |

**Anotações Hive:** `@HiveType(typeId: 1)` com `@HiveField` em cada campo.

### DatabaseService

Serviço centralizado para operações CRUD:

```dart
// Locais
DatabaseService.getLocaisAtivos()           // Lista locais ativos
DatabaseService.saveLocal(local)            // Salva/atualiza local
DatabaseService.deleteLocal(localId)        // Soft delete

// Plantões
DatabaseService.getPlantoesAtivos()         // Lista plantões ativos
DatabaseService.savePlantao(plantao)        // Salva/atualiza plantão
DatabaseService.deletePlantao(plantaoId)    // Soft delete
```

**Soft Delete:** Registros não são removidos fisicamente, apenas marcados como `ativo = false`. Locais desativados não aparecem no dropdown para novos plantões, mas plantões existentes com locais desativados continuam visíveis preservando o histórico.

## 🎨 Design

O aplicativo segue **Material Design 3**, proporcionando uma interface moderna e intuitiva:

- **Cores principais:** Teal (#00897B)
- **Tipografia:** Roboto (padrão Material)
- **Ícones:** Material Icons + ícone customizado
- **Splash Screen:** Animações suaves com imagem de branding
- **Layout responsivo:** Cards e listas adaptáveis

## 🏗️ Arquitetura

```
lib/
├── main.dart                      # Entry point + Firebase init
├── firebase_options.dart          # Configuração Firebase (gerado)
├── models/                        # Modelos de dados
│   ├── local.dart                 # @HiveType(typeId: 0) + userId
│   ├── local.g.dart               # TypeAdapter gerado
│   ├── plantao.dart               # @HiveType(typeId: 1) + userId
│   └── plantao.g.dart             # TypeAdapter gerado
├── screens/                       # Telas do app
│   ├── splash_screen.dart         # Splash + auth check
│   ├── login_screen.dart          # Login email/Google
│   ├── cadastro_screen.dart       # Cadastro de usuário
│   ├── verificacao_email_screen.dart # Verificação obrigatória
│   ├── lista_plantoes_screen.dart # Tela principal
│   ├── cadastro_plantao_screen.dart
│   ├── lista_locais_screen.dart
│   └── cadastro_local_screen.dart
├── services/                      # Camada de serviços
│   ├── auth_service.dart          # Autenticação Firebase
│   └── database_service.dart      # CRUD com filtro userId
└── widgets/                       # Widgets reutilizáveis

assets/
└── images/
    └── plant.png                  # Logo/branding

android/
└── app/
    ├── src/main/
    │   ├── AndroidManifest.xml    # Label: "Fiz Plantão"
    │   └── res/mipmap-*/          # Ícones gerados
    └── build.gradle.kts           # Config Android
```

### Padrões Adotados

- **Soft Delete:** Exclusão lógica via flag `ativo`
- **Locais Inativos:** Não aparecem para novos cadastros, mas plantões existentes os mantêm visíveis
- **Filtros em Memória:** Aplicados diretamente na lista sem queries adicionais
- **Filtro Padrão:** "Próximos" mostra plantões de hoje em diante
- **Type-safe Enums:** `Duracao` para duração de plantões
- **DateTime Formatting:** Intl para formatação brasileira
- **Currency Formatting:** `NumberFormat.currency(locale: 'pt_BR')`
- **Timestamp IDs:** `DateTime.now().millisecondsSinceEpoch.toString()`
- **Hive Boxes:** `locais` e `plantoes` como boxes separados
- **StatefulWidgets:** Para telas com interação
- **Material 3:** Design system consistente

## 📄 Licença

Este projeto está sob a licença MIT.

## 👨‍💻 Desenvolvedor

**Rodrigo Lanes**

- GitHub: [@rodrigolanes](https://github.com/rodrigolanes)

**Status do Projeto:** ✅ MVP Funcional com Autenticação e Sincronização em Tempo Real

**Versão Atual:** 1.3.3+17

## 🧩 Símbolos Nativos (Android)

Para melhorar os relatórios de falhas/ANRs no Google Play Console, o app agora embute símbolos nativos no App Bundle.

- Configuração: já adicionada em `android/app/build.gradle.kts` com `ndk { debugSymbolLevel = "FULL" }` no buildType `release`.
- Gerar AAB com símbolos embutidos:
  ```bash
  flutter clean
  flutter pub get
  flutter build appbundle --release
  ```
- Onde verificar: no Play Console, em “App bundle explorer” do release, o item "Native debug symbols" deve aparecer como “Included”.
- Upload manual (se necessário): após o build, o zip de símbolos costuma estar em:
  - `android/app/build/outputs/native-debug-symbols/release/native-debug-symbols.zip`
  Faça upload em “Android vitals → Native crash symbols”.

Opcional (Dart stack traces):
- Para facilitar a de-ofuscação de stack traces Dart, gere símbolos de Dart também:
  ```bash
  flutter build appbundle --release --split-debug-info=build/symbols
  ```
  Guarde a pasta `build/symbols/` para simbolicar rastros de erro Dart fora do Play Console.

## 🔧 Upgrade Técnico

Esta seção documenta o processo de upgrade de SDK/dependências realizado e as diretrizes para futuros updates.

### Estratégia Adotada

1. Manter a constraint do Dart/Flutter flexível dentro da major: `sdk: '>=3.5.0 <4.0.0'`.
2. Atualizar dependências somente dentro de versões compatíveis evitando quebrar o build.
3. Priorizar estabilidade sobre últimas versões quando pacotes exigem SDK superior.

### Passos Executados

1. Coletado ambiente: `flutter --version` e `dart --version`.
2. Listado pacotes desatualizados com `flutter pub outdated`.
3. Ajustado `pubspec.yaml`:
   - `intl` mantido em `^0.19.0` (travado por `flutter_localizations`).
   - `flutter_lints` revertido para `^5.0.0` por exigir SDK mais novo na v6.
   - Adicionados pacotes de persistência: `hive`, `hive_flutter`, `path_provider`, `hive_generator`, `build_runner`.
4. Rodado `flutter pub get` para sincronizar dependências.
5. Corrigidos erros de análise (parâmetros inválidos e propriedades de cor) e eliminados avisos de async context.

### Diretrizes Futuras de Upgrade

- Antes de subir a major do Flutter/Dart, rodar:
  ```bash
  flutter pub outdated --mode=null-safety
  flutter analyze
  flutter test
  ```
- Se `intl` exigir upgrade (ex.: >=0.20.x), verificar compatibilidade com `flutter_localizations`.
- Atualizar `flutter_lints` para v6 somente após confirmar suporte do SDK (ex.: Flutter >=3.24.x hipotético).
- Após qualquer mudança em modelos Hive, sempre rodar:
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- Manter registro de alterações na seção de Changelog (a ser criada).

### Checklist de Upgrade

- [x] Revisar constraints do SDK
- [x] Atualizar dependências seguras
- [x] Rodar `flutter pub get`
- [x] Rodar `flutter analyze` e resolver problemas
- [ ] Rodar `flutter test` (pendente: adicionar testes)
- [ ] Atualizar versão no `pubspec.yaml` (ex.: `1.0.1+2` após novo release)
- [ ] Atualizar Changelog

### Próximos Passos

1. Adicionar testes básicos (ex.: validação de formatação de valores, soft delete).
2. Criar script de verificação automática de integridade (`make` ou `melos` futuro).
3. Separar camadas para facilitar upgrades (ex.: abstrair Hive para outra implementação).

---

```

```
