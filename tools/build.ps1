param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("android", "ios", "web", "windows", "hap")]
    [string] $Target,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet("dev", "test", "prod")]
    [string] $EnvName,

    [Parameter(Position = 2)]
    [string] $Artifact = "",

    [string] $ApiBase = "",

    [string] $WsUri = "",

    [string] $JPushAppKey = "",

    [string] $BaseHref = "",

    # 仅开发/测试真机联调使用；生产构建禁止携带 HTTP Hybrid Bridge 白名单。
    [string] $HybridTestOrigin = ""
)

# PS 5.1 会把 flutter/dart 等原生命令的 stderr（如 Gradle 弃用 WARNING）包装成 NativeCommandError，
# 配 Stop 会被误判为致命错误而中断构建；真正的失败由下方 exit $LASTEXITCODE 显式校验兜底。
$ErrorActionPreference = "Continue"

function Add-DartDefine {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]] $Args,

        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Value
    )

    if ($Value -ne "") {
        $Args.Add("--dart-define=$Name=$Value")
    }
}

if ($HybridTestOrigin -ne "") {
    if ($EnvName -eq "prod") {
        throw "HybridTestOrigin is only permitted for dev or test builds."
    }
    $hybridUri = $null
    if (-not [System.Uri]::TryCreate($HybridTestOrigin, [System.UriKind]::Absolute, [ref]$hybridUri) -or
        -not $hybridUri.IsAbsoluteUri -or
        [string]::IsNullOrWhiteSpace($hybridUri.Host) -or
        ($hybridUri.Scheme -ne "http" -and $hybridUri.Scheme -ne "https") -or
        $hybridUri.AbsolutePath -ne "/" -or
        -not [string]::IsNullOrEmpty($hybridUri.Query) -or
        -not [string]::IsNullOrEmpty($hybridUri.Fragment)) {
        throw "HybridTestOrigin must be an absolute http(s) origin without path, query, or fragment."
    }
    $HybridTestOrigin = $hybridUri.GetLeftPart([System.UriPartial]::Authority)
}

$flutterArgs = [System.Collections.Generic.List[string]]::new()
$flutterArgs.Add("build")

switch ($Target) {
    "android" {
        if ($Artifact -eq "") {
            $Artifact = "apk"
        }
        if ($Artifact -ne "apk" -and $Artifact -ne "appbundle") {
            throw "Android artifact must be apk or appbundle."
        }
        $flutterArgs.Add($Artifact)
        $flutterArgs.Add("--release")
    }
    "ios" {
        if ($Artifact -eq "") {
            $Artifact = "ipa"
        }
        if ($Artifact -ne "ipa") {
            throw "iOS artifact must be ipa."
        }
        $flutterArgs.Add("ipa")
        $flutterArgs.Add("--release")
    }
    "web" {
        $flutterArgs.Add("web")
        $flutterArgs.Add("--release")
        if ($BaseHref -eq "") {
            if ($EnvName -eq "prod") {
                $BaseHref = "/uploads/app-web/"
            } else {
                $BaseHref = "/"
            }
        }
        $flutterArgs.Add("--base-href")
        $flutterArgs.Add($BaseHref)
    }
    "windows" {
        $flutterArgs.Add("windows")
        $flutterArgs.Add("--release")
    }
    "hap" {
        $flutterArgs.Add("hap")
        $flutterArgs.Add("--release")
    }
}

Add-DartDefine -Args $flutterArgs -Name "APP_ENV" -Value $EnvName
Add-DartDefine -Args $flutterArgs -Name "OPEN_API_BASE" -Value $ApiBase
Add-DartDefine -Args $flutterArgs -Name "OPEN_WS_URI" -Value $WsUri
Add-DartDefine -Args $flutterArgs -Name "OPEN_JPUSH_APPKEY" -Value $JPushAppKey
Add-DartDefine -Args $flutterArgs -Name "OPEN_HYBRID_TEST_ORIGIN" -Value $HybridTestOrigin

Write-Host "Running: flutter $($flutterArgs -join ' ')"
& flutter @flutterArgs
exit $LASTEXITCODE
