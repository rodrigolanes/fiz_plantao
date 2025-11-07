# Configuração de Secrets do GitHub para Firebase

## Passo a Passo

### 1. Obter o conteúdo do google-services.json

No seu computador local:

```powershell
# Windows PowerShell
Get-Content android\app\google-services.json | Set-Clipboard
```

Isso copia o conteúdo completo do arquivo para a área de transferência.

### 2. Adicionar Secret no GitHub

1. Acesse: https://github.com/rodrigolanes/fiz_plantao/settings/secrets/actions

2. Clique em **"New repository secret"**

3. Preencha:
   - **Name:** `GOOGLE_SERVICES_JSON`
   - **Value:** Cole o conteúdo copiado (Ctrl+V)

4. Clique em **"Add secret"**

### 3. Verificar Secrets Existentes

Certifique-se de ter TODOS estes secrets configurados:

✅ `KEYSTORE_BASE64` - Keystore de assinatura (base64)
✅ `KEYSTORE_PASSWORD` - Senha do keystore
✅ `KEY_PASSWORD` - Senha da chave
✅ `KEY_ALIAS` - Alias da chave
✅ `SERVICE_ACCOUNT_JSON` - Service account do Google Play
✅ `GOOGLE_SERVICES_JSON` - **[NOVO]** Configuração do Firebase

### 4. Fazer novo deploy

Depois de adicionar o secret:

```bash
# Fazer commit da correção dos workflows
git add .github/workflows/
git commit -m "fix: adicionar google-services.json ao CI/CD"
git push origin develop
```

O GitHub Actions irá rodar novamente com o arquivo Firebase configurado! ✅

## Formato esperado do GOOGLE_SERVICES_JSON

O conteúdo deve ser o JSON completo, algo assim:

```json
{
  "project_info": {
    "project_number": "642663829595",
    "firebase_url": "https://fiz-plantao.firebaseio.com",
    "project_id": "fiz-plantao",
    "storage_bucket": "fiz-plantao.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:642663829595:android:...",
        "android_client_info": {
          "package_name": "br.com.rodrigolanes.fizplantao"
        }
      },
      ...
    }
  ],
  ...
}
```

## Troubleshooting

### Erro: "Invalid JSON"
- Verifique se copiou o arquivo completo
- Não adicione aspas extras ao colar
- Use o comando PowerShell acima para garantir cópia correta

### Erro: "File still missing"
- Aguarde alguns minutos após adicionar o secret
- Force um novo build: push vazio ou re-run do workflow

### Como re-run do workflow
1. Acesse: https://github.com/rodrigolanes/fiz_plantao/actions
2. Clique no workflow que falhou
3. Clique em **"Re-run all jobs"**
