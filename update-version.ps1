param(
    [Parameter(Mandatory=$true)]
    [string]$Version  # Formato: 1.1.0+7
)

# Extrair versionName e versionCode
$parts = $Version -split '\+'
if ($parts.Length -ne 2) {
    Write-Host "❌ Formato inválido! Use: X.Y.Z+N (exemplo: 1.1.0+7)" -ForegroundColor Red
    exit 1
}

$versionName = $parts[0]
$versionCode = $parts[1]

Write-Host ""
Write-Host "🚀 Atualizando para versão: $versionName (build $versionCode)" -ForegroundColor Cyan
Write-Host ""

# Atualizar pubspec.yaml
$pubspecPath = "pubspec.yaml"
if (Test-Path $pubspecPath) {
    $pubspecContent = Get-Content $pubspecPath -Raw
    $pubspecContent = $pubspecContent -replace 'version: [\d.+]+', "version: $Version"
    Set-Content -Path $pubspecPath -Value $pubspecContent -NoNewline
    Write-Host "✅ pubspec.yaml atualizado" -ForegroundColor Green
} else {
    Write-Host "❌ pubspec.yaml não encontrado!" -ForegroundColor Red
    exit 1
}

# Atualizar build.gradle.kts
$gradlePath = "android/app/build.gradle.kts"
if (Test-Path $gradlePath) {
    $gradleContent = Get-Content $gradlePath -Raw
    $gradleContent = $gradleContent -replace 'versionCode = \d+', "versionCode = $versionCode"
    $gradleContent = $gradleContent -replace 'versionName = "[\d.]+"', "versionName = `"$versionName`""
    Set-Content -Path $gradlePath -Value $gradleContent -NoNewline
    Write-Host "✅ build.gradle.kts atualizado" -ForegroundColor Green
} else {
    Write-Host "❌ build.gradle.kts não encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Yellow
Write-Host "1. Atualizar RELEASE_NOTES.md com as mudanças desta versão"
Write-Host "2. Atualizar android/release-notes-pt-BR.txt (máximo 500 caracteres)"
Write-Host "3. git add ."
Write-Host "4. git commit -m 'chore: bump version to $Version'"
Write-Host "5. git push origin develop"
Write-Host ""
Write-Host "✨ Versão atualizada com sucesso!" -ForegroundColor Green
