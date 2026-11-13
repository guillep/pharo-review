---
name: pharo-review
description: Use when the user wants to review a pull request or a branch of a Pharo project in a running image. Small pull requests are only reported; big ones are grouped into a tree of what they do and opened in the CodeReview tool, where the user reviews on their own and exports notes as Markdown that the agent then works through one at a time.
---

# Reviewing a Pharo pull request

The user reviews; the agent prepares the review. Work in the running image through the tools it offers (for example a Pharo MCP server). If the image has no `CRReview` class, load the tool first:

```smalltalk
Metacello new
	baseline: 'CodeReview';
	repository: 'github://guillep/pharo-review:main/src';
	load.
```
 The full API is in README.md.

Give the review the pull request title (`review pullRequestTitle: '...'`, which names the window and the export) and its description, drafted or taken from GitHub (`review description: '...'`). The tool shows the description, editable, in its Pull request tab, and the Markdown export carries it under "Pull request description". Use the exported text as the pull request body, or to update an open one (`gh pr edit --body-file`).

## 1. Size it

Count the lines added and removed between the base commit and the branch:
`(CRReview repository: '<name>' from: '<base>' to: 'HEAD') lineCount`.

- **Under 300 lines: small.** Say it is small, with the count, and wait for instructions. Do nothing else.
- **300 or more: big.** Go on.

The threshold is a starting point; the user refines it.

## 2. Group the changes into a tree

A big pull request usually does several things. Build a tree of them, top-down:

- **Parts:** each thing the pull request does, with a one-line summary of its purpose, in plain words. Split a part into sub-parts while it still does more than one thing.
- **Changes** are the leaves: methods, class definitions and files, added, removed or changed, of any kind (code, tests, removals).
- **Name every part as a task, with a verb, saying what was done:** "Add the resolution model", not "Resolution objects"; "Change MetacelloScriptEngine", not "MetacelloScriptEngine". Groups by protocol too: "Walk and select versions (resolving)", not "resolving".
- **Say why** in each part's summary, from the commits and from what you know beyond them: the conversation, your memory of the project, earlier decisions and review notes. Changes show the messages of the commits that touched them on their own; when you know more about why a change was made than its commits say, add it: `(review changeNamed: 'Foo>>bar') why: '...'`. Write only what you know, never a guess.
- **Keep splitting until each part is manageable: no more than about 30 items** (sub-parts and changes). Split by class, by method protocol, or by meaning when a theme cuts across classes (for example "printing fixes" for many `printOn:` changes). `part groupBy: [ :change | key ]` does the mechanical splits.
- **Keep a class's methods together** unless they really belong to different things the pull request does; a reviewer reading one class in two places thinks they see duplicates.
- Every change goes in **exactly one** part. What belongs nowhere goes into a part named "Unrelated".
- **Order:**
  - Parts are in reading order, as you add them: what the pull request is for first, then what it builds on, then tests, then "Unrelated". Inside a part, sub-parts come before changes.
  - Changes are always in the tool's order. Do not reorder them by hand.
- Everything needs review: never mark a change as less important.

Build it with the API, in a script run in the image (not committed):

```smalltalk
review := CRReview repository: 'pharo' from: '<base>' to: 'HEAD'.
part := review part: 'Resolution' summary: 'Choose the versions before loading'.
(part part: 'Objects' summary: 'What a resolution holds')
	addAll: (review changesSuchThat: [ :each | each className = 'MetacelloResolution' ]).
review unfiled.        "must end empty"
review checkComplete.  "no change outside the tree, no empty part"
```

- `review changes` is the review's own collection: copy it before removing from it (`OrderedCollection withAll: review changes`).
- Rename a part with `part name: '...'`; never call `setName:summary:` (it is the initializer and empties the part).
- **Link moved code.** When code was moved or extracted (a removed method whose code reappears in an added one, a method split into several), link them: `(review changeNamed: 'New>>sel') movedFrom: (review changeNamed: 'Old>>sel')`. The tool then compares the new code with where it came from. Look for moves by comparing removed and changed methods with added ones; the reviewer should never have to ask "was this moved somewhere?".

## 3. Open the tool

`review open` (refused while a change is unfiled or a part is empty). Tell the user it is open, in one line. Don't describe how the tree is split: they see it in the tool. Keep the review in a global (`Smalltalk at: #MyReview put: review`) so later scripts can change and reopen it.

The user goes through the tree on their own: a Reviewed mark and a note on any item, parts and changes alike. If they ask to reshape the tree (merge, split, rename, move changes), change it with the API and reopen it.

## 4. Act on the notes

The user pastes the Markdown export (Export button).

- **Go through the notes one at a time:** take the first note, answer it or propose what to do, and wait for the user before the next one. Never answer the whole list in one message.
- **Give options:** when a note asks for a decision, show two or three short options, with what each changes and your recommendation first. Make sure the user can see them in your reply.
- Change code only when the user says so. Commit each note's change on its own, with a message naming what changed.

## Next iterations

After acting on the notes, the next review covers only the new commits:

1. List the commits added since the commit the last review ended at (its title names it), with their messages.
2. **Agree the list with the user explicitly** before building anything: they may add, drop or regroup commits.
3. Build a review of that range only (`CRReview repository: … from: <last reviewed commit> to: <last agreed commit>`), grouped as usual (small ones are still just reported), and open it.

If the history before that commit was rewritten (rebase, fixup), say so and agree with the user on the commit to start from.
