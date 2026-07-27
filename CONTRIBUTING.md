# Contributing

The single most useful contribution to this project is an **erratum**. The
framework moves faster than the book, and a reader who hits a listing that no
longer compiles has information the author does not.

## Filing an erratum

Use the [erratum issue template](.github/ISSUE_TEMPLATE/erratum.yml). Include the
package versions you are running — most errata are version drift rather than
mistakes, and without the versions the report cannot be acted on.

## Working on the book

```bash
git clone https://github.com/konradcinkusz/maf-book.git
cd maf-book
latexmk -pdf main.tex        # full build
latexmk -pvc -pdf main.tex   # rebuild on save while writing
make shots                   # list screenshots still outstanding
```

To work on one chapter, uncomment `\includeonly` in `main.tex`. Cross-references
to other chapters keep resolving as long as `main.aux` exists from a previous
full build.

## House rules

**Versions live in one place.** `preamble.tex` defines `\mafcore` and `\mafext`.
Do not write a version number into a chapter.

**Listings that have not been compiled must say so.** Wrap them in
`\begin{verifybox}`. The CI summary counts these on every build, and nothing
ships to a reader with one still attached. Removing a `verifybox` means you
compiled the listing — not that you read it again and felt confident.

**No em-dashes or smart quotes inside `csharp`, `xmlcode` or `shellcmd`
environments.** `listings` cannot handle multi-byte UTF-8 in verbatim mode. The
preamble maps the common offenders, but ASCII inside listings is safer.

**Prefer measurements to assertions.** The book's differentiator is original
data — provider comparisons, tool-selection accuracy, orchestration benchmarks.
A claim about what is faster or more reliable should come with a method and a
number, or be marked as judgement.

**Screenshots.** Use `\needscreenshot{key}{caption}{what to capture}`. A dashed
placeholder prints until `figures/screenshots/key.png` exists, at which point it
is included automatically. Run the redaction checklist in Appendix D before
committing any capture — no tenant names, endpoints, tokens, or personal paths.

## Style

Prose is British English, second person, and assumes a senior audience. Avoid
marketing register: the book is allowed to say when the framework is the wrong
tool, when documentation is out of date, and when the author has not verified
something.

## Pull requests

The build runs on every pull request. It fails on unresolved cross-references, so
a PR that adds a `\ref` to a label that does not exist will be caught before
review.
