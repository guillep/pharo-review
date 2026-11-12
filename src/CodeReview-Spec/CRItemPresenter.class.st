"
I show one item of a review (a part or a change): what it is and why, the change itself, its Reviewed mark, its note, and a button to browse its code when the image has it as the change leaves it. CRReviewPresenter shows me in its Item tab.
"
Class {
	#name : 'CRItemPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'review',
		'current',
		'summary',
		'changeView',
		'reviewedCheckBox',
		'note',
		'browseButton',
		'reviewedAction'
	],
	#category : 'CodeReview-Spec',
	#package : 'CodeReview-Spec'
}

{ #category : 'accessing' }
CRItemPresenter >> browseButton [
	^ browseButton
]

{ #category : 'actions' }
CRItemPresenter >> browseCurrent [
	"Browse the changed method, or the changed class when the method is gone"

	| class |
	class := current imageClass.
	class ifNil: [ ^ self inform: current name , ' is not in the image' ].
	(current isMethod and: [ class includesSelector: current selector asSymbol ])
		ifTrue: [ (class >> current selector asSymbol) browse ]
		ifFalse: [ class browse ]
]

{ #category : 'accessing' }
CRItemPresenter >> changeView [
	^ changeView
]

{ #category : 'layout' }
CRItemPresenter >> defaultLayout [
	^ SpPanedLayout newTopToBottom
		  positionOfSlider: 0.75;
		  add: (SpPanedLayout newTopToBottom
				   positionOfSlider: 0.3;
				   add: summary;
				   add: changeView;
				   yourself);
		  add: (SpBoxLayout newTopToBottom
				   add: (SpBoxLayout newLeftToRight
						    add: reviewedCheckBox;
						    addLast: browseButton expand: false;
						    yourself)
				   expand: false;
				   add: note;
				   yourself);
		  yourself
]

{ #category : 'initialization' }
CRItemPresenter >> initializePresenters [
	summary := self newText
		           beNotEditable;
		           yourself.
	changeView := self instantiate: CRChangePresenter.
	reviewedCheckBox := self newCheckBox
		                    label: 'Reviewed';
		                    whenChangedDo: [ :value | self markReviewed: value ];
		                    yourself.
	note := self newText
		        placeholder: 'Note';
		        whenTextChangedDo: [ :text | current ifNotNil: [ current note: text asString ] ];
		        yourself.
	browseButton := self newButton
		                label: 'Browse';
		                action: [ self browseCurrent ];
		                yourself
]

{ #category : 'actions' }
CRItemPresenter >> markReviewed: aBoolean [
	current ifNil: [ ^ self ].
	current reviewed: aBoolean.
	reviewedAction ifNotNil: [ reviewedAction value ]
]

{ #category : 'accessing' }
CRItemPresenter >> note [
	^ note
]

{ #category : 'accessing' }
CRItemPresenter >> reviewedCheckBox [
	^ reviewedCheckBox
]

{ #category : 'initialization' }
CRItemPresenter >> setModelBeforeInitialization: aReview [
	review := aReview
]

{ #category : 'showing' }
CRItemPresenter >> show: anItemOrNil [
	"Show anItemOrNil: what it is and why, and the change itself; with none, the title of the review"

	current := nil.
	summary text: (anItemOrNil ifNil: [ review title ] ifNotNil: [ :item | item description ]).
	changeView change: anItemOrNil.
	reviewedCheckBox
		state: (anItemOrNil isNotNil and: [ anItemOrNil isReviewed ]);
		enabled: anItemOrNil isNotNil.
	note
		text: (anItemOrNil ifNil: [ '' ] ifNotNil: [ :item | item note ]);
		enabled: (anItemOrNil isNotNil and: [ anItemOrNil acceptsNote ]).
	browseButton enabled: (anItemOrNil isNotNil and: [ anItemOrNil isBrowsable ]).
	current := anItemOrNil
]

{ #category : 'accessing' }
CRItemPresenter >> summary [
	^ summary
]

{ #category : 'events' }
CRItemPresenter >> whenReviewedDo: aBlock [
	"Run aBlock when the reviewer marks the item reviewed or not"

	reviewedAction := aBlock
]
