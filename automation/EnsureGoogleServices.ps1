# ---------------------------
# CONFIG (top of the script)
# ---------------------------
$ProjectRoot = "E:\E\APK"
$JsonSourcePath = "E:\E\APK\app\google-services.json"
$MakeAppMatchJson = $true

# ---------------------------
# SCRIPT IMPLEMENTATION
# ---------------------------

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ExitCode = 0
$finalAppId = $null
$JsonPackage = $null

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [string]$Prefix = "INFO"
    )
    $timestamp = Get-Date -Format 'HH:mm:ss'
    Write-Host "$timestamp [$Prefix] $Message" -ForegroundColor $Color
}

function Write-Info {
    param([Parameter(Mandatory)][string]$Message)
    Write-Log -Message $Message -Color ([ConsoleColor]::Gray) -Prefix 'INFO'
}

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Log -Message $Message -Color ([ConsoleColor]::Cyan) -Prefix 'STEP'
}

function Write-Success {
    param([Parameter(Mandatory)][string]$Message)
    Write-Log -Message $Message -Color ([ConsoleColor]::Green) -Prefix 'OK'
}

function Write-Warn {
    param([Parameter(Mandatory)][string]$Message)
    Write-Log -Message $Message -Color ([ConsoleColor]::Yellow) -Prefix 'WARN'
}

function Write-ErrorLog {
    param([Parameter(Mandatory)][string]$Message)
    Write-Log -Message $Message -Color ([ConsoleColor]::Red) -Prefix 'ERROR'
}

function Normalize-NewLines {
    param([string]$Text)
    if ($null -eq $Text) { return $Text }
    return ($Text -replace "`r?`n", "`r`n")
}

function Write-FileUtf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )
    $normalized = Normalize-NewLines $Content
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $normalized, $encoding)
}

function Ensure-PluginsBlock {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][array]$RequiredPlugins
    )

    $pattern = '(?s)plugins\s*\{\s*(.*?)\s*\}'
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success) {
        throw 'plugins { } block not found.'
    }

    $innerContent = $match.Groups[1].Value
    $existingEntries = @()
    if (-not [string]::IsNullOrWhiteSpace($innerContent)) {
        foreach ($line in ($innerContent -split "`r?`n")) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $trim = $line.Trim()
            $idMatch = [regex]::Match($trim, 'id\("([^"]+)"')
            if ($idMatch.Success) {
                $existingEntries += [pscustomobject]@{
                    Type = 'plugin'
                    Id   = $idMatch.Groups[1].Value
                    Text = $trim
                }
            }
            else {
                $existingEntries += [pscustomobject]@{
                    Type = 'other'
                    Text = $trim
                }
            }
        }
    }

    $requiredIds = @($RequiredPlugins | ForEach-Object { $_.Id })
    $newLines = New-Object System.Collections.Generic.List[string]

    foreach ($plugin in $RequiredPlugins) {
        $existing = $existingEntries | Where-Object { $_.Type -eq 'plugin' -and $_.Id -eq $plugin.Id } | Select-Object -First 1
        if ($null -ne $existing) {
            $newLines.Add("    " + $existing.Text.Trim())
        }
        else {
            $newLines.Add($plugin.Template)
        }
    }

    foreach ($entry in $existingEntries) {
        if ($entry.Type -eq 'plugin' -and $requiredIds -contains $entry.Id) {
            continue
        }
        $newLines.Add("    " + $entry.Text.Trim())
    }

    $innerText = ($newLines.ToArray() -join "`r`n")
    $replacement = "plugins {" + "`r`n" + $innerText + "`r`n" + "}"

    $newContent = $Content.Substring(0, $match.Index) + $replacement + $Content.Substring($match.Index + $match.Length)
    $changed = $newContent -ne $Content
    return [pscustomobject]@{
        Content = $newContent
        Changed = $changed
    }
}

function Invoke-GradleCommand {
    param(
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$Description
    )

    Write-Step "Running $Description ($Command)"
    $process = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $Command -WorkingDirectory $WorkingDirectory -NoNewWindow -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        throw "Command '$Command' failed with exit code $($process.ExitCode)."
    }
    Write-Success "$Description succeeded."
}

