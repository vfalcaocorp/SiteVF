# ============================================================
#  comprimir-videos.ps1
#  Gera versoes leves dos videos para o portfolio (pasta web\)
#  - video  : web\<Segmento>\<nome>.mp4   (H.264, ~1080x1920, faststart)
#  - poster : web\<Segmento>\<nome>.jpg   (miniatura da grade)
#
#  Como usar:
#   1. Instale o ffmpeg uma vez:   winget install Gyan.FFmpeg
#      (feche e reabra o PowerShell depois de instalar)
#   2. Clique com o botao direito neste arquivo > "Executar com PowerShell"
#      ou rode:  powershell -ExecutionPolicy Bypass -File .\comprimir-videos.ps1
#   3. Pode rodar de novo quando quiser: ele pula o que ja foi feito.
# ============================================================

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

# checa ffmpeg
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ffmpeg nao encontrado." -ForegroundColor Red
    Write-Host "Instale com:  winget install Gyan.FFmpeg" -ForegroundColor Yellow
    Write-Host "Depois feche e reabra o PowerShell e rode este script de novo."
    Read-Host "Enter para sair"
    exit 1
}

$segmentos = 'Alimentação','Confecção','Contabilidade','Imobiliário','Marketing','Saúde','Shows','Varejo'

# escala: cabe dentro de 1080x1920 mantendo proporcao, dimensoes pares
$vf = "scale=w=1080:h=1920:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2"

$total = 0; $feitos = 0; $pulados = 0

foreach ($seg in $segmentos) {
    if (-not (Test-Path $seg)) { continue }
    $destDir = Join-Path 'web' $seg
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null

    Get-ChildItem -Path $seg -File -Filter *.mp4 | ForEach-Object {
        $total++
        $stem   = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $outMp4 = Join-Path $destDir "$stem.mp4"
        $outJpg = Join-Path $destDir "$stem.jpg"

        if ((Test-Path $outMp4) -and (Test-Path $outJpg)) {
            $pulados++
            Write-Host "  pulado  $seg\$stem" -ForegroundColor DarkGray
            return
        }

        Write-Host "  gerando $seg\$stem ..." -ForegroundColor Cyan

        if (-not (Test-Path $outMp4)) {
            & ffmpeg -y -loglevel error -i $_.FullName `
                -vf $vf -c:v libx264 -preset medium -crf 23 -profile:v high -pix_fmt yuv420p `
                -c:a aac -b:a 160k -movflags +faststart $outMp4
        }
        if (-not (Test-Path $outJpg)) {
            & ffmpeg -y -loglevel error -ss 1 -i $_.FullName `
                -vframes 1 -vf "scale=640:-2" -q:v 3 $outJpg
        }
        $feitos++
    }
}

Write-Host ""
Write-Host "Concluido. $feitos gerados, $pulados ja existiam, $total no total." -ForegroundColor Green
Write-Host "As versoes leves estao em:  $((Resolve-Path 'web').Path)"
Read-Host "Enter para sair"
