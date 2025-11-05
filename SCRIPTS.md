# Scripts Úteis - Fiz Plantão

Comandos úteis para desenvolvimento e deploy do projeto.

## 🔧 Desenvolvimento

### Setup Inicial

```bash
# Instalar dependências
flutter pub get

# Gerar adapters do Hive
flutter pub run build_runner build --delete-conflicting-outputs

# Analisar código
flutter analyze
```

### Build Local

```bash
# Debug (desenvolvimento)
flutter run

# Debug em dispositivo específico
flutter run -d <device_id>

# Release local (teste)
flutter build apk --release

# Release por arquitetura (recomendado)
flutter build apk --split-per-abi

# AppBundle (Google Play)
flutter build appbundle --release
```

### Testes

```bash
# Rodar todos os testes
flutter test

# Com cobertura
flutter test --coverage

# Teste específico
flutter test test/nome_test.dart
```

## 🔐 Setup de Deploy (Primeira Vez)

### 1. Gerar Keystore

```bash
# Criar keystore de upload
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Mover para pasta android
mv upload-keystore.jks android/
```

### 2. Converter Keystore para Base64 (GitHub Secrets)

**Windows PowerShell:**

```powershell
cd android
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
# Conteúdo copiado para área de transferência
```

**Linux/Mac:**

```bash
cd android
base64 upload-keystore.jks | pbcopy  # Mac
base64 upload-keystore.jks | xclip -selection clipboard  # Linux
```

### 3. Criar key.properties

```bash
# Copiar template
cp android/key.properties.example android/key.properties

# Editar com suas credenciais
code android/key.properties
```

## 🚀 Deploy

### Deploy para Internal Testing (develop)

```bash
# Garantir que está na branch develop
git checkout develop

# Fazer alterações
git add .
git commit -m "feat: nova funcionalidade"

# Push - dispara workflow automaticamente
git push origin develop
```

### Deploy para Produção (tag)

```bash
# 1. Atualizar versão no pubspec.yaml
# Editar: version: 1.0.1+2
code pubspec.yaml

# 2. Commit da versão
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.1"

# 3. Push para main
git push origin main

# 4. Criar e push tag
git tag v1.0.1
git push origin v1.0.1

# Workflow de produção disparará automaticamente
```

### Verificar Status do Deploy

```bash
# Ver workflows no GitHub
open https://github.com/rodrigolanes/fiz_plantao/actions

# Ou usar GitHub CLI
gh run list
gh run view <run-id>
gh run watch <run-id>
```

## 🎨 Ativos e Ícones

### Gerar ícones do app

```bash
# Após editar assets/images/plant.png
dart run flutter_launcher_icons

# Verificar resultado
flutter run
```

### Adicionar novos assets

```bash
# 1. Adicionar arquivo em assets/
# 2. Atualizar pubspec.yaml na seção flutter: assets:
# 3. Rodar
flutter pub get
```

## 🔍 Análise e Qualidade

### Análise estática

```bash
# Análise padrão
flutter analyze

# Com métricas detalhadas
flutter analyze --write=analysis.txt

# Fix automático de alguns problemas
dart fix --apply
```

### Formatar código

```bash
# Formatar todos os arquivos
dart format .

# Formatar arquivo específico
dart format lib/screens/lista_plantoes_screen.dart

# Verificar sem aplicar
dart format --set-exit-if-changed .
```

## 📦 Versionamento

### Incrementar versão

```bash
# Formato: MAJOR.MINOR.PATCH+BUILD
# Exemplo no pubspec.yaml: version: 1.0.1+2

# Bug fix (patch)
# 1.0.0+1 → 1.0.1+2

# Nova feature (minor)
# 1.0.1+2 → 1.1.0+3

# Breaking change (major)
# 1.1.0+3 → 2.0.0+4
```

### Obter versão atual

```bash
# Via pubspec
grep version pubspec.yaml

# Via Flutter
flutter --version
```

## 🗂️ Git Workflows

### Branch Strategy

```bash
# Feature
git checkout -b feature/filtros
git push origin feature/filtros
# PR para develop

# Bugfix
git checkout -b fix/issue-123
git push origin fix/issue-123
# PR para develop ou main

# Hotfix
git checkout -b hotfix/critical-bug
git push origin hotfix/critical-bug
# PR direto para main
```

### Limpar builds

```bash
# Flutter clean
flutter clean

# Rebuild completo
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build appbundle --release
```

## 🐛 Debug

### Logs em produção

```bash
# Conectar dispositivo e ver logs
flutter logs

# Logs de crash (após install)
adb logcat | grep -i flutter

# Symbolicate crash reports
flutter symbolize --input=<crash.txt> --debug-info=<app.android-arm.symbols>
```

### Performance profiling

```bash
# Rodar em modo profile
flutter run --profile

# Com DevTools
flutter run --profile
# DevTools abrirá automaticamente
```

## 📱 Dispositivos

### Listar dispositivos

```bash
# Todos conectados
flutter devices

# Apenas Android
adb devices

# Emuladores disponíveis
flutter emulators
```

### Iniciar emulador

```bash
# Listar
flutter emulators

# Iniciar específico
flutter emulators --launch <emulator_id>

# Iniciar qualquer
flutter emulators --launch
```

## 🔄 Atualizar Dependências

### Verificar atualizações

```bash
# Ver outdated packages
flutter pub outdated

# Modo null-safety
flutter pub outdated --mode=null-safety
```

### Atualizar packages

```bash
# Atualizar respeitando constraints
flutter pub upgrade

# Atualizar major versions (cuidado!)
flutter pub upgrade --major-versions

# Atualizar package específico
flutter pub upgrade <package_name>
```

### Após atualizar Hive models

```bash
# Regenerar adapters
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📊 Relatórios

### Bundle size analysis

```bash
# Gerar build com size analysis
flutter build appbundle --analyze-size

# Ver detalhes
flutter build appbundle --analyze-size --target-platform android-arm64
```

### Dependency tree

```bash
# Árvore de dependências
flutter pub deps

# Apenas diretas
flutter pub deps --style=compact
```

---

**Dica:** Adicione aliases no seu shell para comandos frequentes:

```bash
# ~/.bashrc ou ~/.zshrc
alias frun='flutter run'
alias fbuild='flutter build appbundle --release'
alias fclean='flutter clean && flutter pub get'
alias fanalyze='flutter analyze'
alias ftest='flutter test --coverage'
```
