# Formata in-place todos os arquivos fonte do projeto com o latexindent.
# Backups e indent.log vao para <root>/<build_dir> (gitignored).
#
# Uso: format.ps1 <root> <build_dir> <out_dir>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($args.Count -ne 3) {
  [Console]::Error.WriteLine("Uso: format.ps1 <root> <build_dir> <out_dir>")
  exit 2
}
$root = $args[0]
$buildDir = $args[1]
$outDir = $args[2]

$files = & "$PSScriptRoot/find-sources.ps1" $root format $buildDir $outDir
foreach ($f in $files) {
  latexindent -w -s -l -m -c "$root/$buildDir/" $f
}
