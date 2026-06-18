@default_files = ('monografia.tex');

$pdf_mode = 1;                        # Enable PDF output
$pdflatex = 'xelatex -interaction=nonstopmode %O %S';          # Use XeLaTeX

$aux_dir = 'build';                   # Set auxiliary files directory
$out_dir = 'output';                  # Set output directory

$clean_ext = 'xdv log lof lfs lot blg brf fdb_latexmk aux bbl toc fls synctex.gz';

$clean_full_ext = 'pdf';

$bibtex_use = 2;
$biber = 'biber %O %B';                # Bibliography command (biblatex+biber)

$success_cmd = "echo \"Compiled successfully to $out_dir/%R.pdf\";";
$failure_cmd = "echo \"Compilation failed! Check $aux_dir/%R.log\";";
