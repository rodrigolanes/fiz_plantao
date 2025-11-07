# Script para Atualizar Versão do App

## Uso

Sempre que for lançar uma nova versão, você deve atualizar em **DOIS lugares**:

### 1. pubspec.yaml

```yaml
version: 1.1.0+7  # formato: versionName+versionCode
```

### 2. android/app/build.gradle.kts

```kotlin
versionCode = 7        // Mesmo número após o + no pubspec.yaml
versionName = "1.1.0"  // Mesmo número antes do + no pubspec.yaml
```

## Script PowerShell para Automação

Salve como `update-version.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$Version  # Formato: 1.1.0+7
)

# Extrair versionName e versionCode
$parts = $Version -split '\+'
$versionName = $parts[0]
$versionCode = $parts[1]

Write-Host "Atualizando para versão: $versionName (build $versionCode)" -ForegroundColor Cyan

# Atualizar pubspec.yaml
$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw
$pubspecContent = $pubspecContent -replace 'version: [\d.+]+', "version: $Version"
Set-Content -Path $pubspecPath -Value $pubspecContent
Write-Host "✅ pubspec.yaml atualizado" -ForegroundColor Green

# Atualizar build.gradle.kts
$gradlePath = "android/app/build.gradle.kts"
$gradleContent = Get-Content $gradlePath -Raw
$gradleContent = $gradleContent -replace 'versionCode = \d+', "versionCode = $versionCode"
$gradleContent = $gradleContent -replace 'versionName = "[\d.]+"', "versionName = `"$versionName`""
Set-Content -Path $gradlePath -Value $gradleContent
Write-Host "✅ build.gradle.kts atualizado" -ForegroundColor Green

Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "1. Atualizar RELEASE_NOTES.md com as mudanças"
Write-Host "2. Atualizar android/release-notes-pt-BR.txt (max 500 chars)"
Write-Host "3. git add ."
Write-Host "4. git commit -m 'chore: bump version to $Version'"
Write-Host "5. git push origin develop"
```

## Como Usar o Script

```powershell
# Exemplo: Atualizar para v1.2.0 build 8
.\update-version.ps1 -Version "1.2.0+8"
```

## Checklist de Release

Antes de fazer push para `develop`:

- [ ] Executar script `update-version.ps1` com nova versão
- [ ] Atualizar `RELEASE_NOTES.md` com novas funcionalidades
- [ ] Atualizar `android/release-notes-pt-BR.txt` (Google Play)
- [ ] Testar build local: `flutter build appbundle --release`
- [ ] Commit: `git commit -m "chore: bump version to X.Y.Z+N"`
- [ ] Push: `git push origin develop`
- [ ] Aguardar CI/CD completar
- [ ] Verificar no Google Play Console

## Regras de Versionamento

### versionName (Semantic Versioning)

```
MAJOR.MINOR.PATCH

MAJOR: Mudanças incompatíveis na API/UX (ex: 1.0.0 → 2.0.0)
MINOR: Novas funcionalidades compatíveis (ex: 1.0.0 → 1.1.0)
PATCH: Correções de bugs (ex: 1.1.0 → 1.1.1)
```

### versionCode (Incremental)

- **Sempre incrementar** a cada release
- **Nunca reutilizar** um versionCode
- Google Play rejeita se versionCode não for maior que o anterior

### Exemplos

```
1.0.0+1  → Primeiro lançamento
1.0.1+2  → Bug fix
1.1.0+3  → Nova funcionalidade
1.1.1+4  → Bug fix
2.0.0+5  → Breaking changes
```

## Troubleshooting

### Erro: "Version code has already been used"

Você tentou usar um versionCode que já existe no Google Play.

**Solução:** Incrementar versionCode para o próximo número disponível.

### Erro: "Target SDK is too low"

O targetSdk no build.gradle.kts está incorreto.

**Solução:** Garantir que `targetSdk = 34` (ou superior conforme requisitos do Google Play).

### Versões desincronizadas

Se pubspec.yaml e build.gradle.kts tiverem versões diferentes:

```powershell
# Verificar versão atual
Select-String -Path pubspec.yaml -Pattern "version:"
Select-String -Path android/app/build.gradle.kts -Pattern "versionCode|versionName"

# Corrigir manualmente ou usar o script
.\update-version.ps1 -Version "X.Y.Z+N"
```

## Histórico de Versões

| Versão | Build | Data | Descrição |
|--------|-------|------|-----------|
| 1.1.0  | 7     | 07/11/2025 | Autenticação Firebase + Verificação Email |
| 1.0.0  | 6     | 07/11/2025 | Relatórios e filtros |
| 1.0.0  | 5     | 07/11/2025 | Melhorias UI |
| 1.0.0  | 4     | 06/11/2025 | Config Android |
| 1.0.0  | 3     | 06/11/2025 | Build fixes |
| 1.0.0  | 2     | 06/11/2025 | Dependências |
| 1.0.0  | 1     | 06/11/2025 | Lançamento inicial |
