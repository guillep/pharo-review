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

"Split a part's changes into sub-parts by any key: class, protocol, or a theme"
resolution groupBy: [ :each | each className ].
resolution groupBy: [ :each | each protocol ifNil: [ 'definitions' ] ].

"A change is in one part only: adding it to another part moves it"
review unfiled.          "the changes the tree does not reach yet"
review emptyParts.       "the parts holding nothing"

"Rename a part, keeping what it holds"
objects name: 'Add the resolution objects'.

"Moved or extracted code: the tool compares the new code with where it came from"
(review changeNamed: 'MetacelloVersionSpec>>loadableSpecsFor:')
	movedFrom: (review changeNamed: 'MetacelloRecordTarget>>listLoadableSpecsFrom:').

"After the branch changed: keep the tree, notes, moves, and the marks of unchanged code"
newReview := CRReview repository: 'pharo' from: '6e5455cd' to: 'HEAD'.
newReview reuse: review.   "answers what it could not place"

"Open the tool: refused while a change is unfiled or a part is empty, so nothing is left out (checkComplete)"
review open.

"The words the pull request adds, each with the changes that add them; words new to the code first"
review vocabulary.
change isAccessor.       "a plain getter or setter"

"The reviewer's notes, as the tool's Export button copies them"
review markdown.
```

A `CRChange` answers `kind` (`#added`, `#removed`, `#changed`), `packageName`, `className` (`'Foo class'` for the class side), `selector` (nil for a class definition), `protocol` (nil unless a method), `path` (for a file), `oldSource`, `newSource`, `lineCount`, and `isMethod` / `isFile`.

Iceberg details methods and class definitions only for the packages loaded in the image; any other changed file (a package not loaded, or a file that is not code) is one file change.

For tests, give the changes by hand: `CRReview title: 'pr' changes: { ... }`.

## The tool

- **Left:** the tree. **Group by** shows it by parts or by vocabulary: each word the pull request adds (split at camel case, lowercased, plurals dropped; no numbers, nothing from class comments), sorted alphabetically or by how many changes add it, marked "(new)" when the code before did not use it. **Hide accessors** hides plain getters and setters, and the parts left empty; sizes count what is shown. Each change has an icon for added, removed or changed. Each item shows a check when reviewed, its size (lines changed, and items for a part), and a pencil when it has a note. Right-click marks an item reviewed or not.
- **Right:** a part's summary, or a change's old/new diff with why it was made (the messages of the commits that touched it); the Reviewed mark and the note of the selected item.
- **Marks:** marking a part marks everything under it. A part is reviewed when everything under it is: marking the last child marks the part, unmarking a child unmarks its parts (not its siblings).
- **Order:** in a part, sub-parts come first in the order they were added; then changes, always in the same order: code before files, by class, the class definition first, then instance-side methods, then class-side ones, by selector.
- **Why** comes from the history: a commit that renamed a class does not lead back to the commits before the rename.
- **Browse** opens the changed method or class. **Export** copies the notes to the clipboard as Markdown: progress, every item with a note (its place in the tree, reviewed or not), then the items not reviewed yet.

Not yet: reshaping the tree in the tool, saving a review between sessions.
