[CmdletBinding()]
param(
  [string]$Version = '',
  [int]$BuildNumber = 0,
  [string]$ReleaseNotes = '',
  [string]$Channel = 'stable',
  [ValidateSet('ObjectStorage', 'Cms')]
  [string]$UploadMode = 'ObjectStorage',
  [string]$AdminBaseUrl = 'http://127.0.0.1:30080/api/v1',
  [string]$AdminUser = 'admin',
  [string]$AdminPassword = '',
  [string]$CmsRepoPath = '',
  [string]$JPushAppKey = 'YOUR_JPUSH_APPKEY',
  [ValidateSet('RequireRelease', 'AllowUnsigned')]
  [string]$SigningPolicy = 'RequireRelease',
  [switch]$SkipBuild,
  [switch]$SkipPublish,
  [switch]$ReuseCurrentVersion,
  [switch]$DryRun
)

# One-shot Android release: bump version -> build prod APK -> upload artifact ->
# create release record -> submit -> verify.
# Release package is ALWAYS an APK (flutter build apk --release). AAB is Google Play only.
# Authoritative docs: open_chat_app/BUILD.md (packaging), open_im_server/docs/standards/15_CLIENT_RELEASE_SKILL.md (this flow).

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$pubspec = Join-Path $root 'pubspec.yaml'
$apkDirectory = Join-Path $root 'build\app\outputs\flutter-apk'

function Fail { param([string]$Msg) Write-Error $Msg; exit 1 }

function Resolve-Apk {
  foreach ($name in @('app-release.apk', 'app-release-unsigned.apk')) {
    $candidate = Join-Path $apkDirectory $name
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }
  Fail "Release APK not found under $apkDirectory"
}

function Get-SigningMetadata {
  param([string]$ApkPath)
  $keyProperties = Join-Path $root 'android\key.properties'
  if (Test-Path -LiteralPath $keyProperties) {
    return [ordered]@{ status = 'release-signed'; source = 'android/key.properties' }
  }
  if ($SigningPolicy -eq 'RequireRelease') {
    Fail 'Release signing is required but android/key.properties is missing. Provide an operator-owned keystore or rerun with -SigningPolicy AllowUnsigned.'
  }
  Write-Warning 'Publishing an UNSIGNED Android release artifact. Users cannot install it until an operator signs it.'
  return [ordered]@{ status = 'unsigned'; source = 'open-source-build'; installable = $false }
}

function Get-AdminToken {
  param([string]$BaseUrl, [string]$User, [string]$Password)
  $uri = "$BaseUrl/auth/login"
  $body = @{ username = $User; password = $Password } | ConvertTo-Json
  $resp = Invoke-RestMethod -Method Post -Uri $uri -ContentType 'application/json' -Body $body
  if (-not $resp.access_token) { Fail 'login returned no access_token' }
  return [string]$resp.access_token
}

function New-AdminHeaders {
  param([string]$Token, [string]$Ver, [switch]$WithIdempotency)
  $h = @{
    Authorization = "Bearer $Token"
    'X-Client-Contract' = 'im-v1'
    'X-Client-Version' = $Ver
    'X-Client-Platform' = 'pc-admin'
  }
  if ($WithIdempotency) { $h['Idempotency-Key'] = [guid]::NewGuid().ToString() }
  return $h
}

# ---- 1. Resolve target version (default: PATCH+1, buildNumber+1) ----
$line = (Select-String -Path $pubspec -Pattern '^version:\s*(\S+)').Line
if (-not $line) { Fail "version line not found in $pubspec" }
$m = [regex]::Match($line, '^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)')
if (-not $m.Success) { Fail "cannot parse version from: $line" }
$curMajor = [int]$m.Groups[1].Value
$curMinor = [int]$m.Groups[2].Value
$curPatch = [int]$m.Groups[3].Value
$curBuild = [int]$m.Groups[4].Value

$newVersion = $Version
$newBuild = $BuildNumber
if ($ReuseCurrentVersion) {
  if (($Version -and $Version -ne "$curMajor.$curMinor.$curPatch") -or ($BuildNumber -and $BuildNumber -ne $curBuild)) {
    Fail 'ReuseCurrentVersion cannot be combined with a different Version or BuildNumber.'
  }
  $newVersion = "$curMajor.$curMinor.$curPatch"
  $newBuild = $curBuild
}
if (-not $ReuseCurrentVersion -and -not $newVersion) {
  if ($BuildNumber -gt 0 -and $BuildNumber -le $curBuild) { Fail "buildNumber must be greater than current $curBuild" }
  $newVersion = "$curMajor.$curMinor.$($curPatch + 1)"
} elseif ($newVersion -notmatch '^\d+\.\d+\.\d+$') {
  Fail "Version must be X.Y.Z (got: $newVersion)"
}
if (-not $newBuild) { $newBuild = $curBuild + 1 }
if (-not $ReuseCurrentVersion -and $newBuild -le $curBuild) { Fail "buildNumber must increase: current $curBuild, requested $newBuild" }

