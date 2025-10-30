# Fiz Plantão 🏥

Aplicativo mobile desenvolvido em Flutter para registro e gerenciamento de plantões médicos.

## 📋 Sobre o Projeto

O **Fiz Plantão** é uma solução prática para médicos registrarem e acompanharem seus plantões de forma organizada. O aplicativo permite o cadastro completo de informações sobre plantões, incluindo local, horários, duração e previsão de pagamento.

## ✨ Funcionalidades

### Funcionalidades Principais

- [x] **Cadastro de Locais**

  - [x] Cadastro de apelido do local
  - [x] Cadastro de nome completo do local
  - [x] Validação de campos obrigatórios

- [x] **Listagem de Locais**

  - [x] Visualização em cards
  - [x] Exibição de apelido e nome completo
  - [x] Botão "Novo" para adicionar locais
  - [x] Ícones de edição e exclusão em cada card

- [x] **Cadastro de Plantões**
  - [x] Seleção de local via dropdown
  - [x] Data e hora do plantão
  - [x] Duração do plantão (12h ou 24h)

### Funcionalidades Futuras (Backlog)

- [ ] Persistência de dados (banco de dados local)
- [ ] Filtros de busca na listagem
- [ ] Estatísticas e relatórios
- [ ] Gráficos de rendimentos
- [ ] Notificações de pagamento
- [ ] Histórico de plantões anteriores
- [ ] Exportação de dados (PDF/Excel)
- [ ] Temas claro/escuro
- [ ] Sincronização em nuvem
- [ ] Backup automáticomais recentes primeiro)
- [x] **Edição de Plantões**

  - [x] Editar informações de plantões existentes
  - [x] Atualização de dados via ícone de lápis

- [x] **Exclusão de Plantões**
  - [x] Confirmação antes de excluir
  - [x] Feedback visual após exclusão

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

## 📱 Estrutura do Aplicativo

````
Tela Principal (Listagem de Plantões)
├── Botão "Novo Plantão" (flutuante)
└── Lista de Cards
    └── Card do Plantão
        ├── Local (apelido e nome)
        ├── Data e hora do plantão
        ├── Duração (12h/24h)
        ├── Valor
        ├── Status de pagamento (com cor)
        └── Ícones de edição e exclusão

Tela de Cadastro/Edição de Plantão
├── Dropdown: Local (com botão de gerenciar)
├── Campo: Data e Hora
├── Seletor: Duração (12h/24h)
├── Campo: Valor do Pagamento
├── Campo: Previsão de Pagamento
└── Botões: Salvar/Cancelar

Tela de Listagem de Locais
├── Botão "Novo Local" (flutuante)
└── Lista de Cards
    └── Card do Local
        ├── Apelido
        ├── Nome completo
        └── Ícones de edição e exclusão

Tela de Cadastro/Edição de Local
├── Campo: Apelido
├── Campo: Nome Completo
└── Botões: Salvar/Cancelar
``` Campo: Previsão de Pagamento
└── Botões: Salvar/Cancelar
````

## 🚀 Como Executar

### Pré-requisitos

- Flutter SDK instalado

## 📝 Modelo de Dados

### Local

| Campo        | Tipo     | Descrição                   |
| ------------ | -------- | --------------------------- |
| id           | String   | Identificador único         |
| apelido      | String   | Nome curto (ex: HSL)        |
| nome         | String   | Nome completo do local      |
| criadoEm     | DateTime | Data de criação do registro |
| atualizadoEm | DateTime | Data da última atualização  |

### Plantão

| Campo             | Tipo     | Descrição                    |
| ----------------- | -------- | ---------------------------- |
| id                | String   | Identificador único          |
| local             | Local    | Objeto Local completo        |
| dataHora          | DateTime | Data e hora do plantão       |
| duracao           | Enum     | 12h ou 24h                   |
| valor             | Double   | Valor do pagamento (R$)      |
| previsaoPagamento | DateTime | Data prevista para pagamento |
| criadoEm          | DateTime | Data de criação do registro  |
| atualizadoEm      | DateTime | Data da última atualização   |

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
| valor             | Double   | Valor do pagamento (R$)      |
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
```
