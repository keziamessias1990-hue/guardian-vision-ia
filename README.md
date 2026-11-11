# Guardian Vision IA — Sprint 0

Monorepositório inicial: **Guardian Pais** e **Guardian Kids** (Flutter), API **NestJS** e espaço para painel administrativo. Apenas dados fictícios; não há monitoramento real, pagamentos ou tratamento de conversas de terceiros.

## Pré-requisitos
- Flutter SDK estável instalado e no PATH (`flutter doctor`)
- Node.js LTS (20 ou 22) e npm
- VS Code com extensões **Flutter**, **Dart** e **ESLint** (opcional)
- Android Studio + Android SDK/emulador para Android
- Para iOS: macOS, Xcode, simulador e CocoaPods configurados

## Configuração do Flutter no macOS
Se o comando `flutter` não existir, instale o SDK e configure o PATH:

```bash
# no terminal
cd ~
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git ~/flutter
```

Edite o arquivo de configuração do shell:

```bash
nano ~/.zshrc
```

Adicione esta linha:

```bash
export PATH="$HOME/flutter/bin:$PATH"
```

Salve e recarregue:

```bash
source ~/.zshrc
flutter --version
flutter doctor
```

Se o `flutter doctor` mostrar problemas:
- instale o **Android Studio** e o **Android SDK**
- aceite as licenças do Android: `flutter doctor --android-licenses`
- instale o **Xcode** + **simulador iOS** para macOS
- instale **CocoaPods**: `sudo gem install cocoapods`

## 1. API (terminal VS Code)
```bash
cd backend
npm install
npm run start:dev
```
Abra http://localhost:3000/api/health e espere `{"status":"ok","service":"guardian-api"}`.

## 2. App Guardian Pais
```bash
cd apps/guardian_pais
flutter pub get
flutter analyze
flutter test
flutter run
```

## 3. App Guardian Kids
```bash
cd apps/guardian_kids
flutter pub get
flutter analyze
flutter test
flutter run
```

## 4. Gerar as pastas nativas dos aplicativos
O SDK Flutter gera os projetos Android/iOS no seu computador. Os arquivos `lib/` já estão preparados. **Execute uma vez em cada pasta**:

```bash
cd apps/guardian_pais
flutter create --platforms=android,ios --project-name guardian_pais .
flutter pub get
flutter run
```

Em outro terminal:

```bash
cd apps/guardian_kids
flutter create --platforms=android,ios --project-name guardian_kids .
flutter pub get
flutter run
```

Se quiser escolher o dispositivo manualmente:

```bash
flutter devices
flutter run -d "iPhone 17 Pro"
# ou use o device id retornado por flutter devices
```

Para abrir o simulador iOS no macOS:

```bash
open -a Simulator
```

Para Android emulador:

```bash
flutter emulators
flutter emulators --launch <id_do_emulador>
```

Para listar os dispositivos: `flutter devices`. Para Android emulador, use `flutter emulators` e `flutter emulators --launch <id>`.

> **Importante:** o comando `flutter create` gera os diretórios `android/` e `ios/`, que não acompanham este ZIP porque o Flutter SDK não está instalado no ambiente de geração. Ele preserva os arquivos existentes em `lib/`. Se o Flutter perguntar sobre sobrescrita, não substitua os arquivos Dart deste projeto.

## 5. Testes
```bash
cd backend && npm test
cd apps/guardian_pais && flutter test
cd apps/guardian_kids && flutter test
```

## 6. Verificação rápida do projeto
```bash
cd apps/guardian_pais && flutter analyze && flutter test && flutter run
cd apps/guardian_kids && flutter analyze && flutter test && flutter run
```

## Endereços para integração futura
- Android Emulator → backend no host: `http://10.0.2.2:3000`
- iOS Simulator → backend no host: `http://localhost:3000`
- Dispositivo físico → IP local do computador (somente em rede de desenvolvimento)

Nesta Sprint 0 os apps mostram **dados demonstrativos locais** e **não precisam da API para abrir**. A integração autenticada será feita nas próximas sprints.

## Organização
- `apps/guardian_pais`: tela inicial e navegação demonstrativa
- `apps/guardian_kids`: tela inicial, análise simulada de mensagem fictícia e ajuda
- `backend`: NestJS, `/api/health` e testes básicos
- `admin_web`: reservado para Next.js, sem instalação nesta etapa
- `docs`: decisões, limites e backlog

## Segurança e privacidade
Sem contas reais, sem persistência de dados infantis, sem leitura de chats externos, sem cobrança real. A análise de demonstração é uma regra local ilustrativa, **não é um detector validado de grooming**. Revisão jurídica, RIPD e políticas das lojas continuam como bloqueios para testes com dados reais e publicação comercial.

End
