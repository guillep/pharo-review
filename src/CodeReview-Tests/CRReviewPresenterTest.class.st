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
		assert: presenter diff leftText equals: 'old';
		assert: presenter diff rightText equals: 'new';
		assert: (presenter summary text asString includesSubstring: 'A>>foo changed')
]

{ #category : 'tests' }
CRReviewPresenterTest >> testAPartShowsItsPurpose [

	self select: part.

	self assert: (presenter summary text asString includesSubstring: 'Code: The code')
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
CRReviewPresenterTest >> testTheReviewedMarkAndTheNoteGoToTheItem [

	self select: change.
	presenter reviewedCheckBox state: true.
	presenter note text: 'Why?'.

	self
		assert: change isReviewed;
		assert: change note equals: 'Why?';
		deny: part isReviewed
]
