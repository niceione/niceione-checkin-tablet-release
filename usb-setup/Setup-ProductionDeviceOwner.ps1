param(
    [string]$Serial = "",
    [string]$KisAgentApkPath = "",
    [string]$AppApkPath = "",
    [switch]$SkipKisAgent
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$appPackage = "kr.co.niceione.checkintablet"
$kisPackage = "kr.co.kisvan.andagent"
$adminComponent = "$appPackage/$appPackage.NiceIoneDeviceAdminReceiver"
$latestManifestUrl = "https://github.com/niceione/niceione-checkin-tablet-release/releases/latest/download/update.json"
$platformToolsUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "[$script:StepNumber/7] $Message" -ForegroundColor Cyan
    $script:StepNumber++
}

function Invoke-Download {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Destination
    )
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
        return
    } catch {
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($null -eq $curl) { throw }
        & $curl.Source --ssl-no-revoke -fL $Url -o $Destination
        if ($LASTEXITCODE -ne 0) { throw "다운로드에 실패했습니다: $Url" }
    }
}

function Find-OrInstallAdb {
    $candidates = @(
        (Join-Path $PSScriptRoot ".android-tools\platform-tools\adb.exe"),
        (Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return (Resolve-Path $candidate).Path }
    }
    $command = Get-Command adb.exe -ErrorAction SilentlyContinue
    if ($null -ne $command) { return $command.Source }

    Write-Host "ADB가 없어 Google 공식 Android Platform Tools를 준비합니다."
    $toolsDirectory = Join-Path $PSScriptRoot ".android-tools"
    $archive = Join-Path $toolsDirectory "platform-tools.zip"
    $null = New-Item -ItemType Directory -Force -Path $toolsDirectory
    Invoke-Download -Url $platformToolsUrl -Destination $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $toolsDirectory -Force
    $downloadedAdb = Join-Path $toolsDirectory "platform-tools\adb.exe"
    if (-not (Test-Path -LiteralPath $downloadedAdb)) {
        throw "Android Platform Tools에서 adb.exe를 찾지 못했습니다."
    }
    return (Resolve-Path $downloadedAdb).Path
}

function Invoke-AdbCommand {
    param(
        [Parameter(Mandatory = $true)][string[]]$CommandArguments,
        [switch]$AllowFailure
    )
    $output = & $script:AdbPath -s $script:TargetSerial @CommandArguments 2>&1
    $exitCode = $LASTEXITCODE
    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "ADB 명령 실패: adb -s $script:TargetSerial $($CommandArguments -join ' ')`n$($output -join "`n")"
    }
    return @($output)
}

function Test-PackageInstalled {
    param([Parameter(Mandatory = $true)][string]$PackageName)
    $result = Invoke-AdbCommand -CommandArguments @("shell", "pm", "path", $PackageName) -AllowFailure
    return (($result -join "`n") -match "package:")
}

function Resolve-AppApk {
    if (-not [string]::IsNullOrWhiteSpace($AppApkPath)) {
        return (Resolve-Path -LiteralPath $AppApkPath).Path
    }

    $downloadDirectory = Join-Path $PSScriptRoot "downloads"
    $null = New-Item -ItemType Directory -Force -Path $downloadDirectory
    $manifestFile = Join-Path $downloadDirectory "update.json"
    Invoke-Download -Url $latestManifestUrl -Destination $manifestFile
    $manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
    if ($manifest.apkUrl -notmatch "^https://" -or $manifest.sha256 -notmatch "^[0-9a-fA-F]{64}$") {
        throw "GitHub update.json 형식이 올바르지 않습니다."
    }
    $apkName = [System.IO.Path]::GetFileName(([Uri]$manifest.apkUrl).AbsolutePath)
    $downloadedApk = Join-Path $downloadDirectory $apkName
    Invoke-Download -Url $manifest.apkUrl -Destination $downloadedApk
    $actualHash = (Get-FileHash -LiteralPath $downloadedApk -Algorithm SHA256).Hash
    if ($actualHash -ne $manifest.sha256) {
        throw "다운로드한 NiceIone APK의 SHA-256이 update.json과 다릅니다."
    }
    Write-Host "NiceIone $($manifest.versionName) APK 검증 완료"
    return (Resolve-Path -LiteralPath $downloadedApk).Path
}

