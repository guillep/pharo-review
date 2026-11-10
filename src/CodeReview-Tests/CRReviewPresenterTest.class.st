"
I test the review tool without opening it, on a review given by hand.
"
Class {
	#name : 'CRReviewPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'review',
		'change',
		'part',
		'presenter'
	],
	#category : 'CodeReview-Tests',
	#package : 'CodeReview-Tests'
}

{ #category : 'running' }
CRReviewPresenterTest >> select: anItem [

	presenter tree selectPath: (anItem == part
			 ifTrue: [ #( 1 ) ]
			 ifFalse: [ #( 1 1 ) ])
]

{ #category : 'running' }
CRReviewPresenterTest >> setUp [

	super setUp.
	change := (CRChange kind: #changed from: 'old' to: 'new')
		          packageName: 'P' className: 'A' selector: #foo;
		          yourself.
	review := CRReview title: 'pr' changes: { change }.
	part := review part: 'Code' summary: 'The code'.
	part add: change.
	presenter := CRReviewPresenter on: review
]

{ #category : 'tests' }
CRReviewPresenterTest >> testAChangeShowsItsDiff [

	self select: change.

	self
		assert: presenter changeView isShowingDiff;
		assert: presenter changeView diff leftText equals: 'old';
		assert: presenter changeView diff rightText equals: 'new';
		assert: (presenter changeView label label includesSubstring: 'Changed');
		assert: (presenter summary text asString includesSubstring: 'A>>foo changed')
]

{ #category : 'tests' }
CRReviewPresenterTest >> testAChangeShowsWhyFromItsCommits [

	change commitMessages: #( 'Add foo

Because bar needs it' ).
	self select: change.

	self assert: (presenter summary text asString includesSubstring: 'Because bar needs it')
]

{ #category : 'tests' }
CRReviewPresenterTest >> testAPartShowsItsPurpose [

	self select: part.

	self assert: (presenter summary text asString includesSubstring: 'Code: The code')
]

{ #category : 'tests' }
CRReviewPresenterTest >> testAPartShowsNoChange [

	self select: part.

	self
		deny: presenter changeView isShowingCode;
		deny: presenter changeView isShowingDiff
]

{ #category : 'tests' }
CRReviewPresenterTest >> testARemovalShowsTheOldCode [

	| removal |
	removal := (CRChange
		            kind: #removed
		            from: 'bar
	^ 2'
		            to: nil)
		           packageName: 'P' className: 'A' selector: #bar;
		           yourself.
	presenter changeView change: removal.

	self
		assert: presenter changeView isShowingCode;
		assert: presenter changeView code text asString equals: 'bar
	^ 2'
]

{ #category : 'tests' }
CRReviewPresenterTest >> testAWordTakesNoNote [

	presenter groupByList selectItem: 'Vocabulary'.
	presenter tree selectPath: #( 1 ).
	self deny: presenter note isEnabled
]

{ #category : 'tests' }
CRReviewPresenterTest >> testAnAdditionShowsItsCodeAlone [

	| addition |
	addition := (CRChange kind: #added from: nil to: 'bar
	^ 2')
		            packageName: 'P' className: 'A' selector: #bar;
		            yourself.
	presenter changeView change: addition.

	self
		assert: presenter changeView isShowingCode;
		deny: presenter changeView isShowingDiff;
		assert: presenter changeView code text asString equals: 'bar
	^ 2';
		assert: (presenter changeView label label includesSubstring: 'Added')
]

{ #category : 'tests' }
CRReviewPresenterTest >> testChangesHaveAnIconForTheirKind [

	self
		assert: (presenter iconFor: change) equals: (presenter iconNamed: #changeUpdate);
		assert: (presenter iconFor: part) isNil
]

{ #category : 'tests' }
CRReviewPresenterTest >> testGroupingByVocabularyShowsTheWords [

	presenter groupByList selectItem: 'Vocabulary'.
	self assert: (presenter tree roots collect: [ :each | each title ]) asArray equals: #( 'new (new)' ).
	presenter groupByList selectItem: 'Parts'.
	self assert: presenter tree roots asArray equals: { part }
]

{ #category : 'tests' }
CRReviewPresenterTest >> testHidingAccessorsHidesThePartsLeftEmpty [

	| getter accessors |
	getter := (CRChange kind: #added from: nil to: 'name
	^ name')
		          packageName: 'P' className: 'A' selector: #name;
		          yourself.
	review := CRReview title: 'pr' changes: {
			          change.
			          getter }.
	part := review part: 'Code' summary: 'The code'.
	part add: change.
	accessors := review part: 'Accessors' summary: 'Getters'.
	accessors add: getter.
	presenter := CRReviewPresenter on: review.
	presenter hideAccessorsCheckBox state: true.
	self assert: presenter tree roots asArray equals: { part }.
	presenter hideAccessorsCheckBox state: false.
	self assert: presenter tree roots asArray equals: {
			part.
			accessors }
]

{ #category : 'tests' }
CRReviewPresenterTest >> testMovedCodeIsComparedWithWhereItCameFrom [

	| removal addition |
	removal := (CRChange
		            kind: #removed
		            from: 'old
	^ 1'
		            to: nil)
		           packageName: 'P' className: 'B' selector: #old;
		           yourself.
	addition := (CRChange kind: #added from: nil to: 'new
	^ 1')
		            packageName: 'P' className: 'A' selector: #new;
		            yourself.
	addition movedFrom: removal.
	presenter changeView change: addition.

	self
		assert: presenter changeView isShowingDiff;
		assert: presenter changeView diff leftText equals: 'old
	^ 1';
		assert: (presenter changeView label label includesSubstring: 'Moved   A>>new   from   B>>old');
		assert: (removal description includesSubstring: 'Moved to: A>>new')
]

{ #category : 'tests' }
CRReviewPresenterTest >> testSelectingAnotherItemKeepsTheFirstOnesNote [

	self select: change.
	presenter note text: 'Why?'.
	self select: part.

	self
		assert: change note equals: 'Why?';
		assert: part note equals: ''
]

{ #category : 'tests' }
CRReviewPresenterTest >> testTheMenuMarksTheSelectedItem [

	self select: change.
	presenter markSelected: true.

	self
		assert: change isReviewed;
		assert: presenter reviewedCheckBox state.
	presenter markSelected: false.
	self deny: change isReviewed
]

{ #category : 'tests' }
CRReviewPresenterTest >> testTheReviewedMarkAndTheNoteGoToTheItem [

	self select: change.
	presenter reviewedCheckBox state: true.
	presenter note text: 'Why?'.

	self
		assert: change isReviewed;
		assert: change note equals: 'Why?';
		assert: part isReviewed;
		assert: part note equals: ''
]
