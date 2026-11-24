[CmdletBinding()]
param(
    [ValidateSet('explorar', 'e2e', 'somente-testes')]
    [string]$Modo = 'explorar',
    [switch]$SoPreparar,
    [switch]$Ajuda
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($Ajuda) {
    Write-Host 'preparar-windows.cmd [-Modo explorar|e2e|somente-testes] [-SoPreparar]'
    exit 0
}
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    Write-Error 'Este preparador e para Windows. No macOS ou Linux, use node testar-guardian.cjs.'
    exit 1
}

$nativeArchitecture = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else {
    $env:PROCESSOR_ARCHITECTURE
}
if ($nativeArchitecture -ne 'AMD64') {
    Write-Error 'Use Windows 10/11 de 64 bits em um computador Intel ou AMD para este preparador.'
    exit 1
}

$runner = Join-Path $PSScriptRoot 'testar-guardian.cjs'
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    Write-Error 'Extraia o projeto inteiro e execute o comando na pasta scripts.'
    exit 1
}

# Same Flutter version used to build the apps in the project.
$flutterVersion = '3.47.9'
$flutterHome = Join-Path $env:LOCALAPPDATA "Guardian\flutter-$flutterVersion"
$flutter = Join-Path $flutterHome 'bin\flutter.bat'
$studioHome = if ($env:GUARDIAN_ANDROID_STUDIO) { $env:GUARDIAN_ANDROID_STUDIO } else {
    Join-Path $env:ProgramFiles 'Android\Android Studio'
}
$studio = Join-Path $studioHome 'bin\studio64.exe'
$jdk = Join-Path $studioHome 'jbr'
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) {
    $env:ANDROID_SDK_ROOT
} else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$avd = 'Guardian_API_35'
$imageRoot = 'system-images;android-35;google_apis'
$buildToolsVersion = '36.0.0'
$commandLineArchive = 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip'
$commandLineSha256 = '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a'

function Invoke-Tool {
    param([string]$File, [string[]]$Arguments)
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$(Split-Path -Leaf $File) falhou (codigo $LASTEXITCODE). Veja a mensagem acima."
    }
}

function Find-Executable {
    param([string]$Name, [string[]]$Candidates = @())
    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($command) { return $command.Source }
    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) { return $candidate }
    }
    return $null
}

function Update-SessionPath {
    $paths = @(
        $env:Path
        [Environment]::GetEnvironmentVariable('Path', 'Machine')
        [Environment]::GetEnvironmentVariable('Path', 'User')
    ) -join ';'
    $env:Path = ($paths -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
}

function Install-WithWinGet {
    param([string]$Id)
    $winget = Find-Executable 'winget.exe'
    if (-not $winget) {
        throw 'Instale ou atualize o App Installer pela Microsoft Store para disponibilizar o WinGet.'
    }
    Write-Host "Instalando $Id. Responda aos avisos do instalador, se aparecerem."
    Invoke-Tool $winget @('install', '--exact', '--id', $Id, '--source', 'winget')
    Update-SessionPath
}

function Test-NodeVersion {
    param([string]$Executable)
    if (-not $Executable) { return $false }
    $output = & $Executable --version
    if ($LASTEXITCODE -ne 0 -or $output -notmatch '^v(\d+\.\d+\.\d+)$') { return $false }
    $version = [version]$Matches[1]
    return (
        ($version.Major -eq 22 -and $version -ge [version]'22.22.3') -or
        ($version.Major -eq 24 -and $version -ge [version]'24.15.0') -or
        $version.Major -ge 26
    )
}

function Install-CommandLineTools {
    param([string]$Destination)
    if (Test-Path -LiteralPath $Destination) {
        throw "A pasta $Destination existe, mas o sdkmanager esta incompleto. Confira a instalacao do SDK no Android Studio."
    }
    $temp = Join-Path ([System.IO.Path]::GetTempPath()) "guardian-sdk-$([guid]::NewGuid())"
    New-Item -ItemType Directory -Path $temp | Out-Null
    try {
        $archive = Join-Path $temp 'android-tools.zip'
        $extracted = Join-Path $temp 'extraido'
        Write-Host 'Baixando as ferramentas oficiais do Android SDK e conferindo a integridade...'
        Invoke-WebRequest -UseBasicParsing -Uri $commandLineArchive -OutFile $archive
        if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $commandLineSha256) {
            throw 'O arquivo das ferramentas Android nao passou na verificacao de integridade.'
        }
        Expand-Archive -LiteralPath $archive -DestinationPath $extracted
        if (-not (Test-Path -LiteralPath (Join-Path $extracted 'cmdline-tools\bin\sdkmanager.bat') -PathType Leaf)) {
            throw 'O pacote baixado nao contem o sdkmanager.'
        }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
        Move-Item -LiteralPath (Join-Path $extracted 'cmdline-tools') -Destination $Destination
    } finally {
        Remove-Item -LiteralPath $temp -Recurse -Force
    }
}

