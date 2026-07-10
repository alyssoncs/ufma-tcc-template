# Remove os artefatos de build (build/).
#
# Uso: clean.ps1 <build_dir>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($args.Count -ne 1) {
  [Console]::Error.WriteLine("Uso: clean.ps1 <build_dir>")
  exit 2
}
$buildDir = $args[0]

# Nome vazio aborta antes de remover, para nunca apagar a raiz por engano.
if ([string]::IsNullOrEmpty($buildDir)) {
  [Console]::Error.WriteLine("build_dir: parametro nulo ou nao definido")
  exit 1
}

latexmk -c
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -LiteralPath $buildDir
