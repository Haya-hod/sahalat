# Build Sahalat web for sharing with clients.
# Usage (from repo root, or pass -ProjectRoot):
#   .\scripts\publish-for-clients.ps1 -Mode StaticHost
#   .\scripts\publish-for-clients.ps1 -Mode Xampp
#
# StaticHost: base href / - upload build\web to Netlify / Cloudflare Pages / any static host.
# Xampp:      base href /sahalat/ - mirrors to XAMPP htdocs\sahalat (for localhost + cloudflared).

param(
    [ValidateSet('StaticHost', 'Xampp')]
    [string] $Mode = 'StaticHost',

    [string] $ProjectRoot = '',

    [string] $XamppSahalatPath = 'c:\xampp\htdocs\sahalat',

    [string] $FlutterBat = ''
)

$ErrorActionPreference = 'Stop'

if (-not $ProjectRoot) {
    # This file lives in <project>/scripts/
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
    if (-not (Test-Path (Join-Path $ProjectRoot 'pubspec.yaml'))) {
        Write-Error "pubspec.yaml not found under $ProjectRoot - run from Sahalat Flutter project or pass -ProjectRoot"
    }
}

Set-Location $ProjectRoot

if (-not $FlutterBat) {
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        $FlutterExe = 'flutter'
    } elseif (Test-Path 'C:\src\flutter\bin\flutter.bat') {
        $FlutterExe = 'C:\src\flutter\bin\flutter.bat'
    } else {
        Write-Error "Flutter not found. Install Flutter or set -FlutterBat to flutter.bat"
    }
} else {
    $FlutterExe = $FlutterBat
}

$baseHref = if ($Mode -eq 'Xampp') { '/sahalat/' } else { '/' }

Write-Host ('Building web (Mode={0}, base-href={1})...' -f $Mode, $baseHref) -ForegroundColor Cyan
& $FlutterExe pub get
& $FlutterExe build web --release --base-href $baseHref

$webOut = Join-Path $ProjectRoot 'build\web'
if (-not (Test-Path $webOut)) {
    Write-Error "Build output missing: $webOut"
}

if ($Mode -eq 'Xampp') {
    $ht = Join-Path $XamppSahalatPath '.htaccess'
    $bak = $null
    if (Test-Path $ht) { $bak = Get-Content $ht -Raw }
    Write-Host "Mirroring to $XamppSahalatPath ..." -ForegroundColor Cyan
    robocopy $webOut $XamppSahalatPath /MIR /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($bak) { Set-Content -Path $ht -Value $bak -NoNewline }
    Write-Host ""
    Write-Host "Done. Local: http://127.0.0.1/sahalat/#/splash" -ForegroundColor Green
    Write-Host "Share via Cloudflare Quick Tunnel (install cloudflared), then run:" -ForegroundColor Yellow
    Write-Host "  cloudflared tunnel --url http://127.0.0.1:80" -ForegroundColor White
    Write-Host "Open the printed https URL with path: /sahalat/#/splash" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Build folder (upload this entire folder):" -ForegroundColor Green
    Write-Host "  $webOut" -ForegroundColor White
    Write-Host ""
    Write-Host "Easy options for clients:" -ForegroundColor Cyan
    Write-Host "  1) Netlify Drop: https://app.netlify.com/drop - drag the 'web' folder here." -ForegroundColor White
    Write-Host "  2) Cloudflare Pages: Dashboard -> Workers & Pages -> Create -> Upload assets -> upload zip of 'web'." -ForegroundColor White
    Write-Host "  3) After deploy, share: https://YOUR-SITE.netlify.app/#/splash (hash routes, no extra server config)." -ForegroundColor White
}
