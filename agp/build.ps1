param([string]$JavaHome = $env:JAVA_HOME, [string]$Task = 'assemble', [string]$UpstreamVersion = '8.12.3')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath "$JavaHome/bin/java.exe")) { throw 'Set JAVA_HOME to a JDK 21 installation.' }
$agpReleases = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'releases.json') -Raw | ConvertFrom-Json
$agpRelease = $agpReleases.PSObject.Properties[$UpstreamVersion].Value
if ($null -eq $agpRelease) { throw "Unsupported exact AGP version: $UpstreamVersion" }
$agpForkVersion = $agpRelease.forkVersion
$agpWork = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../.work/agp'))
New-Item -ItemType Directory -Force -Path $agpWork | Out-Null
$agpGradleVersion = $agpRelease.gradle
$agpGradleZip = Join-Path $agpWork "gradle-$agpGradleVersion-bin.zip"
if (-not (Test-Path -LiteralPath $agpGradleZip)) {
    Invoke-WebRequest "https://services.gradle.org/distributions/gradle-$agpGradleVersion-bin.zip" -OutFile $agpGradleZip
}
if ((Get-FileHash -LiteralPath $agpGradleZip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $agpRelease.gradleSha256) {
    throw 'Gradle distribution checksum mismatch.'
}
$agpGradle = Join-Path $agpWork "gradle-$agpGradleVersion/bin/gradle.bat"
if (-not (Test-Path -LiteralPath $agpGradle)) { Expand-Archive -LiteralPath $agpGradleZip -DestinationPath $agpWork }
$env:JAVA_HOME = $JavaHome
& $agpGradle --no-daemon --max-workers=2 --console=plain --project-dir $PSScriptRoot `
    --project-cache-dir "$agpWork/project-cache-$agpForkVersion" --gradle-user-home "$agpWork/gradle-home" `
    '-Dorg.gradle.jvmargs=-Xmx3g -XX:MaxMetaspaceSize=768m' '-Pkotlin.compiler.execution.strategy=in-process' `
    "-Pkotlin.project.persistent.dir=$agpWork/kotlin-$agpForkVersion" '-Pkotlin.project.persistent.dir.gradle.disableWrite=true' `
    "-PupstreamVersion=$UpstreamVersion" $Task 2>&1 | Tee-Object -FilePath "$agpWork/build-$agpForkVersion.log"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
