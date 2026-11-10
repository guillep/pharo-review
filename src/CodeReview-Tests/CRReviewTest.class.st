"
I test CRReview, CRPart and CRChange on changes given by hand: no repository is read.
"
Class {
	#name : 'CRReviewTest',
	#superclass : 'TestCase',
	#instVars : [
		'review',
		'added',
		'changed',
		'file'
	],
	#category : 'CodeReview-Tests',
	#package : 'CodeReview-Tests'
}

{ #category : 'running' }
CRReviewTest >> setUp [

	super setUp.
	added := (CRChange kind: #added from: nil to: 'foo
	^ 1')
		         packageName: 'P' className: 'A' selector: #foo;
		         yourself.
	changed := (CRChange
		            kind: #changed
		            from: 'bar
	^ 1'
		            to: 'bar
	^ 2')
		           packageName: 'P' className: 'A' selector: #bar;
		           yourself.
	file := (CRChange kind: #changed from: 'a' to: 'b')
		        path: '.project';
		        yourself.
	review := CRReview title: 'pr' changes: {
			          added.
			          changed.
			          file }
]

{ #category : 'tests' }
CRReviewTest >> testAChangeCountsTheLinesAddedAndRemoved [

	self
		assert: added lineCount equals: 2;
		assert: changed lineCount equals: 2;
		assert: review lineCount equals: 6
]

{ #category : 'tests' }
CRReviewTest >> testAChangeIsInOnePartOnly [

	| first second |
	first := review part: 'First' summary: ''.
	second := review part: 'Second' summary: ''.
	first add: added.
	second add: added.

	self
		assert: first children isEmpty;
		assert: second children asArray equals: { added };
		assert: added parent equals: second
]

{ #category : 'tests' }
CRReviewTest >> testAPartMarkedReviewedLeavesItsChildren [

	| part |
	part := review part: 'Code' summary: ''.
	part add: added.
	part reviewed: true.

	self deny: added isReviewed
]

{ #category : 'tests' }
CRReviewTest >> testChangesNameWhatTheyChange [

	self
		assert: added title equals: 'A>>foo added';
		assert: file title equals: '.project changed';
		assert: file isFile;
		deny: added isFile
]

{ #category : 'tests' }
CRReviewTest >> testMarkdownHasTheNotesThenWhatIsNotReviewed [

	| part markdown |
	part := review part: 'Code' summary: ''.
	part addAll: {
			added.
			changed }.
	(review part: 'Unrelated' summary: '') add: file.
	changed
		reviewed: true;
		note: 'Why 2?'.
	part note: 'Split this'.
	added reviewed: true.

	markdown := review markdown.

	self
		assert: (markdown includesSubstring: '2 of 5 items reviewed.');
		assert: (markdown includesSubstring: '### Code (not reviewed)

Split this' withUnixLineEndings);
		assert: (markdown includesSubstring: '### Code › A>>bar changed (reviewed)

Why 2?' withUnixLineEndings);
		assert: (markdown includesSubstring: '- Unrelated › .project changed');
		deny: (markdown includesSubstring: 'A>>foo')
]

{ #category : 'tests' }
CRReviewTest >> testPartsNest [

	| part sub |
	part := review part: 'Resolution' summary: 'Choose versions'.
	sub := part part: 'Objects' summary: 'What a resolution holds'.
	sub add: changed.

	self
		assert: changed place equals: 'Resolution › Objects › A>>bar changed';
		assert: part lineCount equals: 2
]

{ #category : 'tests' }
CRReviewTest >> testUnfiledAreTheChangesInNoPart [

	(review part: 'Code' summary: '') addAll: (review changesSuchThat: [ :each | each isMethod ]).

	self assert: review unfiled asArray equals: { file }
]