Write-Host "== version: $curMajor.$curMinor.$curPatch+$curBuild -> $newVersion+$newBuild"

# ---- 2. Bump pubspec.yaml (UTF-8 no BOM) ----
# Read as UTF-8 to preserve non-ASCII comments in pubspec.yaml.
$content = [System.IO.File]::ReadAllText($pubspec, [System.Text.Encoding]::UTF8)
$content = [regex]::Replace($content, '(?m)^version:\s*[^\r\n]*', "version: $newVersion+$newBuild")
if ($ReuseCurrentVersion) {
  Write-Host '== reusing current pubspec version'
} elseif ($DryRun) {
  Write-Host '[dry-run] would bump pubspec.yaml'
} else {
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($pubspec, $content, $utf8)
  Write-Host '== pubspec.yaml bumped'
}

# ---- 3. Build prod APK ----
if ($SkipBuild) {
  Write-Host '== SkipBuild: reuse existing APK'
} elseif ($DryRun) {
  Write-Host '[dry-run] would run: tools/build.ps1 android prod apk -JPushAppKey ...'
} else {
  Write-Host '== building prod APK ...'
  Push-Location $root
  try {
    & (Join-Path $root 'tools\build.ps1') android prod apk -JPushAppKey $JPushAppKey
    if ($LASTEXITCODE -ne 0) { Fail 'flutter build failed' }
  } finally { Pop-Location }
}

$apk = Resolve-Apk
$signingMetadata = Get-SigningMetadata -ApkPath $apk
Write-Host "== APK: $apk"
Write-Host "== signing: $($signingMetadata.status)"

# ---- 4. Upload artifact / resolve downloadUrl + sha256 + sizeBytes ----
$downloadUrl = ''
$sha256 = ''
$sizeBytes = [long]0

if ($UploadMode -eq 'Cms') {
  if (-not $CmsRepoPath) { Fail 'CmsRepoPath is required when UploadMode=Cms' }
  $sha256 = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
  $sizeBytes = (Get-Item -LiteralPath $apk).Length
  $target = Join-Path $CmsRepoPath "html\download\open-chat-$newVersion.apk"
  if ($DryRun) {
    Write-Host "[dry-run] would copy APK to $target"
  } else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $apk -Destination $target -Force
  }
  $downloadUrl = "download/open-chat-$newVersion.apk"
  Write-Host "== CMS artifact: $downloadUrl ($sizeBytes bytes, sha256=$sha256)"
} else {
  if ($SkipPublish) {
    Write-Host '== SkipPublish: upload skipped'
  } else {
    $password = $AdminPassword
    if (-not $password) { $password = $env:OPEN_ADMIN_PASSWORD }
    if (-not $password) { Fail 'Admin password required: -AdminPassword or env OPEN_ADMIN_PASSWORD' }
    if ($DryRun) {
      Write-Host '[dry-run] would login and upload APK via object storage'
    } else {
      $token = Get-AdminToken -BaseUrl $AdminBaseUrl -User $AdminUser -Password $password
      Write-Host '== uploading APK via object storage (presigned) ...'
      $artifactFileName = "open-chat-$newVersion.apk"
      $contentType = 'application/vnd.android.package-archive'
      $headers = @{
        Authorization = "Bearer $token"
        'X-Client-Contract' = 'im-v1'
        'X-Client-Version' = $newVersion
        'X-Client-Platform' = 'pc-admin'
      }

      # 1) 创建直传会话（Invoke-RestMethod 传 JSON，避免 curl 在 PS 5.1 下引号损坏）
      $session = Invoke-RestMethod -Method Post -Uri "$AdminBaseUrl/admin/client-releases/artifacts/upload-sessions" -Headers $headers -ContentType 'application/json' -Body (@{ platform = 'android'; fileName = $artifactFileName; contentType = $contentType } | ConvertTo-Json)
      $objectKey = [string]$session.objectKey
      $uploadUrl = [string]$session.uploadUrl
      if (-not $objectKey -or -not $uploadUrl) { Fail 'invalid upload session' }

      # 2) 预签名 PUT 直传（二进制，用 curl --upload-file 高效上传大文件）
      & curl.exe -sS -f -X PUT -H "Content-Type: $contentType" --upload-file $apk $uploadUrl
      if ($LASTEXITCODE -ne 0) { Fail 'artifact presigned PUT failed' }

      # 3) 完成直传，取 downloadUrl / sha256 / sizeBytes
      $complete = Invoke-RestMethod -Method Post -Uri "$AdminBaseUrl/admin/client-releases/artifacts/upload-sessions/complete" -Headers $headers -ContentType 'application/json' -Body (@{ platform = 'android'; fileName = $artifactFileName; contentType = $contentType; objectKey = $objectKey } | ConvertTo-Json)
      $downloadUrl = [string]$complete.downloadUrl
      $sha256 = [string]$complete.sha256
      $sizeBytes = [long]$complete.sizeBytes
      Write-Host "== object-storage artifact: $downloadUrl ($sizeBytes bytes)"
    }
  }
}

