# Microsoft Agent Framework for .NET Engineers

[![Build](https://github.com/konradcinkusz/maf-book/actions/workflows/build.yml/badge.svg)](https://github.com/konradcinkusz/maf-book/actions/workflows/build.yml)
[![PDF](https://img.shields.io/badge/PDF-download-1F4E79)](https://github.com/konradcinkusz/maf-book/releases/latest/download/MAF-for-dotnet-Engineers.pdf)
[![Text: CC BY-NC-SA 4.0](https://img.shields.io/badge/text-CC%20BY--NC--SA%204.0-0E7C7B)](LICENSE-CONTENT)
[![Code: MIT](https://img.shields.io/badge/code-MIT-B26A00)](LICENSE)

A practitioner's guide to **Microsoft Agent Framework 1.0** for .NET: agents,
tools, MCP, graph-based workflows, multi-agent orchestration, middleware,
observability and hosting.

Written for engineers who have shipped ASP.NET Core services and are now being
asked to put an agent into production — not as an introduction to large language
models.

> **This is a draft.** Chapters 1–3 and all four appendices are written; the rest
> exist as outlines and compile as part of the book. Listings transcribed from
> documentation rather than compiled against the SDK carry a visible *"Compile
> before you trust this"* marker, and the outstanding count is published on every
> build.

**[Download the latest PDF](https://github.com/konradcinkusz/maf-book/releases/latest/download/MAF-for-dotnet-Engineers.pdf)** ·
**[Website](https://konradcinkusz.github.io/maf-book/)**

---

## What is covered

| Part | Chapters |
|---|---|
| **I — Foundations** | The Landscape · Your First Agent · Tools, MCP and Skills · Memory, Context and State |
| **II — Workflows** | Executors and Edges · Durability and Control · Multi-Agent Orchestration |
| **III — Production** | Middleware and Observability · Evaluation · Hosting, Durability and A2A · The Agent Harness |
| **IV — Capstone** | Putting it together |
| **Appendices** | Packages and versions · Provider matrix · Troubleshooting · Screenshot manifest |

Every sample in Parts I and II runs against a locally served model with **no
cloud subscription required** — a constraint the official samples do not meet,
and the reason the experiments in the book are cheap enough to actually run.

---

## Building it

```bash
git clone https://github.com/konradcinkusz/maf-book.git
cd maf-book
latexmk -pdf main.tex
```

Requires a TeX distribution with `listings`, `tcolorbox`, `titlesec`, `microtype`
and `imakeidx`. TeX Live and MiKTeX both have them. Optional font packages
(`newtx`, `inconsolata`) are used when present and skipped when not, so a minimal
installation still builds.

| Command | Does |
|---|---|
| `make` | Full build |
| `make watch` | Rebuild on save |
| `make shots` | List screenshots still outstanding |
| `make clean` | Remove build artefacts |

---

## Repository structure

```
main.tex                  chapter wiring and part structure
preamble.tex              styling, macros, environments, pinned version macros
frontmatter/              title page, introduction
chapters/                 ch01 – ch12
appendices/               appA – appD
figures/screenshots/      drop captures here, named by key
code/                     compiling sample projects, pulled in via \csfile
docs/                     GitHub Pages site
.github/workflows/        build (every PR) · release (every tag) · pages
```

---

## Releasing

```bash
git tag -a v0.3.0 -m "Chapters 1-3 and appendices"
git push origin v0.3.0
```

The release workflow compiles the book, refuses to publish if any
cross-reference is unresolved, and attaches the PDF to a GitHub Release.

---

## Contributing

Errata are the most valuable contribution here — see
[CONTRIBUTING.md](CONTRIBUTING.md). Include the package versions you are running;
most reports are version drift rather than mistakes.

Bugs in Agent Framework itself belong
[upstream](https://github.com/microsoft/agent-framework/issues), not here.

---

## Licence

The **prose** is [CC BY-NC-SA 4.0](LICENSE-CONTENT). The **code samples, LaTeX
macros and build tooling** are [MIT](LICENSE), so you can paste them into
commercial work without thinking about it.

Not affiliated with or endorsed by Microsoft.
