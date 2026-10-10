# Rendering, verification and gotchas

## Rendering

```bash
cd report && quarto render                 # whole book
cd report && quarto render <chapter>.qmd   # one chapter
```

A single-chapter render **never rebuilds `index.html`**. Edit `index.qmd` or `methods.qmd` and
every subsequent chapter-named render leaves their pages stale, silently, for as long as nobody
notices. After editing either, render them by name, or check mtimes:

```bash
cd report
for f in *.qmd; do h=_book/${f%.qmd}.html; [ "$f" -nt "$h" ] && echo "STALE: $h"; done
```

Full renders are slow. Background them properly: a `nohup ... &` inside a short-lived wrapper is
killed with its parent. Use the harness's background execution, or a batch scheduler on a
cluster, then poll for the process to exit rather than sleeping a guessed interval.

Quarto's Jupyter kernel has a **60 s startup timeout**. On a loaded shared machine a cold
pandas/matplotlib import can exceed it, and the render fails with nothing wrong in the document.
Render somewhere with free CPU, or warm the slow imports before calling `quarto render`. If the
report imports library code that pulls in a GPU framework, pin it to CPU in the render
environment.

Jupyter tooling is needed once per environment:

```bash
uv pip install ipykernel nbclient nbformat jupyter-client
```

## "Rendered" is not "correct"

Quarto exits 0 on several kinds of content failure, including a mermaid syntax error and a cell
that runs but emits nothing. Check the output, not the exit code.

- Count the files created against the chapters in `_quarto.yml`.
- "Cell executed" and "cell produced output" are different claims - verify the second:

```bash
grep -c 'class="cell-output' _book/<chapter>.html   # expected number of outputs
grep -c '<table' _book/<chapter>.html               # expected number of tables
grep -c '<img'   _book/<chapter>.html               # expected number of figures
```

`grep -i traceback` on rendered HTML gives false positives from mermaid's bundled JS
(`tracebackGrid`). Those are not render errors.

## Python cell gotchas

**A triple backtick inside a Python cell ends the cell.** Quarto reads ` ``` ` inside an f-string
or any generated string as the cell terminator, truncating it mid-expression and failing the
render with `SyntaxError: incomplete input`. Use inline code in generated markdown, never a
fenced block.

**`Markdown(x)` as the last line of an `if` body displays nothing.** It is not a top-level
expression, so IPython's last-expression auto-display never fires: the cell reports success and
emits nothing. This fails silently. Use a helper of the same arity, so a later edit cannot
change paren balance:

```python
from IPython.display import Markdown, display

def md(text):
    """Display markdown from inside a conditional.

    `Markdown(x)` as the last line of an `if` body is NOT a top-level expression, so
    IPython's auto-display never fires and the table renders empty while the cell
    reports success.
    """
    display(Markdown(text))
```

**Never retype analysis constants in the report - import them.** Build arm tables, parameter
listings and schedules by importing the module that actually runs, so they cannot drift from
what was run. A hardcoded arm list duplicated between an analysis script and a report has
silently dropped every replicate when a new arm was added.

**The report is a second call site for analysis code.** When an output record schema changes,
the analysis script and the report both need the fix. A loop over a record structure that
changed shape raises in the report long after the script was corrected.
