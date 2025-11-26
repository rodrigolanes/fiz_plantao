# Deploy para Produção - Fiz Plantão

## 📋 Visão Geral

O deploy para produção utiliza **tags Git** para versionamento automático e extrai as notas de versão do `RELEASE_NOTES.md`.

## 🏗️ Workflows Disponíveis

### 1. Deploy Internal Testing (`deploy-internal.yml`)
- **Trigger:** Manual via workflow_dispatch
- **Destino:** Play Store Internal Track
- **Versionamento:** Incremento manual (patch/minor/major)
- **Uso:** Testes internos antes de produção

### 2. Deploy Production (`deploy-playstore.yml`)
- **Trigger:** Tag Git (`v*.*.*`) ou Manual
- **Destino:** Play Store Production Track
- **Versionamento:** Baseado na tag Git
- **Uso:** Release final para usuários

## 🚀 Processo de Deploy para Produção

### Passo 1: Preparar a Versão

1. **Atualizar código e documentação:**
   ```bash
   # Implementar features/correções
   git add .
   git commit -m "feat: nova funcionalidade X"
   ```

2. **Atualizar RELEASE_NOTES.md:**
   ```markdown
   ## Versão 1.8.0 (Build TBD) - 25 de novembro de 2025

   ### 🐛 Correções de Interface

   **Atualização de Lista Após Edição**
   - Corrigido problema crítico de não-atualização da lista
   - Fluxo corrigido: agora salva primeiro, depois atualiza
   ```

3. **Commitar e fazer push:**
   ```bash
   git add RELEASE_NOTES.md README.md
   git commit -m "docs: preparar versão 1.8.0"
   git push origin main
   ```

### Passo 2: Criar Tag de Versão

```bash
# Criar tag anotada (IMPORTANTE: use v antes do número)
git tag -a v1.8.0 -m "Release 1.8.0 - Correções de interface"

# Enviar tag para GitHub (isso dispara o workflow automaticamente)
git push origin v1.8.0
```

### Passo 3: Workflow Automático

O GitHub Actions fará automaticamente:

1. ✅ **Extrai versão da tag** (`v1.8.0` → `1.8.0`)
2. ✅ **Incrementa build number** (lê do `pubspec.yaml` atual)
3. ✅ **Atualiza `pubspec.yaml`** com nova versão completa (`1.8.0+35`)
4. ✅ **Extrai notas de versão** do `RELEASE_NOTES.md`
5. ✅ **Gera `android/release-notes-pt-BR.txt`** (máximo 500 caracteres)
6. ✅ **Executa testes** (`flutter test`)
7. ✅ **Build do AAB** (`flutter build appbundle --release`)
8. ✅ **Gera símbolos de debug nativos**
9. ✅ **Upload para Play Store Production**
10. ✅ **Commit automático** da versão atualizada
11. ✅ **Cria GitHub Release** com AAB anexado

## 🎯 Deploy Manual (Alternativo)

Se preferir disparar manualmente sem criar tag:

