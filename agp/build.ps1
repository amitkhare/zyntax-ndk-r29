param([string]$JavaHome = $env:JAVA_HOME, [string]$Task = 'assemble')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath "$JavaHome/bin/java.exe")) { throw 'Set JAVA_HOME to a JDK 21 installation.' }
$agpWork = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../.work/agp'))
New-Item -ItemType Directory -Force -Path $agpWork | Out-Null
$agpGradleZip = Join-Path $agpWork 'gradle-8.13-bin.zip'
$agpGradleSha256 = '20f1b1176237254a6fc204d8434196fa11a4cfb387567519c61556e8710aed78'
if (-not (Test-Path -LiteralPath $agpGradleZip)) {
    Invoke-WebRequest 'https://services.gradle.org/distributions/gradle-8.13-bin.zip' -OutFile $agpGradleZip
}
if ((Get-FileHash -LiteralPath $agpGradleZip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $agpGradleSha256) {
    throw 'Gradle distribution checksum mismatch.'
}
$agpGradle = Join-Path $agpWork 'gradle-8.13/bin/gradle.bat'
if (-not (Test-Path -LiteralPath $agpGradle)) { Expand-Archive -LiteralPath $agpGradleZip -DestinationPath $agpWork }
$env:JAVA_HOME = $JavaHome
& $agpGradle --no-daemon --max-workers=2 --console=plain --project-dir $PSScriptRoot `
    --project-cache-dir "$agpWork/project-cache" --gradle-user-home "$agpWork/gradle-home" `
    '-Dorg.gradle.jvmargs=-Xmx3g -XX:MaxMetaspaceSize=768m' '-Pkotlin.compiler.execution.strategy=in-process' $Task `
    2>&1 | Tee-Object -FilePath "$agpWork/build.log"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
