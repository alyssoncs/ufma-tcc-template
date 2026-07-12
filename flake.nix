{
  description = "Template de TCC da UFMA em LaTeX — devShell com o toolchain completo (rode `just` por cima).";

  inputs = {
    # Pinado num rev do nixos-unstable cujo python3 default e 3.13, para o
    # latexminted (minted v3) do texliveFull funcionar sem override. O
    # nixos-unstable atual traz python3 3.14, que quebra o latexminted 0.6.0.
    nixpkgs.url = "github:NixOS/nixpkgs/5f85796ab70f9a6ac935b366065d4565288947ac";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Dicionarios hunspell reproduziveis pelo flake.lock (sem download).
        hunspellDicts = [
          pkgs.hunspellDicts.pt_BR
          pkgs.hunspellDicts.en_US
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            # TeX Live completo: xelatex, latexmk, biber, latexindent, chktex,
            # latexminted/Pygments (minted) e a fonte cascadia-code.
            pkgs.texliveFull
            # Orquestrador dos workflows do template.
            pkgs.just
            # Suite pytest dos scripts (`just test`); pytest 9.0.3 neste pin,
            # igual ao scripts/test/requirements.txt.
            pkgs.python3
            pkgs.python3Packages.pytest
            # Analise estatica dos scripts POSIX (`just test`).
            pkgs.shellcheck
            # Spellcheck (`just spell`).
            pkgs.hunspell
          ] ++ hunspellDicts;

          shellHook = ''
            export DICPATH="${pkgs.lib.makeSearchPathOutput "out" "share/hunspell" hunspellDicts}"
          '';
        };
      }
    );
}
