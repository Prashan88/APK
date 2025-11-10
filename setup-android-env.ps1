<#
    Script: setup-android-env.ps1
    Description: Configures Android development environment variables for PowerShell.
    Requirements:
        - Detect Android Studio installation and configure JAVA_HOME
        - Add Java and Android SDK platform-tools to PATH
        - Persist environment variables using setx
        - Update current session variables
        - Display java and adb versions at the end
    The script is idempotent and safe to rerun.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success($Message) {
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-WarningMessage($Message) {
    Write-Warning "[WARNING] $Message"
}

function Test-PathCaseInsensitive {
    param (
        [Parameter(Mandatory = $true)][string]$Path
    )
    return Test-Path -LiteralPath $Path
}

function Ensure-PathEntry {
    param (
        [Parameter(Mandatory = $true)][string]$Entry,
        [ValidateSet('User', 'Machine')][string]$Scope = 'User'
    )

    $existing = [Environment]::GetEnvironmentVariable('Path', $Scope)
    if ([string]::IsNullOrWhiteSpace($existing)) {
        $segments = @()
    } else {
        $segments = $existing -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }

    $normalizedEntry = ($Entry.TrimEnd('\')).ToLowerInvariant()
    $hasEntry = $segments | ForEach-Object { ($_).Trim().TrimEnd('\').ToLowerInvariant() } | Where-Object { $_ -eq $normalizedEntry }

    if (-not $hasEntry) {
        $updated = @($segments) + $Entry
        $newPath = ($updated | Select-Object -Unique) -join ';'
        setx Path $newPath | Out-Null
        Write-Info "Added '$Entry' to user PATH."
    } else {
        Write-Info "PATH already contains '$Entry'."
    }
}

function Update-SessionPath {
    param (
        [Parameter(Mandatory = $true)][string]$Entry
    )
    $segments = $env:Path -split ';'
    $normalizedEntry = ($Entry.TrimEnd('\')).ToLowerInvariant()
    $hasEntry = $segments | ForEach-Object { ($_).Trim().TrimEnd('\').ToLowerInvariant() } | Where-Object { $_ -eq $normalizedEntry }

    if (-not $hasEntry) {
        $env:Path = "$Entry;" + $env:Path
        Write-Info "Updated current session PATH with '$Entry'."
    } else {
        Write-Info "Current session PATH already contains '$Entry'."
    }
}

try {
    $androidStudioPath = 'C:\Program Files\Android\Android Studio'
    $javaHome = Join-Path $androidStudioPath 'jbr'

    if (Test-PathCaseInsensitive -Path $javaHome) {
        Write-Info "Android Studio detected at '$androidStudioPath'."
        setx JAVA_HOME "$javaHome" | Out-Null
        $env:JAVA_HOME = $javaHome
        Write-Success "JAVA_HOME set to '$javaHome'."

        $javaBin = Join-Path $javaHome 'bin'
        Ensure-PathEntry -Entry $javaBin -Scope 'User'
        Update-SessionPath -Entry $javaBin
    } else {
        Write-WarningMessage "Android Studio not found at '$androidStudioPath'. JAVA_HOME was not modified."
    }

    $androidSdkPaths = @()

    if ($env:ANDROID_SDK_ROOT) {
        $androidSdkPaths += $env:ANDROID_SDK_ROOT
    }
    if ($env:ANDROID_HOME) {
        $androidSdkPaths += $env:ANDROID_HOME
    }
    $defaultSdkPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
    $androidSdkPaths += $defaultSdkPath

    $sdkPath = $androidSdkPaths | Where-Object { Test-PathCaseInsensitive -Path $_ } | Select-Object -First 1

    if ($null -ne $sdkPath) {
        Write-Info "Android SDK detected at '$sdkPath'."
        $platformTools = Join-Path $sdkPath 'platform-tools'
        if (Test-PathCaseInsensitive -Path $platformTools) {
            Ensure-PathEntry -Entry $platformTools -Scope 'User'
            Update-SessionPath -Entry $platformTools
            Write-Success "Android platform-tools added to PATH."
        } else {
            Write-WarningMessage "Platform-tools folder not found in '$sdkPath'. PATH not updated."
        }
    } else {
        Write-WarningMessage "Could not locate the Android SDK. Ensure it is installed and rerun this script."
    }

    Write-Info 'Verifying tools availability...'

    try {
        $javaVersion = & 'java' -version 2>&1
        Write-Success "java -version:`n$javaVersion"
    } catch {
        Write-WarningMessage "Failed to execute 'java'."
    }

    try {
        $adbVersion = & 'adb' version 2>&1
        Write-Success "adb version:`n$adbVersion"
    } catch {
        Write-WarningMessage "Failed to execute 'adb'."
    }

} catch {
    Write-Error "An unexpected error occurred: $_"
    exit 1
}
