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

{ #category : 'tests - accessors' }
CRReviewTest >> method: aString [

	^ (CRChange kind: #added from: nil to: aString)
		  packageName: 'P' className: 'A' selector: #x;
		  yourself
]

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
CRReviewTest >> testAChangeInAPartEmptiedAgainIsUnfiled [
	"The tree decides, not the change's parent"

	| part |
	part := review part: 'Code' summary: ''.
	part addAll: review changes.
	part setName: 'Code' summary: ''.

	self assert: review unfiled size equals: review changes size
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
CRReviewTest >> testACompleteReviewChecks [

	(review part: 'Code' summary: '') addAll: review changes.

	self shouldnt: [ review checkComplete ] raise: Error
]

{ #category : 'tests' }
CRReviewTest >> testAPartKeepsItsSubPartsFirstThenItsChangesInOrder [

	| part sub |
	part := review part: 'All' summary: ''.
	part addAll: {
			file.
			changed.
			added }.
	sub := part part: 'Sub' summary: ''.

	self assert: part children asArray equals: {
			sub.
			changed.
			added.
			file }
]

{ #category : 'tests' }
CRReviewTest >> testAPartMarkedReviewedMarksItsChildren [

	| part sub |
	part := review part: 'Code' summary: ''.
	sub := part part: 'Sub' summary: ''.
	sub add: added.
	part add: changed.
	part reviewed: true.

	self
		assert: sub isReviewed;
		assert: added isReviewed;
		assert: changed isReviewed.
	part reviewed: false.
	self deny: added isReviewed
]

{ #category : 'tests' }
CRReviewTest >> testAnEmptyPartIsReported [

	| empty |
	(review part: 'Code' summary: '') addAll: review changes.
	empty := review part: 'Nothing' summary: ''.

	self assert: review emptyParts asArray equals: { empty }.
	self should: [ review checkComplete ] raise: Error
]

{ #category : 'tests' }
CRReviewTest >> testChangesAreOrderedByClassDefinitionFirstThenSelector [

	| definition meta ordered |
	definition := (CRChange kind: #added from: nil to: 'Object subclass: #A')
		              packageName: 'P' className: 'A' selector: nil;
		              yourself.
	meta := (CRChange kind: #added from: nil to: 'new')
		        packageName: 'P' className: 'A class' selector: #new;
		        yourself.
	ordered := (CRReview title: 'pr' changes: {
			            file.
			            meta.
			            added.
			            definition.
			            changed }) changes.

	self assert: ordered asArray equals: {
			definition.
			changed.
			added.
			meta.
			file }
]

{ #category : 'tests' }
CRReviewTest >> testChangesNameWhatTheyChange [

	self
		assert: added title equals: 'A>>foo added';
		assert: file title equals: '.project changed';
		assert: file isFile;
		deny: added isFile
]

{ #category : 'tests - accessors' }
CRReviewTest >> testGettersAndSettersAreAccessors [

	self
		assert: (self method: 'name
	^ name') isAccessor;
		assert: (self method: 'name: aString
	name := aString') isAccessor;
		assert: (self method: 'name: aString
	"Set it"
	name := aString.
	^ self') isAccessor
]

{ #category : 'tests' }
CRReviewTest >> testGroupByLeavesSubPartsWhereTheyAre [

	| part sub |
	part := review part: 'All' summary: ''.
	sub := part part: 'Sub' summary: ''.
	sub add: file.
	part addAll: {
			added.
			changed }.
	part groupBy: [ :each | 'Code' ].

	self
		assert: (part children collect: [ :each | each name ]) asArray equals: #( 'Sub' 'Code' );
		assert: file parent equals: sub
]

{ #category : 'tests' }
CRReviewTest >> testGroupByMovesTheChangesIntoSubParts [

	| part groups |
	part := review part: 'All' summary: ''.
	part addAll: review changes.
	groups := part groupBy: [ :each |
			          each isFile
				          ifTrue: [ 'Files' ]
				          ifFalse: [ each className ] ].

	self
		assert: (groups collect: [ :each | each name ]) asArray equals: #( 'A' 'Files' );
		assert: groups first children asArray equals: {
				changed.
				added };
		assert: part children asArray equals: groups asArray;
		assert: changed place equals: 'All › A › A>>bar changed'
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

	markdown := review markdown.

	self
		assert: (markdown includesSubstring: '1 of 5 items reviewed.');
		assert: (markdown includesSubstring: '### Code (not reviewed)

Split this' withUnixLineEndings);
		assert: (markdown includesSubstring: '### Code › A>>bar changed (reviewed)

Why 2?' withUnixLineEndings);
		assert: (markdown includesSubstring: '- Unrelated › .project changed');
		assert: (markdown includesSubstring: '- Code › A>>foo added')
]

{ #category : 'tests - vocabulary' }
CRReviewTest >> testMarkingAWordMarksItsChangesInTheirParts [

	| part |
	part := review part: 'Code' summary: ''.
	part addAll: {
			added.
			changed }.
	review vocabulary first reviewed: true.
	self
		assert: added isReviewed;
		deny: changed isReviewed;
		deny: part isReviewed
]

{ #category : 'tests' }
CRReviewTest >> testMarkingTheLastChildMarksTheParents [

	| part sub |
	part := review part: 'All' summary: ''.
	sub := part part: 'Code' summary: ''.
	sub addAll: {
			added.
			changed }.
	added reviewed: true.
	self deny: sub isReviewed.
	changed reviewed: true.

	self
		assert: sub isReviewed;
		assert: part isReviewed
]

{ #category : 'tests - vocabulary' }
CRReviewTest >> testNumbersAreNotWords [

	self assert: (CRVocabulary wordsOf: 'test00Version35') asArray equals: #( 'test' 'version' )
]

{ #category : 'tests - vocabulary' }
CRReviewTest >> testOnlyAddedNamesHaveVocabulary [

	self
		assert: added addedWords asArray equals: #( 'foo' );
		assert: changed addedWords isEmpty;
		assert: changed oldWords asArray equals: #( 'bar' );
		assert: file addedWords isEmpty
]

{ #category : 'tests - accessors' }
CRReviewTest >> testOtherMethodsAreNotAccessors [

	self
		deny: (self method: 'name
	^ name ifNil: [ ''none'' ]') isAccessor;
		deny: (self method: 'name
	^ Name') isAccessor;
		deny: (self method: 'me
	^ self') isAccessor;
		deny: (self method: 'name: aString
	name := aString asUppercase') isAccessor;
		deny: file isAccessor
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
CRReviewTest >> testRenamingAPartKeepsWhatItHolds [

	| part |
	part := review part: 'Code' summary: ''.
	part addAll: review changes.
	part name: 'Change the code'.

	self assert: part name equals: 'Change the code'.
	self assert: review unfiled isEmpty
]

{ #category : 'tests' }
CRReviewTest >> testReuseTakesTheTreeNotesMovesAndMarksOfAnOlderReview [

	| old part newer newChanged newAdded newFile newExtra |
	part := review part: 'Code' summary: 'The code'.
	part addAll: {
			added.
			changed }.
	(review part: 'Unrelated' summary: '') add: file.
	added
		reviewed: true;
		note: 'ok'.
	changed reviewed: true.
	added movedFrom: changed.
	old := review.
	newAdded := (CRChange kind: #added from: nil to: added newSource)
		            packageName: 'P' className: 'A' selector: #foo;
		            yourself.
	newChanged := (CRChange
		               kind: #changed
		               from: 'bar
	^ 1'
		               to: 'bar
	^ 3')
		              packageName: 'P' className: 'A' selector: #bar;
		              yourself.
	newExtra := (CRChange kind: #added from: nil to: 'baz')
		            packageName: 'P' className: 'A' selector: #baz;
		            yourself.
	newFile := (CRChange kind: #changed from: 'a' to: 'b')
		           path: '.project';
		           yourself.
	newer := CRReview title: 'pr' changes: {
			         newAdded.
			         newChanged.
			         newExtra.
			         newFile }.

	self assert: (newer reuse: old) isEmpty.
	self
		assert: newAdded place equals: 'Code › A>>foo added';
		assert: newExtra place equals: 'Code › A>>baz added';
		assert: newAdded note equals: 'ok';
		assert: newAdded isReviewed;
		deny: newChanged isReviewed;
		assert: newAdded origins asArray equals: { newChanged };
		assert: (newer root children collect: [ :each | each summary ]) asArray equals: #( 'The code' '' )
]

{ #category : 'tests - vocabulary' }
CRReviewTest >> testSplitsIdentifiersIntoNormalizedWords [

	self
		assert: (CRVocabulary wordsOf: 'at:resolvedProjects:') asArray equals: #( 'resolved' 'project' );
		assert: (CRVocabulary wordsOf: 'MetacelloMVSGraph') asArray equals: #( 'metacello' 'mvs' 'graph' );
		assert: (CRVocabulary wordsOf: 'dependencies') asArray equals: #( 'dependency' )
]

{ #category : 'tests' }
CRReviewTest >> testTheSizeLabelSaysLinesAndItems [

	| part |
	part := review part: 'All' summary: ''.
	part addAll: {
			added.
			changed }.

	self
		assert: added sizeLabel equals: '2 lines';
		assert: part sizeLabel equals: '2 items, 4 lines'
]

{ #category : 'tests - vocabulary' }
CRReviewTest >> testTheVocabularyGroupsChangesByWordNewOnesFirst [

	| fooBar words |
	fooBar := (CRChange kind: #added from: nil to: 'fooBar
	^ 1')
		          packageName: 'P' className: 'Graph' selector: #fooBar;
		          yourself.
	words := (CRReview title: 'pr' changes: {
			          added.
			          changed.
			          fooBar }) vocabulary.
	self
		assert: (words collect: [ :each | each title ]) asArray equals: #( 'foo (new)' 'graph (new)' 'bar' );
		assert: words first children asSet equals: {
				added.
				fooBar } asSet;
		assert: words last children asArray equals: { fooBar }
]

{ #category : 'tests' }
CRReviewTest >> testUnfiledAreTheChangesInNoPart [

	(review part: 'Code' summary: '') addAll: (review changesSuchThat: [ :each | each isMethod ]).

	self assert: review unfiled asArray equals: { file }
]

{ #category : 'tests' }
CRReviewTest >> testUnmarkingAChildUnmarksTheParents [

	| part sub |
	part := review part: 'All' summary: ''.
	sub := part part: 'Code' summary: ''.
	sub addAll: {
			added.
			changed }.
	added reviewed: true.
	changed reviewed: true.
	changed reviewed: false.

	self
		deny: sub isReviewed;
		deny: part isReviewed;
		assert: added isReviewed
]
