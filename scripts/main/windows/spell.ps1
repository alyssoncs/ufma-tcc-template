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
# Alem disso, as CHAVES de comandos de citacao/remissao (\cite, \textcite,
# \ref, \label, ...) sao identificadores do biblatex/LaTeX (ex.: "knuth:goto"),
# nao palavras. Versoes novas do hunspell (>=1.7.1) pulam esses comandos e seus
# argumentos no modo -t, mas a 1.7.0 (usada no job Windows do CI) NAO pula, e
# reporta os fragmentos da chave como erros. Para o resultado ser deterministico
# entre versoes, removemos os argumentos desses comandos aqui antes de passar o
# texto ao hunspell -- do mesmo modo que fazemos com os blocos minted.
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

# O hunspell aceita varios idiomas de uma vez (`-d pt_BR,en_US`), mas se UM
# deles faltar ele carrega SO os que achou e SAI 0 -- sem sinalizar a ausencia
# parcial. Isso mascara um falso verde (ex.: no Windows o en_US some, o pt_BR
# fica, e o ingles nunca chega a ser checado). Por isso validamos cada idioma
# individualmente ANTES de rodar o spellcheck: `hunspell -d <lang>` sai != 0
# quando aquele dicionario nao existe. Sondamos com uma palavra qualquer na
# entrada, so para exercitar o carregamento do dicionario; a saida e descartada.
foreach ($one in ($lang -split ',')) {
  "x" | hunspell -l -i utf-8 -d $one *> $null
  if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine("spell: dicionario do hunspell ausente ou ilegivel: $one")
    exit 3
  }
}

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

# Remove os argumentos dos comandos de citacao/remissao (\cite, \textcite,
# \ref, \label, ...), incluindo a variante estrela (\textcite*) e os argumentos
# opcionais ([...]), para que os fragmentos das chaves nao virem "erros de
# ortografia" no hunspell 1.7.0. Ver o cabecalho para o porque.
function Skip-CitationArg($lines) {
  $pattern = '\\(textcite|autocite|parencite|footcite|nocite|cite|autoref|pageref|eqref|ref|label)\*?[ \t]*(\[[^\]]*\])*\{[^}]*\}'
  foreach ($line in $lines) {
    $prev = $null
    $cur = $line
    while ($cur -ne $prev) {
      $prev = $cur
      $cur = [regex]::Replace($cur, $pattern, '')
    }
    $cur
  }
}

$status = 0
foreach ($f in $files) {
  $out = Skip-CitationArg (Skip-MintedBlock $f) | hunspell -t -l -i utf-8 -d $lang -p $dict
  $hrc = $LASTEXITCODE
  if ($hrc -ne 0) {
    exit $hrc
  }
  $words = @($out | Sort-Object -Unique -CaseSensitive)
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
