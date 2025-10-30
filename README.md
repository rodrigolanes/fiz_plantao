# Fiz Plantão 🏥

Aplicativo mobile desenvolvido em Flutter para registro e gerenciamento de plantões médicos.

## 📋 Sobre o Projeto

O **Fiz Plantão** é uma solução prática para médicos registrarem e acompanharem seus plantões de forma organizada. O aplicativo permite o cadastro completo de informações sobre plantões, incluindo local, horários, duração e previsão de pagamento.

## ✨ Funcionalidades

### Funcionalidades Principais

- [ ] **Cadastro de Plantões**
  - [ ] Registro de local do plantão
  - [ ] Data e hora do plantão
  - [ ] Duração do plantão (12h ou 24h)
  - [ ] Data de previsão de pagamento
- [ ] **Listagem de Plantões**
  - [ ] Visualização em cards
  - [ ] Exibição de informações principais em cada card
  - [ ] Botão "Novo" no topo da tela
  - [ ] Ícone de edição (lápis) em cada card
- [ ] **Edição de Plantões**
  - [ ] Editar informações de plantões existentes
  - [ ] Atualização de dados via ícone de lápis

### Funcionalidades Futuras (Backlog)

- [ ] Filtros de busca na listagem
- [ ] Exclusão de plantões
- [ ] Estatísticas e relatórios
- [ ] Notificações de pagamento
- [ ] Histórico de plantões anteriores
- [ ] Exportação de dados
- [ ] Temas claro/escuro
- [ ] Sincronização em nuvem

## 🛠️ Tecnologias

- **Flutter** - Framework principal
- **Dart** - Linguagem de programação
- Android & iOS - Plataformas suportadas

## 📱 Estrutura do Aplicativo

```
Tela Principal (Listagem)
├── Botão "Novo Plantão" (topo)
└── Lista de Cards
    └── Card do Plantão
        ├── Informações do plantão
        └── Ícone de edição (lápis)

Tela de Cadastro/Edição
├── Campo: Local
├── Campo: Data e Hora
├── Seletor: Duração (12h/24h)
├── Campo: Previsão de Pagamento
└── Botões: Salvar/Cancelar
```

## 🚀 Como Executar

### Pré-requisitos

- Flutter SDK instalado
- Android Studio ou VS Code
- Emulador ou dispositivo físico

### Instalação

```bash
# Clone o repositório
git clone https://github.com/rodrigolanes/fiz_plantao.git

# Entre no diretório
cd fiz_plantao

# Instale as dependências
flutter pub get

# Execute o aplicativo
flutter run
```

## 📝 Modelo de Dados

### Plantão

| Campo             | Tipo     | Descrição                    |
| ----------------- | -------- | ---------------------------- |
| id                | String   | Identificador único          |
| local             | String   | Local do plantão             |
| dataHora          | DateTime | Data e hora do plantão       |
| duracao           | Enum     | 12h ou 24h                   |
| previsaoPagamento | DateTime | Data prevista para pagamento |
| criadoEm          | DateTime | Data de criação do registro  |
| atualizadoEm      | DateTime | Data da última atualização   |

## 🎨 Design

O aplicativo segue princípios de Material Design, proporcionando uma interface limpa e intuitiva para facilitar o uso no dia a dia dos profissionais de saúde.

## 📄 Licença

Este projeto está sob a licença MIT.

## 👨‍💻 Desenvolvedor

**Rodrigo Lanes**

---

**Status do Projeto:** 🚧 Em Desenvolvimento
