# Configurar Deep Link para Email de Confirmação

## Problema
O email de confirmação do Supabase está redirecionando para `http://localhost:3000` mesmo no mobile.

## Solução

### 1. Configurar Redirect URLs no Supabase Dashboard

Acesse: **Supabase Dashboard** → **Authentication** → **URL Configuration**

#### Adicionar estas URLs em "Redirect URLs":

```
http://localhost:3000/**
br.com.rodrigolanes.fizplantao://**
```

**Importante**: Clique em "Add URL" para cada uma e depois **SAVE**.

### 2. Configurar Site URL (opcional)

Se quiser que o deep link seja o padrão, configure:

- **Site URL**: `br.com.rodrigolanes.fizplantao://login-callback/`

Caso contrário, deixe como `http://localhost:3000` e o app vai usar o `emailRedirectTo` explícito.

### 3. AndroidManifest.xml já configurado

O deep link já está configurado em:
- `android/app/src/main/AndroidManifest.xml`

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data 
        android:scheme="br.com.rodrigolanes.fizplantao"
        android:host="login-callback" />
</intent-filter>
```

### 4. AuthService já configurado

Os métodos já passam o `emailRedirectTo` correto:
- `cadastrar()`: passa deep link no mobile
- `redefinirSenha()`: passa deep link no mobile  
- `enviarEmailVerificacao()`: passa deep link no mobile

## Como testar

1. Configure as Redirect URLs no Supabase Dashboard
2. Rode o app: `flutter run -d RXCX10A7B6A`
3. Cadastre um novo usuário
4. Verifique o email - o link agora deve usar `br.com.rodrigolanes.fizplantao://login-callback/...`
5. Ao clicar no link, o app deve abrir automaticamente

## Troubleshooting

Se o email ainda mostrar `localhost:3000`:
- Confirme que salvou as Redirect URLs no dashboard
- Teste criando um **novo usuário** (emails já enviados usam o redirect antigo)
- Limpe o cache do Supabase: Settings → General → Clear cache