# ---- 5. Create + submit release record ----
if ($SkipPublish) {
  Write-Host '== SkipPublish: release record not created'
} elseif ($DryRun) {
  Write-Host "[dry-run] would create+submit release record on channel=$Channel version=$newVersion build=$newBuild"
} else {
  if (-not $downloadUrl -or -not $sha256 -or $sizeBytes -le 0) { Fail 'artifact fields incomplete' }
  if (-not $ReleaseNotes) { Fail 'ReleaseNotes is required to publish' }

  $password = $AdminPassword
  if (-not $password) { $password = $env:OPEN_ADMIN_PASSWORD }
  if (-not $password) { Fail 'Admin password required: -AdminPassword or env OPEN_ADMIN_PASSWORD' }
  $token = Get-AdminToken -BaseUrl $AdminBaseUrl -User $AdminUser -Password $password

  # Build JSON explicitly so the single-element 'artifacts' is always a JSON array:
  # PowerShell ConvertTo-Json unwraps single-element arrays, which would break the
  # backend List<ArtifactRequest> deserialization.
  $signingJson = $signingMetadata | ConvertTo-Json -Compress
  $signingJsonLiteral = $signingJson | ConvertTo-Json -Compress
  $artifactJson = '{"architecture":"universal","packageType":"apk","downloadUrl":' + ($downloadUrl | ConvertTo-Json -Compress) + ',"sha256":' + ($sha256 | ConvertTo-Json -Compress) + ',"sizeBytes":' + $sizeBytes + ',"signingMetadata":' + $signingJsonLiteral + '}'
  $compatJson = @{ protocolVersion = 'v1'; minimumServerCapabilityVersion = 1 } | ConvertTo-Json -Depth 5
  $notesJson = $ReleaseNotes | ConvertTo-Json
  $reasonJson = '直接发布' | ConvertTo-Json
  $createBody = '{' + ('"platform":"android"') + (',"channel":"' + $Channel + '"') + (',"version":"' + $newVersion + '"') + (',"buildNumber":' + $newBuild) + ',"mandatory":false' + (',"releaseNotes":' + $notesJson) + ',"storeUrl":null' + (',"compatibility":' + $compatJson) + (',"artifacts":[' + $artifactJson + ']') + (',"reason":' + $reasonJson) + '}'

  $headers = New-AdminHeaders -Token $token -Ver $newVersion -WithIdempotency
  # Send releaseNotes/reason as UTF-8 bytes (PS 5.1 string bodies fall back to ANSI/ASCII and mangle non-ASCII).
  $createBytes = [System.Text.Encoding]::UTF8.GetBytes($createBody)
  try {
    $created = Invoke-RestMethod -Method Post -Uri "$AdminBaseUrl/admin/client-releases" -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $createBytes
  } catch {
    $response = $_.Exception.Response
    if ($response -and $response.GetResponseStream()) {
      $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
      $detail = $reader.ReadToEnd()
      Fail "release record creation failed: $detail"
    }
    throw
  }
  $releaseId = [long]$created.data.id
  $rowVersion = [long]$created.data.rowVersion

  $submitBody = @{
    expectedRowVersion = $rowVersion
    reason = '直接发布'
    initialRolloutPercent = 100
  } | ConvertTo-Json -Depth 10

  $headers = New-AdminHeaders -Token $token -Ver $newVersion -WithIdempotency
  $submitBytes = [System.Text.Encoding]::UTF8.GetBytes($submitBody)
  $submitted = Invoke-RestMethod -Method Post -Uri "$AdminBaseUrl/admin/client-releases/$releaseId/submit" -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $submitBytes
  Write-Host "== release record created id=$releaseId status=$($submitted.data.status)"
}

# ---- 6. Verify ----
if ($DryRun -or $SkipPublish) { exit 0 }
$latest = Invoke-RestMethod -Method Get -Uri "$AdminBaseUrl/client/releases/latest?platform=android&channel=$Channel"
$lv = $latest.data.version
$lb = $latest.data.buildNumber
$ls = $latest.data.status
Write-Host "== latest: version=$lv buildNumber=$lb status=$ls"
if ($lv -ne $newVersion -or [long]$lb -ne [long]$newBuild) {
  Write-Warning "latest release ($lv+$lb) does not match target ($newVersion+$newBuild)"
} else {
  Write-Host "== RELEASE OK: $newVersion+$newBuild ($Channel)"
}
