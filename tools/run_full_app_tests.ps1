param(
    [Parameter(Mandatory = $true)]
    [string]$Device,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [string]$ConversationName,
    [string]$PeerId,

    [ValidateSet("private", "group", "channel", "secret")]
    [string]$ChatType = "group",

    [ValidateSet("dev", "test", "prod")]
    [string]$AppEnvironment = "prod",

    [string]$ApiBase = "https://api.dev.example.com",
    [string]$WebSocketUri = "wss://api.dev.example.com/ws/im/v1",
    [string]$MediaBase = "https://api.dev.example.com",
    [string]$JPushAppKey = "",

    [switch]$AllowSend,
    [switch]$AllowCamera
)

if (([string]::IsNullOrWhiteSpace($ConversationName)) -and ([string]::IsNullOrWhiteSpace($PeerId))) {
    throw "A dedicated test conversation is required. Use -ConversationName or -PeerId."
}

$jpushProduction = "false"
if ($AppEnvironment -eq "prod") {
    $jpushProduction = "true"
}

$runnerArguments = @(
    "run",
    "tools/run_integration_tests.dart",
    "--device=$Device",
    "--target=integration_test",
    "--dart-define=APP_ENV=$AppEnvironment",
    "--dart-define=OPEN_API_BASE=$ApiBase",
    "--dart-define=OPEN_WS_URI=$WebSocketUri",
    "--dart-define=OPEN_MEDIA_BASE=$MediaBase",
    "--dart-define=OPEN_JPUSH_PRODUCTION=$jpushProduction",
    "--dart-define=OPEN_TEST_USERNAME=$Username",
    "--dart-define=OPEN_TEST_PASSWORD=$Password",
    "--dart-define=OPEN_TEST_CHAT_TYPE=$ChatType"
)

if (-not [string]::IsNullOrWhiteSpace($ConversationName)) {
    $runnerArguments += "--dart-define=OPEN_TEST_CONVERSATION_NAME=$ConversationName"
}
if (-not [string]::IsNullOrWhiteSpace($PeerId)) {
    $runnerArguments += "--dart-define=OPEN_TEST_PEER_ID=$PeerId"
}
if (-not [string]::IsNullOrWhiteSpace($JPushAppKey)) {
    $runnerArguments += "--dart-define=OPEN_JPUSH_APPKEY=$JPushAppKey"
}
if ($AllowSend) {
    $runnerArguments += "--dart-define=OPEN_TEST_ALLOW_SEND=true"
}
if ($AllowCamera) {
    $runnerArguments += "--dart-define=OPEN_TEST_ALLOW_CAMERA=true"
}

& dart @runnerArguments
exit $LASTEXITCODE