$script:StepNumber = 1
Write-Step "ADB 준비"
$script:AdbPath = Find-OrInstallAdb
& $script:AdbPath start-server | Out-Null

Write-Step "연결된 태블릿 확인"
$deviceOutput = & $script:AdbPath devices
$authorizedDevices = @(
    $deviceOutput | Select-Object -Skip 1 | Where-Object { $_ -match "^\S+\s+device\s*$" }
)
$unauthorizedDevices = @(
    $deviceOutput | Select-Object -Skip 1 | Where-Object { $_ -match "^\S+\s+unauthorized\s*$" }
)
if ($unauthorizedDevices.Count -gt 0) {
    throw "태블릿 화면의 '이 컴퓨터에서 항상 허용'과 '허용'을 누른 뒤 다시 실행하세요."
}
if ([string]::IsNullOrWhiteSpace($Serial)) {
    if ($authorizedDevices.Count -ne 1) {
        throw "USB 디버깅이 허용된 태블릿을 정확히 1대만 연결하세요. 현재: $($authorizedDevices.Count)대"
    }
    $Serial = (($authorizedDevices[0] -split "\s+")[0])
}
$script:TargetSerial = $Serial
$model = (Invoke-AdbCommand -CommandArguments @("shell", "getprop", "ro.product.model")) -join ""
$android = (Invoke-AdbCommand -CommandArguments @("shell", "getprop", "ro.build.version.release")) -join ""
$sdk = [int](((Invoke-AdbCommand -CommandArguments @("shell", "getprop", "ro.build.version.sdk")) -join "").Trim())
if ($sdk -lt 24) { throw "지원하지 않는 Android 버전입니다: Android $android (SDK $sdk)" }
Write-Host "대상: $Serial / $model / Android $android"

Write-Step "Device Owner 등록 조건 확인"
$policyText = (Invoke-AdbCommand -CommandArguments @("shell", "dumpsys", "device_policy")) -join "`n"
$alreadyOwner = $policyText -match [regex]::Escape($adminComponent)
if ($policyText -match "Device Owner:" -and -not $alreadyOwner) {
    throw "다른 Device Owner가 이미 설정되어 있습니다. 기존 MDM을 확인하거나 공장 초기화해야 합니다."
}
if (-not $alreadyOwner) {
    $usersText = (Invoke-AdbCommand -CommandArguments @("shell", "pm", "list", "users")) -join "`n"
    $userCount = [regex]::Matches($usersText, "UserInfo\{").Count
    if ($userCount -ne 1) {
        throw "Android 사용자가 $userCount 명입니다. 보조 사용자/업무 프로필을 제거하거나 공장 초기화하세요."
    }
    $accountsText = (Invoke-AdbCommand -CommandArguments @("shell", "dumpsys", "account")) -join "`n"
    if ($accountsText -match "Accounts:\s*[1-9]" -or $accountsText -match "Account \{name=") {
        throw "Google 또는 기타 계정이 등록되어 있습니다. 모든 계정을 제거한 뒤 다시 실행하세요."
    }
}

