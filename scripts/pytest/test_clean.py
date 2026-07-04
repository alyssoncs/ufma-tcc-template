"""Porta clean.bats: clean.sh e cleanall.sh removem os diretorios certos e,
crucialmente, ABORTAM sem apagar nada quando recebem um argumento vazio (guarda
${var:?}). Esse guard e critico para o port PowerShell.

clean.sh roda `latexmk -c`, que num diretorio sem .tex sai com exit 10 e, sob
'set -eu', abortaria o script antes do `rm -rf`. Por isso stubamos o latexmk.
"""


def test_clean_remove_build_dir(run_script, tmp_path, latexmk_stub):
    build = tmp_path / "build"
    build.mkdir()
    (build / "f.aux").write_text("x")

    result = run_script("clean", "build", cwd=tmp_path, env=latexmk_stub)
    assert result.returncode == 0
    assert not build.exists()


def test_clean_invoca_latexmk_c(run_script, tmp_path, latexmk_spy):
    env, logpath = latexmk_spy
    build = tmp_path / "build"
    build.mkdir()

    result = run_script("clean", "build", cwd=tmp_path, env=env)
    assert result.returncode == 0
    # clean.sh deve rodar `latexmk -c` (limpa aux fora de build/); provamos que o
    # latexmk foi de fato chamado, e com -c, e nao apenas o `rm` do build.
    assert logpath.exists()
    assert "-c" in logpath.read_text()


def test_cleanall_remove_build_e_output(run_script, tmp_path, latexmk_stub):
    build = tmp_path / "build"
    output = tmp_path / "output"
    build.mkdir()
    output.mkdir()
    (build / "f.aux").write_text("x")
    (output / "monografia.pdf").write_text("y")

    result = run_script(
        "cleanall", "build", "output", cwd=tmp_path, env=latexmk_stub
    )
    assert result.returncode == 0
    assert not build.exists()
    assert not output.exists()


def test_clean_arg_vazio_aborta(run_script, tmp_path, latexmk_stub):
    keep = tmp_path / "keepme.txt"
    keep.write_text("keep")

    result = run_script("clean", "", cwd=tmp_path, env=latexmk_stub)
    assert result.returncode != 0
    # A falha e do guard ${build_dir:?} (mensagem cita a variavel), NAO do rm
    # recusando "/". Isso garante que o teste pega a remocao do guard.
    assert "build_dir" in result.stderr
    assert keep.exists()


def test_cleanall_out_dir_vazio_aborta(run_script, tmp_path, latexmk_stub):
    output = tmp_path / "output"
    output.mkdir()
    (output / "monografia.pdf").write_text("keep")

    result = run_script("cleanall", "build", "", cwd=tmp_path, env=latexmk_stub)
    assert result.returncode != 0
    # A falha e do guard ${out_dir:?} (mensagem cita a variavel).
    assert "out_dir" in result.stderr
    # O output nao foi apagado.
    assert (output / "monografia.pdf").exists()


def test_cleanall_build_dir_vazio_aborta(run_script, tmp_path, latexmk_stub):
    output = tmp_path / "output"
    output.mkdir()
    (output / "monografia.pdf").write_text("keep")

    result = run_script("cleanall", "", "output", cwd=tmp_path, env=latexmk_stub)
    assert result.returncode != 0
    # O build_dir vazio e repassado ao clean.sh, cujo guard ${build_dir:?}
    # aborta (mensagem cita a variavel) ANTES de qualquer rm.
    assert "build_dir" in result.stderr
    # cleanall aborta em set -eu antes do rm do out_dir: o output fica intacto.
    assert (output / "monografia.pdf").exists()
