# Notas de Versão - Fiz Plantão

## Versão 1.0.0 (Build 5) - 7 de novembro de 2025

### ✨ Novidades

**📊 Relatórios e Estatísticas**
- Nova tela de Relatórios acessível pelo ícone de gráfico no menu principal
- Relatório de Plantões por Local com:
  - Total geral destacado com quantidade de plantões
  - Toggle "Apenas pagamentos futuros" (ativado por padrão)
  - Percentual e barra de progresso de cada local em relação ao total
  - Valor médio por plantão
  - Detalhamento expandível com plantões agrupados por data de pagamento
  - Data/hora e valor individual de cada plantão

**🎨 Melhorias de Interface**
- Filtro de período agora é um IconButton compacto
- Indicador visual mostrando período filtrado quando ativo
- Toggle para mostrar/ocultar locais inativos na lista
- Locais inativos com destaque visual diferenciado (badge + cores)

### 🔧 Melhorias Técnicas
- Configurações do VS Code adicionadas ao repositório
- Instruções atualizadas com checklist obrigatório antes de commits
- Versionamento obrigatório antes de push para develop

---

## Versão 1.0.0 (Build 4) - 6 de novembro de 2025

### 🐛 Correções

**Configuração Android**
- Corrigido targetSdk para 34 no AndroidManifest.xml
- Garantida compatibilidade com requisitos da Google Play Store
- Build e deploy via GitHub Actions funcionando corretamente

---

## Versão 1.0.0 (Build 3) - 6 de novembro de 2025

### 🔧 Melhorias Técnicas

**Configuração de Build**
- Definidas configurações explícitas de SDK no build.gradle.kts
- minSdk: 21, targetSdk: 34, compileSdk: 36
- Corrigidas versões para compatibilidade com Play Store

---

## Versão 1.0.0 (Build 2) - 6 de novembro de 2025

### 🔧 Correções Técnicas

**Dependências**
- Corrigida versão do pacote intl para ^0.19.0 (compatibilidade com flutter_localizations)
- Resolvido conflito de dependências no GitHub Actions

**CI/CD**
- Atualizado Flutter para versão 3.27.0 no GitHub Actions
- Configurado deploy automático para teste interno no Google Play

---

## Versão 1.0.0 (Build 1) - 6 de novembro de 2025

### 🎉 Lançamento Inicial

Primeira versão do **Fiz Plantão** - o aplicativo essencial para profissionais de saúde gerenciarem seus plantões de forma simples e organizada.

### ✨ Funcionalidades

**Gestão de Locais**
- Cadastre seus locais de trabalho com apelido e nome completo
- Edite e gerencie seus locais de forma prática
- Visualização em cards intuitivos

**Gestão de Plantões**
- Registre plantões com data, hora e duração (12h ou 24h)
- Defina valor e previsão de pagamento
- Visualize status de pagamento com cores intuitivas
- Lista ordenada por data (mais recentes primeiro)
- Edite ou exclua plantões quando necessário

**Privacidade e Segurança**
- Todos os dados salvos localmente no seu dispositivo
- Nenhuma informação enviada para servidores externos
- Funciona 100% offline
- Seus dados são exclusivamente seus

**Interface**
- Design moderno seguindo Material Design 3
- Cores suaves e profissionais (tema teal)
- Navegação intuitiva e fácil de usar
- Feedback visual em todas as ações

### 💡 Por que usar o Fiz Plantão?

- **Simples**: Interface limpa e direta ao ponto
- **Privado**: Seus dados nunca saem do seu celular
- **Offline**: Funciona sem internet
- **Gratuito**: Sem anúncios ou cobranças ocultas

### 📝 Próximas Atualizações

Estamos trabalhando em:
- Filtros e busca avançada
- Dashboard com estatísticas
- Exportação de dados (PDF/Excel)
- Notificações de pagamentos
- E muito mais!

### 🐛 Encontrou algum problema?

Entre em contato: rodrigolanes@gmail.com

---

**Desenvolvedores e profissionais de saúde, obrigado por escolher o Fiz Plantão!** 💚