try {
    Write-Step 'Validating project structure'
    if (-not (Test-Path -LiteralPath $ProjectRoot)) {
        Write-ErrorLog "Project root not found at $ProjectRoot"
        $script:ExitCode = 1
        return
    }
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).ProviderPath
    Write-Info "Project root: $ProjectRoot"

    $appDirectory = Join-Path $ProjectRoot 'app'
    if (-not (Test-Path -LiteralPath $appDirectory)) {
        throw "App module directory not found at $appDirectory"
    }

    $appJsonPath = Join-Path $appDirectory 'google-services.json'
    Write-Step 'Ensuring google-services.json exists in app module'
    $sourceExists = Test-Path -LiteralPath $JsonSourcePath
    $targetExists = Test-Path -LiteralPath $appJsonPath

    if (-not $sourceExists -and -not $targetExists) {
        Write-ErrorLog "google-services.json not found. Place it at $appJsonPath"
        $script:ExitCode = 1
        return
    }

    if ($sourceExists) {
        $resolvedSource = (Resolve-Path -LiteralPath $JsonSourcePath).ProviderPath
        if (-not (Test-Path -LiteralPath $appDirectory)) {
            New-Item -ItemType Directory -Path $appDirectory -Force | Out-Null
        }
        $resolvedTarget = $appJsonPath
        if ($resolvedSource -ieq $resolvedTarget) {
            Write-Info "google-services.json already located at $resolvedTarget"
        }
        else {
            Copy-Item -LiteralPath $resolvedSource -Destination $resolvedTarget -Force
            Write-Success "Copied google-services.json to $resolvedTarget"
        }
    }
    else {
        Write-Info "Using existing google-services.json at $appJsonPath"
    }

    $appJsonPath = (Resolve-Path -LiteralPath $appJsonPath).ProviderPath

    Write-Step 'Parsing google-services.json'
    $jsonContent = Get-Content -LiteralPath $appJsonPath -Raw -Encoding UTF8
    $jsonObject = $jsonContent | ConvertFrom-Json
    if ($null -eq $jsonObject.client -or $jsonObject.client.Count -eq 0) {
        throw 'Unable to locate client entries in google-services.json.'
    }
    $JsonPackage = $jsonObject.client[0].client_info.android_client_info.package_name
    if ([string]::IsNullOrWhiteSpace($JsonPackage)) {
        throw 'package_name missing inside google-services.json.'
    }
    Write-Success "Detected google-services package: $JsonPackage"

    $appGradlePath = Join-Path $appDirectory 'build.gradle.kts'
    if (-not (Test-Path -LiteralPath $appGradlePath)) {
        throw "Missing file: $appGradlePath"
    }

    Write-Step 'Reviewing app/build.gradle.kts'
    $appGradleOriginal = Get-Content -LiteralPath $appGradlePath -Raw -Encoding UTF8
    $appGradleWorking = $appGradleOriginal

    $applicationIdMatch = [regex]::Match($appGradleWorking, 'applicationId\s*=\s*"([^"]+)"')
    if ($applicationIdMatch.Success) {
        $GradleAppId = $applicationIdMatch.Groups[1].Value
        Write-Info "Current Gradle applicationId: $GradleAppId"
    }
    else {
        $GradleAppId = $null
        Write-Warn 'applicationId not defined in defaultConfig.'
    }

    if (-not $MakeAppMatchJson) {
        if ([string]::IsNullOrWhiteSpace($GradleAppId)) {
            Write-ErrorLog 'applicationId is missing from Gradle configuration.'
            $script:ExitCode = 2
            return
        }
        if ($GradleAppId -ne $JsonPackage) {
            Write-Host "applicationId ($GradleAppId) does not match google-services package ($JsonPackage)." -ForegroundColor Red
            Write-Host "Keep your current applicationId. Please go to Firebase Console → Project settings → Add app (Android)" -ForegroundColor Red
            Write-Host "with applicationId '$GradleAppId' and download a new google-services.json, then place it at app/google-services.json." -ForegroundColor Red
            $script:ExitCode = 2
            return
        }
        $finalAppId = $GradleAppId
    }
    else {
        $appContentChanged = $false
        if ($GradleAppId) {
            if ($GradleAppId -ne $JsonPackage) {
                Write-Step "Updating applicationId to $JsonPackage"
                $appGradleWorking = [regex]::Replace($appGradleWorking, 'applicationId\s*=\s*"([^"]+)"', "applicationId = \"$JsonPackage\"", 1)
                $appContentChanged = $true
                $GradleAppId = $JsonPackage
                Write-Success "applicationId updated to $JsonPackage"
            }
            else {
                Write-Info 'applicationId already matches google-services package.'
            }
        }
        else {
            Write-Step "Inserting applicationId = $JsonPackage into defaultConfig"
            if (-not [regex]::IsMatch($appGradleWorking, 'defaultConfig\s*\{')) {
                throw 'defaultConfig block not found in app/build.gradle.kts.'
            }
            $appGradleWorking = [regex]::Replace($appGradleWorking, 'defaultConfig\s*\{', "defaultConfig {`r`n        applicationId = \"$JsonPackage\"", 1)
            $appContentChanged = $true
            $GradleAppId = $JsonPackage
            Write-Success "applicationId inserted as $JsonPackage"
        }

        $requiredAppPlugins = @(
            @{ Id = 'com.android.application'; Template = '    id("com.android.application")' }
            @{ Id = 'org.jetbrains.kotlin.android'; Template = '    id("org.jetbrains.kotlin.android")' }
            @{ Id = 'com.google.gms.google-services'; Template = '    id("com.google.gms.google-services")' }
        )
        $pluginResult = Ensure-PluginsBlock -Content $appGradleWorking -RequiredPlugins $requiredAppPlugins
        $appGradleWorking = $pluginResult.Content
        if ($pluginResult.Changed) {
            $appContentChanged = $true
            Write-Success 'Ensured required plugins are declared in app/build.gradle.kts.'
        }

        if ($appContentChanged) {
            Write-Step 'Saving updates to app/build.gradle.kts'
            Write-FileUtf8NoBom -Path $appGradlePath -Content $appGradleWorking
            Write-Success 'app/build.gradle.kts updated.'
        }
        else {
            Write-Info 'No changes required in app/build.gradle.kts.'
        }
        $finalAppId = $GradleAppId
    }

    Write-Step 'Updating settings.gradle.kts'
    $settingsPath = Join-Path $ProjectRoot 'settings.gradle.kts'
    if (-not (Test-Path -LiteralPath $settingsPath)) {
        throw "Missing file: $settingsPath"
    }
    $settingsOriginal = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8
    $includeList = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($settingsOriginal -split "`r?`n")) {
        $trim = $line.Trim()
        if ($trim.StartsWith('include(')) {
            if (-not $includeList.Contains($trim)) {
                $includeList.Add($trim)
            }
        }
    }
    if (-not $includeList.Contains('include(":app")')) {
        $includeList.Insert(0, 'include(":app")')
    }
    $includeBlock = $includeList.ToArray() -join "`r`n"

    $desiredSettings = @"
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "APK"
$includeBlock
"@
    $desiredSettings = $desiredSettings.Trim()
    if ((Normalize-NewLines $settingsOriginal).Trim() -ne (Normalize-NewLines $desiredSettings).Trim()) {
        Write-FileUtf8NoBom -Path $settingsPath -Content $desiredSettings
        Write-Success 'settings.gradle.kts updated.'
    }
    else {
        Write-Info 'settings.gradle.kts already matches required content.'
    }

    Write-Step 'Updating root build.gradle.kts'
    $rootBuildPath = Join-Path $ProjectRoot 'build.gradle.kts'
    if (-not (Test-Path -LiteralPath $rootBuildPath)) {
        throw "Missing file: $rootBuildPath"
    }
    $rootBuildOriginal = Get-Content -LiteralPath $rootBuildPath -Raw -Encoding UTF8
    $requiredRootPlugins = @"
