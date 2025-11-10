Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-FileUtf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $directory = Split-Path -Path $Path -Parent
    if (![string]::IsNullOrEmpty($directory) -and -not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $normalized = [regex]::Replace($Content, "`r?`n", "`r`n")
    if ($normalized.Length -gt 0 -and -not $normalized.EndsWith("`r`n")) {
        $normalized += "`r`n"
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $normalized, $encoding)
}

function Ensure-AppPluginsBlock {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$PluginsBlock,
        [Parameter(Mandatory = $true)][string]$MinimumContent
    )

    if (-not (Test-Path -Path $FilePath)) {
        Write-FileUtf8NoBom -Path $FilePath -Content $MinimumContent
        return
    }

    $existingContent = [System.IO.File]::ReadAllText($FilePath)
    if ([string]::IsNullOrWhiteSpace($existingContent)) {
        Write-FileUtf8NoBom -Path $FilePath -Content $MinimumContent
        return
    }

    $hasAndroidBlock = $existingContent -match 'android\s*\{'
    if (-not $hasAndroidBlock) {
        Write-FileUtf8NoBom -Path $FilePath -Content $MinimumContent
        return
    }

    $updatedContent = $existingContent
    $pluginRegex = [regex]'(?s)plugins\s*\{.*?\}'
    $pluginMatch = $pluginRegex.Match($updatedContent)

    if ($pluginMatch.Success) {
        $requiredPlugins = @(
            'id("com.android.application")',
            'id("org.jetbrains.kotlin.android")',
            'id("com.google.gms.google-services")'
        )

        foreach ($plugin in $requiredPlugins) {
            if ($pluginMatch.Value -notmatch [regex]::Escape($plugin)) {
                $updatedContent = $updatedContent.Insert($pluginMatch.Index + $pluginMatch.Length - 1, "    $plugin`r`n")
                $pluginMatch = $pluginRegex.Match($updatedContent)
            }
        }
    } else {
        $updatedContent = $PluginsBlock.TrimEnd() + "`r`n`r`n" + $updatedContent.TrimStart()
    }

    Write-FileUtf8NoBom -Path $FilePath -Content $updatedContent
}

$projectRoot = 'E:\E\APK'
$settingsPath = Join-Path $projectRoot 'settings.gradle.kts'
$rootBuildPath = Join-Path $projectRoot 'build.gradle.kts'
$appBuildPath = Join-Path $projectRoot 'app\build.gradle.kts'
$wrapperPropertiesPath = Join-Path $projectRoot 'gradle\wrapper\gradle-wrapper.properties'
$googleServicesPath = Join-Path $projectRoot 'app\google-services.json'

$settingsContent = @'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories { google(); mavenCentral() }
}
rootProject.name = "APK"
include(":app")
'@

$rootBuildContent = @'
plugins {
  id("com.android.application") version "8.2.2" apply false
  id("org.jetbrains.kotlin.android") version "1.9.22" apply false
  id("com.google.gms.google-services") version "4.4.2" apply false
}
'@

$pluginsBlock = @'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
}
'@

$minimalAppBuild = @'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
}

android {
    namespace = "prashan.muditha.sahas"
    compileSdk = 34

    defaultConfig {
        applicationId = "prashan.muditha.sahas"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
}
'@

Write-FileUtf8NoBom -Path $settingsPath -Content $settingsContent
Write-FileUtf8NoBom -Path $rootBuildPath -Content $rootBuildContent
Ensure-AppPluginsBlock -FilePath $appBuildPath -PluginsBlock $pluginsBlock -MinimumContent $minimalAppBuild

$wrapperContent = ''
if (Test-Path -Path $wrapperPropertiesPath) {
    $wrapperContent = [System.IO.File]::ReadAllText($wrapperPropertiesPath)
}

$desiredDistribution = 'distributionUrl=https://services.gradle.org/distributions/gradle-8.5-bin.zip'
if ($wrapperContent -match 'distributionUrl=.*') {
    $wrapperContent = [regex]::Replace($wrapperContent, 'distributionUrl=.*', $desiredDistribution)
} else {
    if ($wrapperContent.Trim().Length -gt 0 -and -not $wrapperContent.EndsWith("`r`n")) {
        $wrapperContent += "`r`n"
    }
    $wrapperContent += $desiredDistribution
}

Write-FileUtf8NoBom -Path $wrapperPropertiesPath -Content $wrapperContent

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    if ($env:LOCALAPPDATA) {
        $platformTools = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools'
        $adbPath = Join-Path $platformTools 'adb.exe'
        if (Test-Path -Path $adbPath) {
            $pathItems = $env:Path -split ';'
            if ($pathItems -notcontains $platformTools) {
                $env:Path = "$platformTools;$($env:Path)"
                Write-Host "Added $platformTools to PATH for this session."
            }
        }
    }
}

$commands = @(
    @{ Description = 'Stop Gradle daemons'; Args = '--stop' },
    @{ Description = 'Ensure Gradle wrapper at 8.5'; Args = 'wrapper --gradle-version 8.5' },
    @{ Description = 'Clean build'; Args = 'clean' },
    @{ Description = 'Run build'; Args = 'build --stacktrace' }
)

Push-Location -Path $projectRoot
try {
    foreach ($command in $commands) {
        $argString = $command.Args
        Write-Host "Executing: gradlew.bat $argString"
        cmd /c ".\gradlew.bat $argString"
        if ($LASTEXITCODE -ne 0) {
            throw "Command '.\\gradlew.bat $argString' failed with exit code $LASTEXITCODE."
        }
    }
} finally {
    Pop-Location
}

if (-not (Test-Path -Path $googleServicesPath)) {
    Write-Host 'Reminder: E:\E\APK\app\google-services.json is missing. The Google Services plugin requires this file.'
}