1. Acesse: [Deploy Production Workflow](https://github.com/rodrigolanes/fiz_plantao/actions/workflows/deploy-playstore.yml)
2. Clique em **"Run workflow"**
3. Digite a tag desejada (ex: `v1.8.0`)
4. Clique em **"Run workflow"**

## 📝 Formato das Notas de Versão

### RELEASE_NOTES.md

```markdown
## Versão X.Y.Z (Build TBD) - DD de mês de YYYY

### 🐛 Categoria (emoji + título)

**Subtítulo em Negrito**
- Item de lista com descrição
- Outro item

**Outro Subtítulo**
- Mais informações
```

### Conversão Automática para Play Store

O workflow extrai automaticamente:
- ✅ Seção da versão especificada
- ✅ Subtítulos (### → •)
- ✅ Itens de lista (- → -)
- ✅ Texto em negrito
- ✅ Trunca para 500 caracteres (limite da Play Store)

**Exemplo de saída:**
```
• Correções de Interface

Atualização de Lista Após Edição
  - Corrigido problema crítico de não-atualização
  - Fluxo corrigido: agora salva primeiro
  - Interface sempre sincronizada
```

## 🔧 Configuração Necessária

### Secrets do GitHub

Certifique-se de ter configurados:
- `GH_TOKEN` - Token com permissão para push
- `KEYSTORE_BASE64` - Keystore Android em base64
- `KEYSTORE_PASSWORD` - Senha do keystore
- `KEY_PASSWORD` - Senha da key
- `KEY_ALIAS` - Alias da key
- `SERVICE_ACCOUNT_JSON` - JSON da service account do Google Play
- `SUPABASE_URL` - URL do Supabase
- `SUPABASE_ANON_KEY` - Chave anon do Supabase
- `GOOGLE_WEB_CLIENT_ID` - Client ID do Google OAuth
- `GOOGLE_SERVICES_JSON` - google-services.json em base64

## ⚠️ Importante

### Versionamento Semântico

Siga o padrão **MAJOR.MINOR.PATCH**:
- **MAJOR** (v2.0.0): Mudanças incompatíveis
- **MINOR** (v1.8.0): Novas funcionalidades compatíveis
- **PATCH** (v1.7.1): Correções de bugs

### Build Number

- É **incrementado automaticamente** pelo workflow
- Nunca edite manualmente o build number no `pubspec.yaml`
- Cada deploy (internal ou production) incrementa o build

### Checklist Antes do Deploy

- [ ] Código revisado e testado
- [ ] `RELEASE_NOTES.md` atualizado com a nova versão
- [ ] `README.md` atualizado (se necessário)
- [ ] Testes locais passando (`flutter test`)
- [ ] Build local funcional (`flutter build appbundle --release`)
- [ ] Commits feitos e push para `main`
- [ ] Tag criada com formato correto (`v1.8.0`)

## 🔄 Fluxo Completo Recomendado

### Para Testes Internos (Internal Testing)

```bash
# 1. Desenvolver e commitar
git add .
git commit -m "feat: nova funcionalidade"
git push origin main

# 2. Disparar workflow manual
# GitHub Actions → Deploy Internal Testing → Run workflow → Escolher patch/minor/major
```

### Para Produção (Production)

```bash
# 1. Garantir que versão internal está estável
# Testes no Internal Track da Play Store

# 2. Atualizar documentação
vim RELEASE_NOTES.md  # Adicionar notas da versão
git add RELEASE_NOTES.md
git commit -m "docs: release notes v1.8.0"
git push origin main

# 3. Criar e enviar tag
git tag -a v1.8.0 -m "Release 1.8.0"
git push origin v1.8.0

# 4. Aguardar workflow automático
# GitHub Actions executará automaticamente
```

## 📊 Monitoramento

### GitHub Actions
- Acompanhe em: https://github.com/rodrigolanes/fiz_plantao/actions
- Logs completos de cada step
- Artefatos gerados (AAB, símbolos)

### Play Console
- Verifique em: https://play.google.com/console
- Status do release
- Relatórios de crash
- Métricas de distribuição

## 🐛 Troubleshooting

### Tag já existe
```bash
# Deletar tag local e remota
git tag -d v1.8.0
git push origin :refs/tags/v1.8.0

# Criar novamente
git tag -a v1.8.0 -m "Release 1.8.0"
git push origin v1.8.0
```

### Workflow não disparou
- Verifique se a tag tem formato correto (`v*.*.*`)
- Confirme que a tag foi enviada para o repositório remoto
- Verifique logs do GitHub Actions

### Notas de versão não encontradas
- Certifique-se que `RELEASE_NOTES.md` existe
- Verifique formato: `## Versão X.Y.Z`
- Versão na tag deve corresponder à versão nas notas

---

**Desenvolvido com ❤️ para Fiz Plantão**
