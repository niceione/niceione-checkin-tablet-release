# NiceIone 체크인 태블릿 배포

NiceIone 객실 체크인 전용 Android 태블릿의 공개 배포 저장소입니다.

- 최신 운영 버전: [`v1.0.2`](https://github.com/niceione/niceione-checkin-tablet-release/releases/latest)
- 대상 기기: NTP-10, Android 11 (실기기 1대 선행 검증 필수)
- 앱 패키지: `kr.co.niceione.checkintablet`
- Device Owner 관리자: `kr.co.niceione.checkintablet.NiceIoneDeviceAdminReceiver`

## 설치 전에 반드시 확인

1. Device Owner 최초 등록 전 필요한 기존 앱, 설정 및 자료를 백업합니다.
2. 먼저 시험 기기 1대만 등록하고 결제·재부팅·키오스크 동작을 확인한 후 나머지 기기를 진행합니다.
3. 공장 초기화 후에도 KIS Agent 패키지 `kr.co.kisvan.andagent`가 남는지 확인합니다. Agent가 없다면 나머지 기기를 진행하지 말고 KIS Agent 무인 설치 방식을 먼저 준비합니다.
4. NTP-10에서 QR 등록 화면이 열리지 않으면 아래 USB BAT 방식을 사용합니다.

NTP-10은 출고 시기와 펌웨어에 따라 USB 드라이버, Device Owner 등록 허용 여부 및 KIS Agent 동작이 다를 수 있습니다. 여러 대를 작업하기 전에 반드시 실제 NTP-10 한 대에서 전 항목을 선행 검증하십시오.

## 실기기 검증 현황

2026-09-29에 Android 11 기반 R10D 한 대에서 USB Device Owner 등록, HOME·최근 앱·뒤로가기 제한, 재부팅 자동 실행, 관리자 `앱 종료`와 재실행 복구, GitHub 최신 버전의 1분 주기 확인까지 검증했습니다.

KIS Agent와 실카드 승인·취소는 아직 미검증입니다. v1.0.2보다 높은 운영 버전도 아직 없으므로 새 APK의 무인 설치·재시작 전체 과정은 다음 버전 게시 시 추가 검증합니다.

## QR이 안 되는 NTP-10: USB BAT 설치

1. [`niceione-tablet-usb-setup-v1.0.2.zip`](https://github.com/niceione/niceione-checkin-tablet-release/releases/download/v1.0.2/niceione-tablet-usb-setup-v1.0.2.zip)을 받아 압축을 풉니다.
2. KIS Agent가 태블릿에 없다면 KIS 제공 APK를 `kis-agent.apk` 이름으로 같은 폴더에 넣습니다.
3. 태블릿을 공장 초기화하고 Google 계정을 추가하지 않은 채 초기 설정을 마칩니다.
4. `설정 → 태블릿 정보 → 빌드 번호`를 7번 눌러 개발자 옵션을 켭니다.
5. 개발자 옵션에서 `USB 디버깅`을 켜고 PC에 연결합니다.
6. 태블릿의 USB 디버깅 허용 창에서 `이 컴퓨터에서 항상 허용`을 선택합니다.
7. PC에서 `Setup-NiceIone-Tablet.bat`를 더블클릭합니다.

BAT가 ADB 준비, KIS Agent 확인, 최신 APK 다운로드·해시 검증, Device Owner 등록, HOME·뒤로가기 제한, 자동 실행까지 처리하고 마지막 상태를 검증합니다.

- [USB 설치 전체 설명](usb-setup/INSTALL-KO.md)
- [BAT 원본](usb-setup/Setup-NiceIone-Tablet.bat)
- [PowerShell 원본](usb-setup/Setup-ProductionDeviceOwner.ps1)

관리자 설정 우측 상단 `앱 종료`를 누르면 Lock Task를 일시 해제하고 Android 설정으로 이동합니다. NiceIone 앱을 다시 실행하거나 기기를 재부팅하면 키오스크 정책이 자동 복구됩니다.

## Device Owner 설치 QR

아래 QR 하나를 신규 태블릿에 계속 재사용할 수 있습니다.

QR 프로비저닝을 지원하는 다른 태블릿에서만 사용합니다. 이 QR에는 Wi-Fi 정보가 없으므로 초기 설정 중 사용할 Wi-Fi를 직접 선택해야 합니다.

![NiceIone Device Owner 설치 QR](device-owner/v1.0.2/niceione-device-owner-qr.png)

- [QR 이미지 원본 다운로드](device-owner/v1.0.2/niceione-device-owner-qr.png)
- [QR 데이터 확인](device-owner/v1.0.2/niceione-device-owner.json)

## 실제 태블릿 설치 순서

### 1. 시험 기기 한 대 등록

1. 필요한 기존 자료를 백업하고 태블릿을 공장 초기화합니다.
2. 재부팅 후 표시되는 Android 첫 환영 화면에서 빈 곳의 같은 위치를 빠르게 6번 누릅니다.
3. Wi-Fi 선택 화면이 나오면 인터넷 사용이 가능한 Wi-Fi에 연결합니다.
4. QR 스캐너가 열리면 위의 Device Owner QR을 스캔합니다.
5. `기기를 설정하는 중` 안내에 따라 초기 등록을 계속합니다. 최초 Device Owner 등록 과정의 확인 화면은 진행해야 합니다.
6. Android가 APK를 다운로드하고 체크섬을 검증한 뒤 NiceIone 앱을 Device Owner로 등록할 때까지 기다립니다.
7. NiceIone 앱이 자동으로 시작되는지 확인합니다.

첫 화면을 6번 눌러도 QR 등록 화면이 나오지 않으면 위의 USB BAT 설치 방식을 사용합니다.

### 2. 기기별 설정

각 태블릿에서 다음 값은 서로 겹치지 않게 설정합니다.

1. 지점코드
2. 9자리 기기 ID
3. 객실코드
4. 관리자 PIN
5. 운영 결제 모드

관리자 화면에서 KIS Agent 연결과 실제 승인·취소 시험까지 완료합니다.

### 3. 시험 기기 확인

다음 항목이 모두 정상일 때만 나머지 태블릿을 등록합니다.

- 앱이 기본 HOME/키오스크 화면으로 동작한다.
- 홈·뒤로 가기로 고객이 앱을 이탈할 수 없다.
- 전원을 다시 켜면 앱이 자동으로 실행된다.
- KIS Agent가 설치되어 있고 실제 승인·취소가 정상이다.
- 지점코드, 기기 ID, 객실코드가 해당 객실과 일치한다.

### 4. 나머지 기기 반복

같은 QR을 사용해 태블릿을 계속 추가합니다. QR 자체에는 등록 대수 제한이 없습니다. 기기마다 고유한 기기 ID와 객실코드만 입력합니다.

## 자동 업데이트 동작

Device Owner 등록이 끝난 뒤에는 사용자가 APK 설치를 허용할 필요가 없습니다.

1. 앱 시작 시와 실행 중 1분마다 최신 버전을 확인합니다.
2. APK의 패키지명, 버전, 서명 및 SHA-256을 검증합니다.
3. 고객 흐름, 본인인증, 결제, 관리자 화면 또는 미완료 거래가 있으면 설치를 연기합니다.
4. 첫 화면에서 마지막 터치 후 1분 이상 지난 경우에만 자동 설치합니다.
5. 설치가 끝나면 앱이 자동으로 다시 시작됩니다.

## QR에 포함된 정보

QR에는 다음 정보만 있습니다.

- `v1.0.2` 운영 APK 공개 다운로드 주소
- Device Owner 관리자 컴포넌트명
- APK 변조 확인용 SHA-256 체크섬
- 기존 Android 시스템 앱 유지 설정

Wi-Fi 비밀번호, GitHub 계정·토큰, 지점코드, 객실코드, 기기 ID, 관리자 PIN 및 고객정보는 포함되지 않습니다.

## 운영 주의사항

- 이 QR은 `v1.0.2` APK의 체크섬과 연결되어 있으므로 `v1.0.2` Release의 APK를 교체하거나 삭제하지 않습니다.
- 이후 버전은 새로운 태그와 더 큰 `versionCode`로 게시합니다.
- 신규 기기는 QR로 `v1.0.2`를 설치한 뒤 실행 중 최신 버전으로 자동 업데이트됩니다.
- 문제가 있는 버전을 게시했을 때 Android는 낮은 `versionCode`로 자동 복귀하지 않습니다. 수정 버전은 반드시 더 큰 `versionCode`로 게시합니다.
