# ============================================================
#  comprimir-videos.ps1
#  Gera as versoes leves usadas pelo site (pasta web\)
#
#   web\<Setor>\<nome>.mp4   video comprimido, 1080x1920, faststart
#   web\<Setor>\<nome>.jpg   miniatura da grade
#   web\showreel.mp4         fundo do topo do site (se houver showreel.mp4 na raiz)
#
#  Como usar:
#   1. Instale o ffmpeg uma vez:   winget install Gyan.FFmpeg
#      (feche e reabra o PowerShell depois de instalar)
#   2. Botao direito neste arquivo > "Executar com PowerShell"
#      ou:  powershell -ExecutionPolicy Bypass -File .\comprimir-videos.ps1
#   3. Pode rodar quantas vezes quiser: ele pula o que ja foi feito.
#
#  Opcoes:
#   -SomentePosters   refaz so as miniaturas (rapido, nao re-comprime video)
#   -Forcar           refaz tudo, mesmo o que ja existe
# ============================================================

param(
    [switch]$SomentePosters,
    [switch]$Forcar
)

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ffmpeg nao encontrado." -ForegroundColor Red
    Write-Host "Instale com:  winget install Gyan.FFmpeg" -ForegroundColor Yellow
    Write-Host "Depois feche e reabra o PowerShell e rode este script de novo."
    Read-Host "Enter para sair"
    exit 1
}

# cabe dentro de 1080x1920 mantendo a proporcao, com dimensoes pares
$vf = "scale=w=1080:h=1920:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2"

# Pega um frame representativo: 18% da duracao, nunca antes de 1s.
# Evita cair no fade-in preto que quase todo video tem no comeco.
function Get-InstantePoster([string]$arquivo) {
    try {
        $d = & ffprobe -v error -show_entries format=duration -of csv=p=0 $arquivo
        $seg = [double]$d
        if ($seg -gt 0) { return [Math]::Max(1.0, [Math]::Round($seg * 0.18, 2)) }
    } catch { }
    return 1.0
}

$feitos = 0; $pulados = 0; $total = 0

# ---------- 1. videos dos setores ----------
$segmentos = Get-ChildItem -Directory | Where-Object { $_.Name -ne 'web' }

foreach ($segItem in $segmentos) {
    $seg = $segItem.Name
    Write-Host "Pasta: $seg" -ForegroundColor White
    $destDir = Join-Path 'web' $seg
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null

    Get-ChildItem -LiteralPath $segItem.FullName -File -Filter *.mp4 | ForEach-Object {
        $total++
        $stem   = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $outMp4 = Join-Path $destDir "$stem.mp4"
        $outJpg = Join-Path $destDir "$stem.jpg"

        $precisaMp4 = (-not $SomentePosters) -and ($Forcar -or -not (Test-Path -LiteralPath $outMp4))
        $precisaJpg = $Forcar -or $SomentePosters -or (-not (Test-Path -LiteralPath $outJpg))

        if (-not $precisaMp4 -and -not $precisaJpg) {
            $pulados++
            Write-Host "  pulado  $stem" -ForegroundColor DarkGray
            return
        }

        Write-Host "  gerando $stem ..." -ForegroundColor Cyan

        if ($precisaMp4) {
            & ffmpeg -y -loglevel error -i $_.FullName `
                -vf $vf -c:v libx264 -preset medium -crf 27 -maxrate 2200k -bufsize 4400k `
                -profile:v high -pix_fmt yuv420p `
                -c:a aac -b:a 128k -movflags +faststart $outMp4
        }
        if ($precisaJpg) {
            $ss = Get-InstantePoster $_.FullName
            & ffmpeg -y -loglevel error -ss $ss -i $_.FullName `
                -vframes 1 -vf "scale=640:-2" -q:v 3 $outJpg
        }
        $feitos++
    }
}

# ---------- 2. showreel (fundo do topo do site) ----------
# Coloque o arquivo como  showreel.mp4  na raiz desta pasta.
# O fundo e mudo, entao o audio e removido de proposito (deixa o arquivo bem menor).
$showreelOrigem = 'showreel.mp4'
$showreelDest   = Join-Path 'web' 'showreel.mp4'

if (Test-Path -LiteralPath $showreelOrigem) {
    if ($Forcar -or -not (Test-Path -LiteralPath $showreelDest)) {
        Write-Host "Showreel (fundo do topo) ..." -ForegroundColor Cyan
        & ffmpeg -y -loglevel error -i $showreelOrigem `
            -an `
            -vf "scale=w=1440:h=1440:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2" `
            -c:v libx264 -preset medium -crf 30 -maxrate 1800k -bufsize 3600k `
            -profile:v high -pix_fmt yuv420p -movflags +faststart $showreelDest
        Write-Host "  ok: $showreelDest" -ForegroundColor Green
    } else {
        Write-Host "Showreel ja existe (use -Forcar para refazer)." -ForegroundColor DarkGray
    }
} else {
    Write-Host "Sem showreel.mp4 na raiz - o topo do site usa os frames dos trabalhos." -ForegroundColor DarkGray
}

# ---------- 3. aviso sobre o retrato ----------
if (-not (Test-Path -LiteralPath (Join-Path 'web' 'retrato.jpg'))) {
    Write-Host "Sem web\retrato.jpg - a secao Sobre fica sem foto." -ForegroundColor DarkGray
    Write-Host "  Salve sua foto (vertical, 4:5) como web\retrato.jpg" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Concluido. $feitos processados, $pulados pulados, $total no total." -ForegroundColor Green
Write-Host "Saida em: $((Resolve-Path 'web').Path)"
Read-Host "Enter para sair"
