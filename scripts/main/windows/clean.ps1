# Remove os artefatos de build (build/) e os caches de teste (__pycache__,
# .pytest_cache) gerados pela suite pytest sob scripts/.
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

# Remove os caches do Python/pytest (__pycache__, .pytest_cache) que a suite de
# testes gera sob scripts/. Sao regenerados a cada `just test`; limpa-los aqui
# evita lixo acumulado. Ausencia de scripts/ (ou de caches) nao e erro.
if (Test-Path -LiteralPath 'scripts') {
  Get-ChildItem -LiteralPath 'scripts' -Recurse -Directory -Force |
    Where-Object { $_.Name -eq '__pycache__' -or $_.Name -eq '.pytest_cache' } |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
