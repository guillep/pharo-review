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