Write-Step "KIS Agent 확인 및 설치"
$kisInstalled = Test-PackageInstalled -PackageName $kisPackage
if (-not $kisInstalled -and -not $SkipKisAgent) {
    if ([string]::IsNullOrWhiteSpace($KisAgentApkPath)) {
        $KisAgentApkPath = Join-Path $PSScriptRoot "kis-agent.apk"
    }
    if (-not (Test-Path -LiteralPath $KisAgentApkPath)) {
        throw "KIS Agent가 태블릿에 없습니다. KIS 제공 APK를 이 BAT와 같은 폴더에 kis-agent.apk 이름으로 넣으세요."
    }
    $resolvedKisApk = (Resolve-Path -LiteralPath $KisAgentApkPath).Path
    Invoke-AdbCommand -CommandArguments @("install", "-r", "-g", $resolvedKisApk) | Write-Host
    if (-not (Test-PackageInstalled -PackageName $kisPackage)) {
        throw "설치한 APK의 패키지가 $kisPackage 가 아닙니다. 올바른 KIS Agent APK인지 확인하세요."
    }
    Write-Host "KIS Agent 설치 완료"
} elseif ($kisInstalled) {
    Write-Host "기존 KIS Agent 확인 완료"
} else {
    Write-Warning "-SkipKisAgent가 지정되어 KIS Agent 확인을 건너뜁니다. 실결제는 동작하지 않습니다."
}

Write-Step "최신 NiceIone 앱 설치"
$resolvedAppApk = Resolve-AppApk
Invoke-AdbCommand -CommandArguments @("install", "-r", "-g", $resolvedAppApk) | Write-Host
if (-not (Test-PackageInstalled -PackageName $appPackage)) {
    throw "NiceIone 앱 설치를 확인하지 못했습니다."
}

Write-Step "Device Owner 및 키오스크 정책 적용"
if (-not $alreadyOwner) {
    $ownerResult = Invoke-AdbCommand -CommandArguments @(
        "shell", "dpm", "set-device-owner", "--user", "0", "--name", "NiceIoneTablet", $adminComponent
    )
    Write-Host ($ownerResult -join "`n")
}
Invoke-AdbCommand -CommandArguments @(
    "shell", "am", "force-stop", $appPackage
) | Out-Null
Invoke-AdbCommand -CommandArguments @(
    "shell", "am", "start", "-W", "-n", "$appPackage/$appPackage.MainActivity"
) | Out-Null
Start-Sleep -Seconds 2

Write-Step "최종 검증"
$verifiedPolicy = (Invoke-AdbCommand -CommandArguments @("shell", "dumpsys", "device_policy")) -join "`n"
if ($verifiedPolicy -notmatch [regex]::Escape($adminComponent)) {
    throw "Device Owner 등록을 확인하지 못했습니다. 공장 초기화 후 Google 계정을 추가하지 말고 다시 시도하세요."
}
$homeActivity = (Invoke-AdbCommand -CommandArguments @(
    "shell", "cmd", "package", "resolve-activity", "--brief", "-a", "android.intent.action.MAIN", "-c", "android.intent.category.HOME"
)) -join "`n"
if ($homeActivity -notmatch [regex]::Escape($appPackage)) {
    throw "NiceIone 앱이 기본 HOME으로 설정되지 않았습니다: $homeActivity"
}
$activityState = (Invoke-AdbCommand -CommandArguments @("shell", "dumpsys", "activity", "activities")) -join "`n"
if ($activityState -notmatch "mLockTaskModeState=LOCKED") {
    throw "Lock Task(HOME/최근 앱 차단)가 활성화되지 않았습니다."
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "설정 완료" -ForegroundColor Green
Write-Host "- HOME/최근 앱/뒤로가기 제한: 적용"
Write-Host "- 재부팅 후 자동 실행: 적용"
Write-Host "- KIS Agent: $(if (Test-PackageInstalled -PackageName $kisPackage) { '설치 확인' } else { '건너뜀' })"
Write-Host "- 승인/취소 결제: 앱 관리자 화면에서 실결제 시험 필요"
Write-Host "- 앱 자체 자동 업데이트: 적용"
Write-Host "- 관리자 앱 종료: 관리자 설정 우측 상단 '앱 종료'"
Write-Host "============================================================" -ForegroundColor Green
