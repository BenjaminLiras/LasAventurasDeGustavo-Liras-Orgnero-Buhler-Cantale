param([string]$Godot = 'godot')

$ErrorActionPreference = 'Stop'
$raizProyecto = Split-Path $PSScriptRoot -Parent
Push-Location $raizProyecto
try {
    New-Item -ItemType Directory -Path build/web -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $raizProyecto 'build/.gdignore'), '')
    & $Godot --headless --path . --export-release LasAventurasDeGustavo build/web/index.html
    if ($LASTEXITCODE -ne 0) { throw 'Godot no pudo exportar. Revisar sus mensajes y las plantillas Web de la misma versión.' }
    foreach ($archivoWeb in @('index.html', 'index.js', 'index.wasm', 'index.pck')) {
        $rutaArchivoWeb = Join-Path 'build/web' $archivoWeb
        if (!(Test-Path -LiteralPath $rutaArchivoWeb) -or (Get-Item -LiteralPath $rutaArchivoWeb).Length -eq 0) {
            throw "La exportación está incompleta: falta $archivoWeb."
        }
    }
    Compress-Archive -Path build/web/* -DestinationPath build/gustavo_web.zip -Force
    Write-Host 'Listo: build/gustavo_web.zip. Subir el ZIP completo a itch.io como HTML y marcar Jugar en navegador.'
} finally {
    Pop-Location
}
