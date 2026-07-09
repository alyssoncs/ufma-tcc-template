# Corretor ortografico. Roda o hunspell em modo LaTeX (-t) sobre cada arquivo
# .tex, reportando as palavras desconhecidas por arquivo. Verifica todos os
# arquivos antes de decidir o resultado: se algum tiver erros, falha (exit 1)
# ao final, depois de ter listado tudo.
#
# O hunspell em modo LaTeX (-t) pula \verb e ambientes verbatim conhecidos, mas
# NAO conhece o pacote minted: sem tratamento, todo o codigo dentro de blocos
# \begin{minted}...\end{minted} viraria "erro de ortografia". Por isso esses
# blocos sao removidos antes de passar o texto ao hunspell.
#
# Uso: spell.ps1 <lang> <dict> <arquivo.tex>...
#   lang   dicionarios do hunspell (ex.: pt_BR,en_US)
#   dict   dicionario do projeto, palavras validas (ex.: dictionary.txt)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($args.Count -lt 3) {
  [Console]::Error.WriteLine("Uso: spell.ps1 <lang> <dict> <arquivo.tex>...")
  exit 2
}

$lang = $args[0]
$dict = $args[1]
$files = $args[2..($args.Count - 1)]

# Garante UTF-8 na comunicacao com o hunspell (-i utf-8).
$OutputEncoding = [System.Text.Encoding]::UTF8

# Remove os blocos de codigo do minted (inclusive as linhas \begin/\end) para
# que o hunspell nao tente corrigir o conteudo das listagens.
function Skip-MintedBlock($path) {
  $skip = $false
  foreach ($line in Get-Content -LiteralPath $path) {
    if ($line -match '\\begin\{minted\}') { $skip = $true }
    if (-not $skip) { $line }
    if ($line -match '\\end\{minted\}') { $skip = $false }
  }
}

$status = 0
foreach ($f in $files) {
  $words = @(
    Skip-MintedBlock $f |
      hunspell -t -l -i utf-8 -d $lang -p $dict |
      Sort-Object -Unique -CaseSensitive
  )
  if ($words.Count -gt 0) {
    $status = 1
    Write-Output "== $f =="
    foreach ($w in $words) { Write-Output "  $w" }
  }
}

if ($status -ne 0) {
  Write-Output "Erros de ortografia encontrados. Corrija-os ou, se forem termos validos,"
  Write-Output "adicione-os (1 por linha) em $dict."
}
exit $status
