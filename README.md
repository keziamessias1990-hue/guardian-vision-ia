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

## 1. API (backend NestJS)

No terminal do projeto:

```bash
cd /Users/keziamessias/guardian-vision-ia/backend
npm install
npm run start:dev
```

Se a porta 3000 estiver ocupada, o backend pode iniciar em `3001`. Neste caso, teste com:

```bash
curl http://localhost:3001/api/health
```

Verifique a API local:

```bash
curl http://localhost:3000/api/health || curl http://localhost:3001/api/health
```

Resposta esperada:

```json
{"status":"ok","service":"guardian-api"}
```

Endpoints principais desta sprint:

```bash
curl http://localhost:3000/api/parents || curl http://localhost:3001/api/parents
curl http://localhost:3000/api/children || curl http://localhost:3001/api/children
curl http://localhost:3000/api/alerts || curl http://localhost:3001/api/alerts
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mae@guardianvision.local","password":"guardian123"}'
```

## 2. App Guardian Pais

No terminal:

```bash
cd /Users/keziamessias/guardian-vision-ia/apps/guardian_pais
flutter pub get
flutter analyze
flutter test
flutter run
```

Se quiser rodar em um emulador iOS ou Android específico:

```bash
flutter devices
flutter run -d "iPhone 17 Pro"
flutter run -d emulator-5554
```

## 3. App Guardian Kids

No terminal:

```bash
cd /Users/keziamessias/guardian-vision-ia/apps/guardian_kids
flutter pub get
flutter analyze
flutter test
flutter run
```

Para abrir em um simulador concreto:

```bash
flutter devices
flutter run -d "iPhone 17 Pro"
```

## 4. Testes do backend

```bash
cd /Users/keziamessias/guardian-vision-ia/backend
npm test
```

## 5. Testes dos apps Flutter

```bash
cd /Users/keziamessias/guardian-vision-ia/apps/guardian_pais
flutter test

cd /Users/keziamessias/guardian-vision-ia/apps/guardian_kids
flutter test
```

## 6. Fluxo completo de execução (ordem recomendada)

Abra 3 terminais:

Terminal 1 — backend:

```bash
cd /Users/keziamessias/guardian-vision-ia/backend
npm install
PORT=3001 npm run start:dev
```

Terminal 2 — app Guardian Pais:

```bash
cd /Users/keziamessias/guardian-vision-ia/apps/guardian_pais
flutter pub get
flutter run -d "iPhone 17 Pro"
```

Terminal 3 — app Guardian Kids:

```bash
cd /Users/keziamessias/guardian-vision-ia/apps/guardian_kids
flutter pub get
flutter run -d "iPhone 17 Pro"
```

## 7. Endereços úteis para integração local

- Android Emulator → backend: `http://10.0.2.2:3000/api` ou `http://10.0.2.2:3001/api`
- iOS Simulator → backend: `http://localhost:3000/api` ou `http://localhost:3001/api`
- Dispositivo físico → use o IP do notebook/PC na rede local

## 8. Observações de segurança e privacidade

- O projeto continua em fase de protótipo.
- Não deve haver coleta automática de conversas externas.
- O app só deve consumir eventos estruturados e mínimos do backend.
- Ainda não há autenticação real, persistência de dados infantis ou integração com lojas.

## Organização
- `apps/guardian_pais`: app parental com dashboard e integração inicial com a API
- `apps/guardian_kids`: app da criança em fluxo de demonstração
- `backend`: API NestJS com contrato local inicial e testes
- `admin_web`: espaço reservado para painel administrativo
- `docs`: documentação e roteiro de desenvolvimento

## Segurança e privacidade
Sem contas reais, sem persistência de dados infantis, sem leitura de chats externos, sem cobrança real. A análise de demonstração é uma regra local ilustrativa, **não é um detector validado de grooming**. Revisão jurídica, RIPD e políticas das lojas continuam como bloqueios para testes com dados reais e publicação comercial.

End
