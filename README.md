MARIDO DE ALUGUEL – APLICATIVO MOBILE (FLUTTER + FIREBASE)
==========================================================

Descrição Geral
---------------
O aplicativo Marido de Aluguel facilita o agendamento de serviços residenciais,
conectando clientes e prestadores de serviço em uma plataforma simples e segura.

O app possui dois perfis:

1. Cliente:
   - Solicita serviços.
   - Agenda atendimentos.
   - Consulta histórico.
   - Visualiza detalhes dos serviços.

2. Prestador:
   - Marca suas competências.
   - Define preços personalizados.
   - Recebe chamados pendentes.
   - Aceita ou recusa atendimentos.
   - Gerencia seu perfil, foto, descrição e avaliações.

O backend utiliza Firebase (Firestore, Authentication e Storage).

----------------------------------------------------------

Principais Funcionalidades
--------------------------
Cliente:
- Login e cadastro.
- Listagem de serviços.
- Agendamento.
- Histórico de atendimentos.
- Perfil do usuário.

Prestador:
- Cadastro com opção “Sou prestador de serviços”.
- Configuração das competências.
- Painel de chamados pendentes.
- Aceitar ou recusar solicitações.
- Perfil completo com foto.
- Estatísticas de avaliação e quantidade de serviços realizados.

----------------------------------------------------------

Tecnologias Utilizadas
----------------------
Frontend:
- Flutter 3.x
- Dart
- Provider
- Image Picker
- Firebase Core
- Google Fonts

Backend Firebase:
- Firebase Authentication
- Firebase Firestore
- Firebase Storage

----------------------------------------------------------

Arquitetura do Projeto
----------------------
lib/
 ├── screens/               Telas do aplicativo
 ├── widgets/               Componentes reutilizáveis
 ├── models/                Modelos de dados
 ├── repositories/          Acesso ao Firestore
 ├── state/                 Gerenciamento de estado (AppState)
 ├── theme/                 Tema e fontes
 ├── dev_seed.dart          Seed de dados iniciais
 ├── app.dart               Configurações gerais
 ├── main.dart              Entry point do aplicativo

----------------------------------------------------------

Pré-requisitos
--------------
- Flutter instalado (versão 3.22+)
- Android Studio ou Visual Studio Code
- Emulador Android configurado
- Conta no Firebase

----------------------------------------------------------

Configuração do Firebase
------------------------
1. Criar projeto no Firebase.
2. Ativar:
   - Authentication (Email/Senha)
   - Firestore Database
   - Firebase Storage
3. Baixar:
   - google-services.json → android/app/
   - GoogleService-Info.plist → ios/Runner/
4. Rodar configuração:
   dart run flutterfire_cli configure

----------------------------------------------------------

Como Executar o Projeto
-----------------------
1. Baixar o repositório:
   git clone https://github.com/crucifiedddd/maridodealuguel.git

2. Entrar na pasta:
   cd marido_de_aluguel

3. Instalar dependências:
   flutter pub get

4. Executar:
   flutter run

----------------------------------------------------------

Contas de Teste
----------------
Cliente:
  email: cliente@test.com
  senha: 123456

Prestador:
  email: prestador@test.com
  senha: 123456

----------------------------------------------------------

Créditos
--------
Autor: Jefferson Luis Jacob Junior
Orientador: Carlos Eduardo Iatskiu
Instituição: UniGuairacá
Ano: 2025

Fim do Documento.
----------------------------------------------------------
