# pharo-review

A tool to review a big pull request in a Pharo image, top-down.

The changes of the pull request are grouped into a tree: the things the pull request does (parts), split into smaller parts, down to the changes themselves (a method, a class definition or a file, added, removed or changed). The reviewer goes through the tree, marks items reviewed, writes notes, and exports the notes as Markdown.

## Load

```smalltalk
Metacello new
	baseline: 'CodeReview';
	repository: 'tonel://path/to/pharo-review/src';
	load.
```

## API

```smalltalk
"Every change between two commits of an Iceberg repository (a commit id, or 'HEAD')"
review := CRReview repository: 'pharo' from: '6e5455cd' to: 'HEAD'.
review changes.          "the CRChanges"
review lineCount.        "lines added and removed"

"Build the tree: parts, sub-parts, and the changes in them"
resolution := review part: 'Resolution' summary: 'Choose the versions before loading'.
objects := resolution part: 'Objects' summary: 'What a resolution holds'.
objects addAll: (review changesSuchThat: [ :each | each className = 'MetacelloResolution' ]).

"A change is in one part only: adding it to another part moves it"
review unfiled.          "the changes in no part yet"

"Open the tool: refused while a change is unfiled, so nothing is left out"
review open.

"The reviewer's notes, as the tool's Export button copies them"
review markdown.
```

A `CRChange` answers `kind` (`#added`, `#removed`, `#changed`), `packageName`, `className` (`'Foo class'` for the class side), `selector` (nil for a class definition), `path` (for a file), `oldSource`, `newSource`, `lineCount`, and `isMethod` / `isFile`.

Iceberg details methods and class definitions only for the packages loaded in the image; any other changed file (a package not loaded, or a file that is not code) is one file change.

For tests, give the changes by hand: `CRReview title: 'pr' changes: { ... }`.

## The tool

- **Left:** the tree. Each item shows a check when reviewed, its size in lines, and a pencil when it has a note.
- **Right:** a part's summary, or a change's old/new diff; the Reviewed mark and the note of the selected item. Marking a part reviewed does not mark its children.
- **Browse** opens the changed method or class. **Export** copies the notes to the clipboard as Markdown: progress, every item with a note (its place in the tree, reviewed or not), then the items not reviewed yet.

Not yet: reshaping the tree in the tool, saving a review between sessions.