plugins {
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
"@
    $requiredRootPlugins = $requiredRootPlugins.Trim()
    $rootUpdated = [regex]::Replace($rootBuildOriginal, '(?s)plugins\s*\{.*?\}', $requiredRootPlugins, 1)
    if ($rootUpdated -eq $rootBuildOriginal -and -not [regex]::IsMatch($rootBuildOriginal, '(?s)plugins\s*\{.*?\}')) {
        $rootUpdated = $requiredRootPlugins + "`r`n" + $rootBuildOriginal
    }
    if ((Normalize-NewLines $rootBuildOriginal).Trim() -ne (Normalize-NewLines $rootUpdated).Trim()) {
        Write-FileUtf8NoBom -Path $rootBuildPath -Content $rootUpdated
        Write-Success 'build.gradle.kts updated with required plugins block.'
    }
    else {
        Write-Info 'build.gradle.kts already compliant.'
    }

    Write-Step 'Ensuring gradle-wrapper.properties targets Gradle 8.5'
    $wrapperDir = Join-Path $ProjectRoot 'gradle/wrapper'
    if (-not (Test-Path -LiteralPath $wrapperDir)) {
        New-Item -ItemType Directory -Path $wrapperDir -Force | Out-Null
    }
    $wrapperPath = Join-Path $wrapperDir 'gradle-wrapper.properties'
    $desiredWrapper = @"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https://services.gradle.org/distributions/gradle-8.5-bin.zip
"@
    $desiredWrapper = $desiredWrapper.Trim()
    $writeWrapper = $true
    if (Test-Path -LiteralPath $wrapperPath) {
        $existingWrapper = Get-Content -LiteralPath $wrapperPath -Raw -Encoding UTF8
        if ((Normalize-NewLines $existingWrapper).Trim() -eq (Normalize-NewLines $desiredWrapper).Trim()) {
            $writeWrapper = $false
        }
    }
    if ($writeWrapper) {
        Write-FileUtf8NoBom -Path $wrapperPath -Content $desiredWrapper
        Write-Success 'gradle-wrapper.properties updated for Gradle 8.5.'
    }
    else {
        Write-Info 'gradle-wrapper.properties already targets Gradle 8.5.'
    }

    $gradlewBat = Join-Path $ProjectRoot 'gradlew.bat'
    if (-not (Test-Path -LiteralPath $gradlewBat)) {
        throw "gradlew.bat not found at $gradlewBat. Cannot proceed with Gradle tasks."
    }

    Push-Location -LiteralPath $ProjectRoot
    $pushed = $true
    try {
        Invoke-GradleCommand -WorkingDirectory $ProjectRoot -Command '.\gradlew.bat wrapper --gradle-version 8.5' -Description 'Gradle wrapper upgrade'
        Invoke-GradleCommand -WorkingDirectory $ProjectRoot -Command '.\gradlew.bat --stop' -Description 'Gradle daemon stop'
        Invoke-GradleCommand -WorkingDirectory $ProjectRoot -Command '.\gradlew.bat clean' -Description 'Gradle clean'
        Invoke-GradleCommand -WorkingDirectory $ProjectRoot -Command '.\gradlew.bat :app:processDebugGoogleServices --stacktrace' -Description ':app:processDebugGoogleServices'
        Invoke-GradleCommand -WorkingDirectory $ProjectRoot -Command '.\gradlew.bat build --stacktrace' -Description 'Gradle build'
    }
    finally {
        if ($pushed) { Pop-Location }
    }

    $apkPath = Join-Path $ProjectRoot 'app\build\outputs\apk\debug\app-debug.apk'
    if (Test-Path -LiteralPath $apkPath) {
        Write-Success "Build complete. Debug APK: $apkPath"
    }
    else {
        Write-Warn 'Build finished but APK not found at expected location.'
    }

    Write-Host ''
    Write-Info 'Checklist:'
    Write-Host "  - Confirmed JSON path: $appJsonPath"
    Write-Host "  - JSON package: $JsonPackage"
    Write-Host "  - applicationId applied: $finalAppId"
    Write-Host '  - Next commands to install and run:'
    Write-Host '      cmd /c ".\gradlew.bat installDebug"'
    Write-Host "      adb shell monkey -p $finalAppId 1"
}
catch {
    if ($script:ExitCode -eq 0) {
        $script:ExitCode = if ($LASTEXITCODE -ne 0) { $LASTEXITCODE } else { 1 }
    }
    Write-ErrorLog $_.Exception.Message
}
finally {
    if (Get-Variable -Name pushed -Scope Script -ErrorAction SilentlyContinue) {
        if ($pushed) { Pop-Location }
    }
    exit $script:ExitCode
}
