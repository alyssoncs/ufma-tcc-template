# Verifica a formatacao dos arquivos fonte sem altera-los. Falha (exit 1) assim
# que encontra um arquivo que precisaria ser reformatado pelo latexindent.
#
# Uso: format-check.ps1 <root> <build_dir> <out_dir>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($args.Count -ne 3) {
  [Console]::Error.WriteLine("Uso: format-check.ps1 <root> <build_dir> <out_dir>")
  exit 2
}
$root = $args[0]
$buildDir = $args[1]
$outDir = $args[2]

$files = & "$PSScriptRoot/find-sources.ps1" $root format $buildDir $outDir
foreach ($f in $files) {
  latexindent -k -s -l -m -c "$root/$buildDir/" $f | Out-Null
  if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine("Fora de formatacao: $f (rode 'just format')")
    exit 1
  }
}
