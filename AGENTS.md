# pharo-review

CodeReview: a Pharo tool to review a big pull request top-down, as a tree of what it does, with marks and notes exported as Markdown.

- Code is in Tonel under `src/`: `BaselineOfCodeReview`, `CodeReview` (the model), `CodeReview-Spec` (the Spec UI), `CodeReview-Tests`.
- Work on the code in a running Pharo image, through the tools it offers (for example a Pharo MCP server); commit the packages from the image (Iceberg). Files outside `src/` are edited and committed with git.
- Run `CodeReview-Tests` after any change; tests build reviews by hand (`CRReview title:changes:`) and never touch the network.
- The API and the tool are described in README.md; keep it up to date when either changes.
- To review a pull request with this tool, follow the skill in `.agents/skills/pharo-review/SKILL.md`.
