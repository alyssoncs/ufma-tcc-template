# Corretor ortografico. Roda o hunspell em modo LaTeX (-t) sobre cada arquivo
# .tex, reportando as palavras desconhecidas por arquivo. Verifica todos os
# arquivos antes de decidir o resultado: se algum tiver erros, falha (exit 1)
# ao final, depois de ter listado tudo.
#
# O hunspell em modo LaTeX (-t) pula \verb e ambientes verbatim conhecidos, mas
# NAO conhece o pacote minted: sem tratamento, todo o codigo dentro de blocos
# \begin{minted}...\end{minted} viraria "erro de ortografia". Por isso esses
# blocos --- e os argumentos de comandos de citacao (chaves do biblatex) --- sao
# removidos antes de passar o texto ao hunspell.
#
# Antes de corrigir, valida que TODOS os dicionarios do hunspell carregam; se
# algum faltar, falha (exit 3) em vez de checar so parte dos idiomas em silencio.
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

# Defesa: se chamado via `pwsh -Command` (como o `just` faz), um argumento sem
# aspas com virgula (pt_BR,en_US) chega como ARRAY (operador virgula), nao
# string. Passar o array ao hunspell o espalha em -d pt_BR en_US, carregando so
# o pt_BR e tratando en_US como arquivo de entrada ("Can't open en_US."). Reunir
# num unico argumento com virgula (no-op quando ja e string).
$lang = @($lang) -join ','

# Garante que TODOS os dicionarios do hunspell carregam antes de corrigir. Um
# dicionario ausente/ilegivel faz o hunspell seguir so com os que abriu e sair 0
# --- as vezes sem nada no stderr ---, mascarando um idioma nao verificado como
# sucesso (falso verde). Checamos cada idioma isolado (o -d <lang> sozinho sai
# != 0 se nao achar os arquivos) e tambem o uso combinado (alguns builds abrem
# cada idioma isolado mas emitem "Can't open <lang>." no stderr no modo
# -d a,b). Retorna $false se qualquer verificacao acusar dicionario faltando.
function Assert-DictsLoad($langs) {
  # Local ao escopo da funcao: nao deixa o exit code != 0 do hunspell (dict
  # ausente) virar excecao, para podermos inspecionar $LASTEXITCODE.
  $ErrorActionPreference = 'Continue'
  $PSNativeCommandUseErrorActionPreference = $false

  foreach ($l in $langs.Split(',')) {
    '' | hunspell -d $l -l 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
      [Console]::Error.WriteLine("Erro: o dicionario do hunspell '$l' nao pode ser carregado (-d $l).")
      [Console]::Error.WriteLine("Verifique a instalacao do dicionario e o DICPATH.")
      return $false
    }
  }

  $combinedErr = @(
    '' | hunspell -d $langs -l 2>&1 |
      Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } |
      ForEach-Object { $_.ToString() }
  ) -join "`n"
  if ($combinedErr -match "(?i)can't open") {
    [Console]::Error.WriteLine("Erro: o hunspell nao carregou todos os dicionarios de '-d $langs':")
    foreach ($line in ($combinedErr -split "`n")) { [Console]::Error.WriteLine("  $line") }
    return $false
  }
  return $true
}

if (-not (Assert-DictsLoad $lang)) {
  exit 3
}

# Garante UTF-8 na comunicacao com o hunspell (-i utf-8).
$OutputEncoding = [System.Text.Encoding]::UTF8

# Prepara cada arquivo para o hunspell, removendo o que nao deve ser corrigido:
# os blocos \begin{minted}...\end{minted} (codigo das listagens) e os argumentos
# de comandos de citacao (\cite, \textcite, \parencite, ...), que sao chaves do
# biblatex, nao prosa. O hunspell so pula esses comandos nas versoes novas
# (1.7.2); o build antigo do Windows (winget FSFhu, ~1.7.0) nao conhece
# \textcite/\autocite e marcaria as chaves --- removemos aqui para ficar
# consistente entre plataformas.
function Skip-MintedBlock($path) {
  $skip = $false
  foreach ($line in Get-Content -LiteralPath $path) {
    if ($line -match '\\begin\{minted\}') { $skip = $true }
    if (-not $skip) {
      $line -replace '\\[a-zA-Z]*[Cc]ite[a-zA-Z]*\{[^{}]*\}', ' '
    }
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
