# Script para atualizar Release Notes do Google Play

## Uso

Antes de fazer push para `develop` ou criar uma tag de produção, atualize o arquivo de release notes:

```bash
# Edite o arquivo
notepad android\release-notes-pt-BR.txt

# Ou use PowerShell
code android\release-notes-pt-BR.txt
```

## Formato do Arquivo

O arquivo `android/release-notes-pt-BR.txt` deve conter as novidades da versão em **português brasileiro** (máximo 500 caracteres).

### Exemplo:

```
🔐 AUTENTICAÇÃO
• Sistema de login e cadastro
• Google Sign-In integrado
• Verificação de email obrigatória

🎨 MELHORIAS
• Nova interface moderna
• Navegação intuitiva

🛡️ SEGURANÇA
• Dados isolados por usuário
• Proteção contra sequestro de contas
```

## Como funciona

1. **Deploy Automático (develop)**:
   - Push para `develop` → GitHub Actions → Internal Track
   - Release notes do arquivo são enviadas automaticamente

2. **Deploy Manual (produção)**:
   - Criar tag `v1.1.0` → GitHub Actions → Production Track
   - Release notes do arquivo são enviadas automaticamente

## Suporte a Múltiplos Idiomas

Para adicionar outros idiomas, crie arquivos adicionais:

```
android/
├── release-notes-pt-BR.txt  # Português (Brasil)
├── release-notes-en-US.txt  # Inglês (EUA)
└── release-notes-es-ES.txt  # Espanhol
```

O Google Play usará o idioma correspondente para cada usuário.

## Limites do Google Play

- **Máximo:** 500 caracteres por idioma
- **Formato:** Texto simples (sem HTML)
- **Emojis:** ✅ Suportados

## Dicas

✅ **Use emojis** para destacar seções
✅ **Seja conciso** - usuários leem rapidamente
✅ **Destaque benefícios** ao invés de detalhes técnicos
✅ **Mencione correções importantes** de bugs

❌ Evite jargões técnicos
❌ Não use formatação complexa
❌ Não exceda 500 caracteres

## Automatização Futura

### Opção 1: Extrair do RELEASE_NOTES.md

Criar script que extrai as notas da versão atual do `RELEASE_NOTES.md`:

```yaml
- name: Generate Release Notes
  run: |
    # Extrair seção da versão atual
    awk '/^## Versão 1.1.0/,/^## Versão/' RELEASE_NOTES.md \
      | head -n -1 \
      | tail -n +2 \
      > android/release-notes-pt-BR.txt
```

### Opção 2: Usar Git Commit Messages

```yaml
- name: Generate Release Notes from Commits
  run: |
    git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"• %s" \
      > android/release-notes-pt-BR.txt
```

### Opção 3: Template Dinâmico

Criar template com placeholders substituídos pelo CI:

```
🚀 Versão {{VERSION}}

{{HIGHLIGHTS}}

📱 Melhorias e correções disponíveis
```

## Verificação

Antes do deploy, você pode verificar o conteúdo:

```bash
# Windows
type android\release-notes-pt-BR.txt

# PowerShell
Get-Content android\release-notes-pt-BR.txt

# Contar caracteres
(Get-Content android\release-notes-pt-BR.txt -Raw).Length
```

## Troubleshooting

**Problema:** Release notes não aparecem no Google Play

**Soluções:**
1. Verificar que o arquivo está em `android/release-notes-pt-BR.txt`
2. Confirmar que tem menos de 500 caracteres
3. Verificar logs do GitHub Actions
4. Aguardar algumas horas (Google Play pode demorar a processar)

**Problema:** Caracteres especiais aparecem incorretos

**Solução:** Salvar arquivo com encoding UTF-8 (sem BOM)

```powershell
# PowerShell: Salvar com UTF-8
$content = Get-Content android\release-notes-pt-BR.txt
[System.IO.File]::WriteAllText("android\release-notes-pt-BR.txt", $content, [System.Text.Encoding]::UTF8)
```
