# Fiz Plantão 🏥

Aplicativo mobile desenvolvido em Flutter para registro e gerenciamento de plantões médicos com persistência local de dados.

## 📋 Sobre o Projeto

O **Fiz Plantão** é uma solução prática para médicos registrarem e acompanharem seus plantões de forma organizada. O aplicativo permite o cadastro completo de informações sobre plantões, incluindo local, horários, duração e previsão de pagamento, com todos os dados salvos localmente usando Hive.

## ✨ Funcionalidades Implementadas

### 🏥 Gestão de Locais

- [x] **Cadastro de Locais**
  - [x] Apelido e nome completo
  - [x] Validação de campos obrigatórios
  - [x] Soft delete (exclusão lógica)
- [x] **Listagem de Locais**
  - [x] Visualização em cards
  - [x] Ícones de edição e exclusão
  - [x] Apenas locais ativos são exibidos

### 📅 Gestão de Plantões

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
- [x] **Edição e Exclusão**
  - [x] Editar plantões existentes
  - [x] Soft delete com confirmação
  - [x] Feedback visual

### 💾 Persistência de Dados

- [x] **Hive Database**
  - [x] Persistência local offline
  - [x] TypeAdapters para modelos
  - [x] DatabaseService centralizado
  - [x] Soft delete para locais e plantões
  - [x] Locais desativados não aparecem no cadastro de novos plantões
  - [x] Plantões existentes com locais desativados continuam visíveis

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

- [ ] **Filtros e Busca**

  - [ ] Filtrar plantões por período
  - [ ] Filtrar por local
  - [ ] Filtrar por status de pagamento
  - [ ] Busca por texto

- [ ] **Estatísticas e Relatórios**

  - [ ] Dashboard com totalizadores
  - [ ] Gráficos de rendimentos mensais
  - [ ] Relatório de plantões por local
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
  - [ ] Sincronização em nuvem (opcional)
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

- **Flutter 3.x** - Framework multiplataforma
- **Dart** - Linguagem de programação
- **Hive 2.2.3** - Banco de dados NoSQL local
- **Intl** - Internacionalização e formatação (pt_BR)
- **flutter_launcher_icons** - Geração automática de ícones
- **Material Design 3** - Design system

### Pacotes Principais

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  intl: ^0.19.0

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
└── Indicador de carregamento

Tela Principal (Listagem de Plantões)
├── AppBar: "Fiz Plantão"
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
├── main.dart                      # Entry point
├── models/                        # Modelos de dados
│   ├── local.dart                 # @HiveType(typeId: 0)
│   ├── local.g.dart               # TypeAdapter gerado
│   ├── plantao.dart               # @HiveType(typeId: 1)
│   └── plantao.g.dart             # TypeAdapter gerado
├── screens/                       # Telas do app
│   ├── splash_screen.dart         # Splash animado
│   ├── lista_plantoes_screen.dart # Tela principal
│   ├── cadastro_plantao_screen.dart
│   ├── lista_locais_screen.dart
│   └── cadastro_local_screen.dart
├── services/                      # Camada de serviços
│   └── database_service.dart      # CRUD centralizado
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
- **Type-safe Enums:** `Duracao` para duração de plantões
- **DateTime Formatting:** Intl para formatação brasileira
- **Currency Formatting:** `NumberFormat.currency(locale: 'pt_BR')`
- **UUID:** Identificadores únicos para registros
- **Hive Boxes:** `locais` e `plantoes` como boxes separados
- **StatefulWidgets:** Para telas com interação
- **Material 3:** Design system consistente

## 📄 Licença

Este projeto está sob a licença MIT.

## 👨‍💻 Desenvolvedor

**Rodrigo Lanes**

- GitHub: [@rodrigolanes](https://github.com/rodrigolanes)

---

**Status do Projeto:** ✅ MVP Funcional | 🚧 Melhorias Contínuas

**Versão Atual:** 1.0.0+1

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