try {
    Update-SessionPath
    $gitCandidates = @(
        (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe')
    )
    $git = Find-Executable 'git.exe' $gitCandidates
    if (-not $git) {
        Install-WithWinGet 'Git.Git'
        $git = Find-Executable 'git.exe' $gitCandidates
    }
    if (-not $git) { throw 'O Git ainda nao esta no PATH. Abra um novo PowerShell e execute novamente.' }

    $nodeCandidates = @((Join-Path $env:ProgramFiles 'nodejs\node.exe'))
    $node = Find-Executable 'node.exe' $nodeCandidates
    if (-not (Test-NodeVersion $node)) {
        Install-WithWinGet 'OpenJS.NodeJS.LTS'
        $node = Find-Executable 'node.exe' $nodeCandidates
    }
    if (-not (Test-NodeVersion $node)) {
        throw 'Use Node.js 22.22.3+ na linha 22, ou 24.15.0+ na linha 24. Confira node --version em um novo PowerShell.'
    }

    if (-not (Test-Path -LiteralPath $studio -PathType Leaf)) {
        Install-WithWinGet 'Google.AndroidStudio'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $jdk 'bin\javac.exe') -PathType Leaf)) {
        throw 'O JDK do Android Studio nao foi encontrado. Se instalou em outro local, defina GUARDIAN_ANDROID_STUDIO.'
    }

    $env:Path = "$(Split-Path -Parent $git);$(Split-Path -Parent $node);$jdk\bin;$env:Path"
    $env:JAVA_HOME = $jdk
    $env:ANDROID_HOME = $sdk
    $env:ANDROID_SDK_ROOT = $sdk
    if (-not (Test-Path -LiteralPath $flutter -PathType Leaf)) {
        if (Test-Path -LiteralPath $flutterHome) {
            throw "A pasta $flutterHome existe, mas o Flutter esta incompleto. Renomeie essa pasta e execute novamente."
        }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $flutterHome) | Out-Null
        Write-Host "Instalando Flutter $flutterVersion na pasta do Guardian..."
        Invoke-Tool $git @('-c', 'core.longpaths=true', 'clone', '--depth', '1', '--branch', $flutterVersion,
            'https://github.com/flutter/flutter.git', $flutterHome)
    }
    $env:FLUTTER_BIN = $flutter
    $env:Path = "$(Split-Path -Parent $flutter);$env:Path"
    Invoke-Tool $flutter @('--version')

    $extension = Join-Path $flutterHome 'packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt'
    $metadata = Get-Content -Raw -LiteralPath $extension
    $compile = [regex]::Match($metadata, 'compileSdkVersion\s*:\s*Int\s*=\s*(\d+)')
    $ndk = [regex]::Match($metadata, 'ndkVersion\s*:\s*String\s*=\s*"([\d.]+)"')
    if (-not $compile.Success -or -not $ndk.Success) {
        throw 'Nao foi possivel identificar a plataforma Android e o NDK exigidos pelo Flutter.'
    }
    $platform = $compile.Groups[1].Value
    $ndkVersion = $ndk.Groups[1].Value

    $abi = 'x86_64'
    $toolsRoot = Join-Path $sdk 'cmdline-tools\latest'
    $sdkManager = Join-Path $toolsRoot 'bin\sdkmanager.bat'
    if (-not (Test-Path -LiteralPath $sdkManager -PathType Leaf)) {
        Install-CommandLineTools $toolsRoot
    }
    $sdkArg = "--sdk_root=$sdk"
    $packages = [ordered]@{
        'platform-tools' = 'platform-tools\adb.exe'
        "platforms;android-$platform" = "platforms\android-$platform\android.jar"
        "build-tools;$buildToolsVersion" = "build-tools\$buildToolsVersion\source.properties"
        "ndk;$ndkVersion" = "ndk\$ndkVersion\source.properties"
    }
    if ($Modo -ne 'somente-testes') {
        $packages['emulator'] = 'emulator\emulator.exe'
        $packages["$imageRoot;$abi"] = "system-images\android-35\google_apis\$abi\source.properties"
    }
    $missing = @($packages.Keys | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $sdk $packages[$_]) -PathType Leaf)
    })
    if ($missing.Count -gt 0 -or -not (Test-Path -LiteralPath (Join-Path $sdk 'licenses\android-sdk-license'))) {
        Write-Host 'Leia e confirme as licencas do Android quando o SDK solicitar.'
        Invoke-Tool $sdkManager @($sdkArg, '--licenses')
    }
    if ($missing.Count -gt 0) {
        Invoke-Tool $sdkManager (@($sdkArg, '--install') + $missing)
    }

    if ($Modo -ne 'somente-testes') {
        $emulator = Join-Path $sdk 'emulator\emulator.exe'
        $avdManager = Join-Path $toolsRoot 'bin\avdmanager.bat'
        $existingAvds = @(& $emulator -list-avds)
        if ($LASTEXITCODE -ne 0) { throw 'O emulador nao conseguiu listar os dispositivos virtuais.' }
        if ($existingAvds -notcontains $avd) {
            'no' | & $avdManager create avd --name $avd --package "$imageRoot;$abi"
            if ($LASTEXITCODE -ne 0) { throw "Nao foi possivel criar o emulador $avd." }
        }
        if (-not $env:GUARDIAN_AVD) { $env:GUARDIAN_AVD = $avd }
        & $emulator -accel-check
        if ($LASTEXITCODE -ne 0) {
            throw 'Ative a Plataforma do Hipervisor do Windows e a virtualizacao do computador, reinicie e execute novamente.'
        }
    }

    Write-Host 'Ambiente Guardian preparado para esta execucao.'
    if ($SoPreparar) { exit 0 }
    $arguments = @($runner)
    if ($Modo -ne 'explorar') { $arguments += "--$Modo" }
    Invoke-Tool $node $arguments
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
