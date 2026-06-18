# Template de TCC da UFMA em LaTeX seguindo as normas ABNT

## Como usar esse template

O tutorial de como usar esse template se encontra [nesse PDF](https://github.com/alyssoncs/ufma-tcc-template/blob/pdf/monografia.pdf).

tl;dr: Crie uma cópia desse projeto e mude o conteúdo para o seu trabalho, a maior parte da formatação vai ser feita pelo LaTeX.

Se você tem um distribuição LaTeX na sua máquina, você deve ser capaz de rodar o comando `make` para compilar o projeto.

- O PDF final será gerado no diretório `output/`.
- Os arquivos auxiliares ficam no diretório `build/`. Esses são arquivos temporários que o LaTeX cria durante a compilação (índices, referências cruzadas, logs, etc.) — você não precisa se preocupar com eles, mas se algo der errado, o log de erros estará em `build/`.

Também pode ser usado o comando `make continuous` para ficar compilando continuamente a cada mudança.

Você também pode usar overleaf ou outras soluções para compilar o projeto.

## CI/CD

O projeto vem com um workflow do GitHub Actions que automatiza a compilação e publicação do PDF. Funciona assim:

- A cada push na branch `master`, o projeto é compilado automaticamente.
- Se a compilação for bem-sucedida, o PDF é publicado na branch `pdf` do repositório, ficando fácil de compartilhar com outras pessoas.
- Pull requests também disparam a compilação, mas sem fazer deploy.

> **Nota:** O deploy só é disparado por pushes na branch `master`. Se o seu fork usa `main` como branch padrão, renomeie para `master` ou ajuste o arquivo `.github/workflows/ci.yaml`.

## FAQ

* Existe algum TCC real escrito com esse template?
    * Sim: https://github.com/alyssoncs/Monografia
