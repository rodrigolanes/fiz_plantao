# Copilot Instructions - Fiz Plantão

## Contexto do Projeto

**Fiz Plantão** é um aplicativo Flutter para gerenciamento de plantões médicos com persistência local. O app permite cadastrar locais de trabalho e registrar plantões com informações de data, duração, valor e previsão de pagamento.

## Stack Tecnológica

- **Framework:** Flutter 3.x com Dart
- **Banco de Dados:** Hive 2.2.3 (NoSQL local)
- **Internacionalização:** Intl (pt_BR)
- **Design:** Material Design 3 com tema Teal (#00897B)
- **Build Tools:** build_runner, hive_generator, flutter_launcher_icons

## Organização de Trabalho

### Gestão de Tarefas

**SEMPRE usar TODO lists para trabalhos complexos:**

1. **Quando criar TODO list:**

   - Tarefas multi-step ou com múltiplas mudanças em arquivos
   - Quando usuário fornece múltiplas solicitações (numeradas ou separadas por vírgula)
   - Debugging que requer investigação em várias áreas
   - Implementação de novas features que envolvem models, services, screens e widgets
   - Refatorações significativas

2. **Quando NÃO criar TODO list:**

   - Tarefas simples e diretas (uma única mudança)
   - Leitura de arquivos ou buscas
   - Perguntas informacionais
   - Correções de typos ou formatação simples

3. **Workflow obrigatório:**

   - Criar lista ANTES de começar o trabalho
   - Marcar item como "in-progress" ANTES de trabalhar nele
   - Marcar como "completed" IMEDIATAMENTE após concluir
   - Não fazer batch de completions - marcar um por um

4. **Estrutura da lista:**
   - Títulos descritivos e acionáveis (3-7 palavras)
   - Descrição detalhada com arquivos/métodos específicos
   - Status: not-started, in-progress (máximo 1), completed
   - IDs sequenciais começando em 1

**Exemplo:**

```
1. Analisar código existente - not-started
2. Implementar método X no service Y - not-started
3. Criar/atualizar screen Z - not-started
4. Atualizar documentação - not-started
5. Testar e commitar - not-started
```

## Arquitetura e Padrões

### Estrutura de Pastas

```
lib/
├── main.dart                   # Entry point com Hive initialization
├── models/                     # Data models com Hive annotations
├── screens/                    # UI screens (StatefulWidgets)
├── services/                   # Business logic layer
└── widgets/                    # Reusable custom widgets
```

### Padrões Obrigatórios

1. **Soft Delete Pattern**

   - NUNCA delete registros fisicamente do Hive
   - Use flag `bool ativo = true` em todos os modelos
   - Métodos `delete*` devem setar `ativo = false`
   - Queries devem filtrar por `where((item) => item.ativo)`

2. **Hive TypeAdapters**

   - Todos os modelos devem ter `@HiveType(typeId: X)`
   - Cada campo deve ter `@HiveField(N)`
   - Usar typeId únicos: Local=0, Plantao=1
   - Rodar `flutter pub run build_runner build` após mudanças

3. **Database Service Pattern**

   - Toda operação de banco DEVE passar por `DatabaseService`
   - Métodos estáticos e síncronos
   - Nomenclatura: `getNomeAtivos()`, `saveNome()`, `deleteNome()`
   - Box names: lowercase plural (ex: 'locais', 'plantoes')

4. **DateTime Formatting**

   - Sempre usar `intl` para formatação
   - Locale fixo: `'pt_BR'`
   - Formato data: `DateFormat('dd/MM/yyyy', 'pt_BR')`
   - Formato hora: `DateFormat('HH:mm', 'pt_BR')`

5. **Currency Formatting**

   ```dart
   NumberFormat.currency(
     locale: 'pt_BR',
     symbol: 'R\$',
     decimalDigits: 2,
   )
   ```

6. **Model Structure**

   - Todos os modelos têm: `id`, `criadoEm`, `atualizadoEm`, `ativo`
   - ID é timestamp: `DateTime.now().millisecondsSinceEpoch.toString()`
   - Timestamps automáticos no save via `DatabaseService` (atualiza `atualizadoEm`)
   - Incluir `copyWith()` method em todos os modelos

7. **Enums**

   - Usar PascalCase para enum names
   - Valores em lowercase sem separadores
   - Exemplo: `enum Duracao { dozeHoras, vinteQuatroHoras }`
   - Incluir Hive annotations: `@HiveType(typeId: X)` e `@HiveField(N)` em cada valor

8. **Async Context Safety**
   - Capturar `Navigator.of(context)` e `ScaffoldMessenger.of(context)` ANTES de awaits
   - Verificar `if (!mounted) return;` após cada operação async
   - Usar builders como `builder: (_) =>` em dialogs para evitar captura de context

## Convenções de Código

### Nomenclatura

- **Arquivos:** snake_case (ex: `lista_plantoes_screen.dart`)
- **Classes:** PascalCase (ex: `ListaPlantoesScreen`)
- **Variáveis:** camelCase (ex: `dataHora`, `previsaoPagamento`)
- **Constantes:** camelCase (não UPPER_CASE)
- **Português:** Usar português para nomes de variáveis e classes relacionadas ao domínio

### Imports

```dart
// 1. Flutter/Dart imports
import 'package:flutter/material.dart';
import 'dart:async';

// 2. Package imports
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

// 3. Relative imports
import '../models/plantao.dart';
import '../services/database_service.dart';
```

### UI Components

1. **Screens**

   - StatefulWidget quando há interação
   - AppBar com título em português
   - FloatingActionButton para ação primária (ex: "Novo")
   - Usar `ListView.builder` para listas

2. **Forms**

   - TextFormField com validators
   - Validação de campos obrigatórios
   - Feedback com SnackBar após salvar/deletar
   - Confirmação antes de deletar (AlertDialog)

3. **Navegação**

   - `Navigator.push` para telas de cadastro/edição
   - `Navigator.pushReplacement` para SplashScreen
   - Passar objetos via constructor arguments

4. **Colors**

   - Primary: `Colors.teal` ou `Colors.teal[800]`
   - Background: `Colors.teal[50]`
   - Cards: `Colors.white`
   - Erro: `Colors.red`
   - Usar `withOpacity(value)` para transparência (não `withAlpha` ou deprecated `withValues`)

5. **Material Design 3**
   - Usar `WidgetStateProperty` (não deprecated `MaterialStateProperty`)
   - Usar `WidgetState` (não deprecated `MaterialState`)
   - Preferir Material 3 components: `FilledButton`, `OutlinedButton`, etc.

## Regras Específicas

### Ao Criar Novos Modelos

1. Adicionar annotations Hive
2. Incluir campo `bool ativo = true`
3. Incluir timestamps `criadoEm` e `atualizadoEm`
4. Criar métodos no DatabaseService
5. Gerar TypeAdapter: `flutter pub run build_runner build`

### Ao Criar Novas Telas

1. Seguir padrão das telas existentes
2. Usar Material 3 components
3. Implementar validação de formulários
4. Adicionar feedback visual (SnackBar)
5. Tratar casos de lista vazia

### Ao Modificar DatabaseService

1. Métodos de leitura são síncronos, writes são async
2. Retornar List<T>, T ou void (Future<void> para saves)
3. Filtrar por `.where((item) => item.ativo)` em queries
4. Usar `box.put(id, objeto)` para salvar
5. `save*` e `update*` methods já atualizam `atualizadoEm` automaticamente via `copyWith`
6. NUNCA pré-popular dados (seed) - usuário cria manualmente

### Regras de Soft Delete

- Locais desativados (`ativo = false`) NÃO aparecem no dropdown para novos plantões
- Plantões existentes com locais desativados CONTINUAM visíveis
- Ao listar plantões ativos, filtrar apenas `plantao.ativo` (não verificar `plantao.local.ativo`)
- Isso preserva o histórico: plantões antigos mostram o local mesmo que tenha sido desativado

## Testes e Debugging

### Antes de Commitar

- [ ] **Rodar a aplicação** em pelo menos um dispositivo/emulador para validar mudanças
- [ ] **Executar testes** (se existirem): `flutter test`
- [ ] Rodar `flutter analyze` para verificar problemas no código
- [ ] Rodar `flutter pub run build_runner build` se alterou modelos Hive
- [ ] Verificar que dados persistem após restart (se mudou persistência)
- [ ] **Atualizar README.md** com novas funcionalidades ou mudanças relevantes
  - Marcar features implementadas como [x]
  - Adicionar novas seções se necessário
  - Atualizar versão atual no final do documento
- [ ] **Atualizar RELEASE_NOTES.md** com as mudanças da versão
  - Criar nova seção para a versão com data
  - Descrever novidades, melhorias e correções
  - Usar linguagem clara para usuários finais

### Antes de Push para Develop (OBRIGATÓRIO)

- [ ] **SEMPRE incrementar version no pubspec.yaml** antes de fazer push para `develop`
  - Branch `develop` aciona GitHub Actions que faz deploy automático
  - Formato: `MAJOR.MINOR.PATCH+BUILD` (ex: `1.0.0+5`)
  - Incrementar `+BUILD` (versionCode) a cada push
  - Deploy falhará se a versão não for incrementada

### Debug Comum

- **"Box not found":** Verificar se Hive.initFlutter() foi chamado
- **"Type not registered":** Registrar TypeAdapter no main.dart
- **"Bad state: No element":** Lista vazia, usar `.firstWhere(..., orElse: () => null)`
- **Formatação errada:** Verificar locale 'pt_BR' no DateFormat/NumberFormat

## Assets e Recursos

### Ícones do App

- Arquivo fonte: `assets/images/plant.png`
- Config: `flutter_launcher_icons.yaml`
- Gerar: `dart run flutter_launcher_icons`
- Background adaptativo Android: `#00897B`

### Assets no Pubspec

```yaml
flutter:
  assets:
    - assets/images/
```

## Build e Deploy

### Gerar APK

```bash
# APK universal (maior)
flutter build apk

# APKs por arquitetura (recomendado)
flutter build apk --split-per-abi
```

### Versioning

Formato no `pubspec.yaml`: `version: MAJOR.MINOR.PATCH+BUILD`

Exemplo: `1.0.0+1` onde:

- `1.0.0` = versionName (user-facing)
- `+1` = versionCode (internal, Android)

**Incrementar sempre:**

- PATCH (+build): Bug fixes
- MINOR (+build): New features
- MAJOR (+build): Breaking changes

## Melhorias Futuras Planejadas

Ao implementar novas features, considerar:

1. **Filtros:** Adicionar à ListaPlantoesScreen
2. **Dashboard:** Nova screen com estatísticas
3. **Exportação:** PDF/Excel via packages
4. **Notificações:** flutter_local_notifications
5. **Backup:** Cloud sync opcional (Firebase)
6. **Temas:** ThemeData dark/light mode
7. **Onboarding:** Intro screen para novos usuários

## Perguntas Frequentes

**P: Por que soft delete ao invés de delete real?**
R: Para manter histórico, permitir "desfazer" e integridade referencial (Plantoes de Locais deletados).

**P: Por que Hive e não SQLite?**
R: Hive é mais simples, sem SQL, type-safe, e suficiente para este use case.

**P: Por que não usar Provider/Bloc?**
R: Projeto pequeno, setState é suficiente. Considerar state management se crescer.

**P: Posso usar inglês nos nomes?**
R: Preferir português para domínio (Local, Plantao), inglês para técnico (DatabaseService).

## Histórico de Atualizações

### Novembro 2025

- Migração para WidgetStateProperty/WidgetState (Material 3)
- Async context safety implementado (captured navigator/messenger)
- Timestamps automáticos no DatabaseService
- Remoção de seed automático de dados
- Correção de documentação sobre soft delete de locais

### Outubro 2025

- Implementação inicial com Hive
- Soft delete pattern
- Splash screen e ícone customizado
- Localização pt_BR completa

---

**Última atualização:** Novembro 2025
**Versão do projeto:** 1.0.0+1
