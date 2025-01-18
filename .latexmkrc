@default_files = ('monografia.tex');

$pdf_mode = 1;                        # Enable PDF output
$pdflatex = 'xelatex %O %S';          # Use XeLaTeX

$aux_dir = 'build';                   # Set auxiliary files directory
$out_dir = 'output';                  # Set output directory

$clean_ext = 'xdv log lof lfs log lot blg brf fdb_latexmk aux bbl toc xdv fls synctex.gz';

$clean_full_ext = 'pdf';

$bibtex_use = 2;
$bibtex = 'bibtex %O %B';             # Bibliography command

$success_cmd = 'echo "Compiled successfully to build/monografia.pdf";';
$failure_cmd = 'echo "Compilation failed! Check build/monografia.log";';

