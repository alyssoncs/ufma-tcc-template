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

O projeto está configurado de forma que a cada vez que você suba um update aqui no github, o PDF será gerado e salvo na branch `pdf`, ficando fácil de compartilhar com outras pessoas.

## FAQ

* Existe algum TCC real escrito com esse template?
    * Sim: https://github.com/alyssoncs/Monografia

