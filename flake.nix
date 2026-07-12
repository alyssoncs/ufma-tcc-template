{
  description = "Template de TCC da UFMA em LaTeX — devShell (rode `just` por cima) e build hermetico do PDF (`nix build`).";

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

        # DICPATH aponta o hunspell para os dicts do flake (sem depender do SO).
        # Reusado pelo devShell (shellHook) e pelo build hermetico (buildPhase).
        dicpath = pkgs.lib.makeSearchPathOutput "out" "share/hunspell" hunspellDicts;

        # Toolchain que roda `just build` (format-check + lint + spell + pdf).
        # texliveFull: xelatex, latexmk, biber, latexindent, chktex,
        # latexminted/Pygments (minted) e a fonte cascadia-code.
        buildTools = [
          pkgs.texliveFull
          pkgs.just
          pkgs.hunspell
        ] ++ hunspellDicts;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = buildTools ++ [
            # Suite pytest dos scripts (`just test`); pytest 9.0.3 neste pin,
            # igual ao scripts/test/requirements.txt. Fora do build hermetico
            # (`just test` nao entra em `just build`).
            pkgs.python3
            pkgs.python3Packages.pytest
            # Analise estatica dos scripts POSIX (`just test`).
            pkgs.shellcheck
          ];

          shellHook = ''
            export DICPATH="${dicpath}"
          '';
        };

        # Build hermetico do PDF: `nix build` roda `just build` numa sandbox sem
        # rede. Diferente do devShell (que so *prove* o toolchain), aqui o Nix
        # *isola* --- cobre format-check + lint + spell + pdf num unico comando.
        # NAO roda `just test` (e para quem mantem o template, nao para o build
        # do artefato).
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          name = "monografia";
          # Exclui artefatos de build para o latexmk nao ver o PDF como
          # "up-to-date" e pular a recompilacao.
          src = pkgs.lib.cleanSourceWith {
            src = ./.;
            filter =
              path: _type:
              let
                base = baseNameOf path;
              in
              !(builtins.elem base [
                "build"
                "output"
              ])
              && !(pkgs.lib.hasPrefix "result" base);
          };

          nativeBuildInputs = buildTools ++ [
            # Sem locale UTF-8 o hunspell falha em palavras acentuadas na sandbox
            # (iconv: ISO8859-1 -> ANSI_X3.4-1968). No devShell/CI nativo o host
            # ja tem locale; aqui precisamos prove-lo.
            pkgs.glibcLocales
          ];

          buildPhase = ''
            runHook preBuild

            # A sandbox tem $HOME nao-gravavel; latexmk/minted precisam escrever
            # cache (build/_minted). TEXMFVAR idem.
            export HOME="$TMPDIR"
            export TEXMFVAR="$TMPDIR/texmf-var"
            export DICPATH="${dicpath}"
            export LANG="en_US.UTF-8"
            export LC_ALL="en_US.UTF-8"
            export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
            mkdir -p "$TEXMFVAR"

            just build

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
            cp output/monografia.pdf "$out/"
            runHook postInstall
          '';
        };
      }
    );
}
