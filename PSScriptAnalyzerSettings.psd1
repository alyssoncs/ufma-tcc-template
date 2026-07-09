# Configuracao do PSScriptAnalyzer (analogo Windows do shellcheck para os .sh).
# Roda as regras padrao, mas so falha o build em achados de severidade Error ou
# Warning (Information fica de fora). Passado explicitamente via -Settings no
# 'just test [windows]', para valer igual em qualquer maquina, sem depender de
# auto-descoberta.
@{
  IncludeDefaultRules = $true
  Severity            = @('Error', 'Warning')
}
