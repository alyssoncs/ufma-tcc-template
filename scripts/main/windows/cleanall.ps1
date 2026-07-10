# Remove os artefatos de build (build/) e o PDF final (output/).
#
# Uso: cleanall.ps1 <build_dir> <out_dir>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($args.Count -ne 2) {
  [Console]::Error.WriteLine("Uso: cleanall.ps1 <build_dir> <out_dir>")
  exit 2
}
$buildDir = $args[0]
$outDir = $args[1]

& "$PSScriptRoot/clean.ps1" $buildDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Nome vazio aborta antes de remover, para nunca apagar a raiz por engano.
if ([string]::IsNullOrEmpty($outDir)) {
  [Console]::Error.WriteLine("out_dir: parametro nulo ou nao definido")
  exit 1
}

Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -LiteralPath $outDir
