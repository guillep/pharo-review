"
I am the review tool. Left: the tree of the review (parts, then changes), each item with its size in lines, a check when reviewed and a pencil when it has a note. Right: the selected item, its purpose or its diff, its Reviewed mark and its note. Browse opens the changed class or method; Export copies the notes as Markdown, for the chat.

	(CRReviewPresenter on: aReview) open
"
Class {
	#name : 'CRReviewPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'review',
		'current',
		'tree',
		'summary',
		'diff',
		'reviewedCheckBox',
		'note',
		'browseButton',
		'exportButton'
	],
	#category : 'CodeReview-Spec',
	#package : 'CodeReview-Spec'
}

{ #category : 'actions' }
CRReviewPresenter >> browseCurrent [
	"Browse the changed method, or the changed class when the method is gone"

	| class |
	class := self classOf: current.
	class ifNil: [ ^ self inform: current name , ' is not in the image' ].
	(current isMethod and: [ class includesSelector: current selector asSymbol ])
		ifTrue: [ (class >> current selector asSymbol) browse ]
		ifFalse: [ class browse ]
]

{ #category : 'actions' }
CRReviewPresenter >> classOf: aChange [

	| class |
	class := Smalltalk globals classNamed: (aChange className copyReplaceAll: ' class' with: '').
	class ifNil: [ ^ nil ].
	^ (aChange className endsWith: ' class')
		  ifTrue: [ class class ]
		  ifFalse: [ class ]
]

{ #category : 'initialization' }
CRReviewPresenter >> defaultLayout [

	^ SpPanedLayout newLeftToRight
		  positionOfSlider: 0.35;
		  add: tree;
		  add: (SpPanedLayout newTopToBottom
				   positionOfSlider: 0.75;
				   add: (SpPanedLayout newTopToBottom
						    positionOfSlider: 0.3;
						    add: summary;
						    add: diff;
						    yourself);
				   add: (SpBoxLayout newTopToBottom
						    add: (SpBoxLayout newLeftToRight
								     add: reviewedCheckBox;
								     addLast: browseButton expand: false;
								     addLast: exportButton expand: false;
								     yourself)
						    expand: false;
						    add: note;
						    yourself);
				   yourself);
		  yourself
]

{ #category : 'accessing - tests' }
CRReviewPresenter >> diff [

	^ diff
]

{ #category : 'actions' }
CRReviewPresenter >> export [

	Clipboard clipboardText: review markdown.
	self inform: 'The review notes are in the clipboard'
]

{ #category : 'actions' }
CRReviewPresenter >> iconFor: anItem [
	"Added, removed or changed, for a change; none for a part"

	anItem isChange ifFalse: [ ^ nil ].
	^ self iconNamed:
		  ((Dictionary newFromPairs: #( #added #changeAdd #removed #changeRemove #changed #changeUpdate )) at: anItem kind)
]

{ #category : 'initialization' }
CRReviewPresenter >> initializePresenters [

	tree := self newTree
		        roots: review root children;
		        children: [ :each | each children ];
		        display: [ :each | self labelFor: each ];
		        displayIcon: [ :each | self iconFor: each ];
		        contextMenu: [ self reviewMenu ];
		        whenSelectionChangedDo: [ :selection | self show: selection selectedItem ];
		        yourself.
	summary := self newText
		           beNotEditable;
		           yourself.
	diff := self newDiff.
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
		                yourself.
	exportButton := self newButton
		                label: 'Export';
		                action: [ self export ];
		                yourself.
	self show: nil
]

{ #category : 'initialization' }
CRReviewPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Review: ' , review title;
		initialExtent: 1300 @ 850
]

{ #category : 'actions' }
CRReviewPresenter >> labelFor: anItem [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (anItem isReviewed
						   ifTrue: [ '✓ ' ]
						   ifFalse: [ '   ' ]);
				  nextPutAll: anItem title;
				  nextPutAll: '  (';
				  nextPutAll: anItem sizeLabel;
				  nextPutAll: ')'.
			  anItem hasNote ifTrue: [ stream nextPutAll: '  ✎' ] ]
]

{ #category : 'actions' }
CRReviewPresenter >> markReviewed: aBoolean [

	current ifNil: [ ^ self ].
	current reviewed: aBoolean.
	tree refresh
]

{ #category : 'actions' }
CRReviewPresenter >> markSelected: aBoolean [
	"Mark the selected item from the menu, and show the new mark"

	tree selectedItem ifNil: [ ^ self ].
	tree selectedItem reviewed: aBoolean.
	tree refresh.
	self show: tree selectedItem
]

{ #category : 'accessing - tests' }
CRReviewPresenter >> note [

	^ note
]

{ #category : 'actions' }
CRReviewPresenter >> reviewMenu [

	^ self newMenu
		  addGroup: [ :group |
				  group
					  addItem: [ :item |
							  item
								  name: 'Mark reviewed';
								  action: [ self markSelected: true ] ];
					  addItem: [ :item |
							  item
								  name: 'Mark not reviewed';
								  action: [ self markSelected: false ] ] ];
		  yourself
]

{ #category : 'accessing - tests' }
CRReviewPresenter >> reviewedCheckBox [

	^ reviewedCheckBox
]

{ #category : 'initialization' }
CRReviewPresenter >> setModelBeforeInitialization: aReview [

	review := aReview
]

{ #category : 'actions' }
CRReviewPresenter >> show: anItemOrNil [
	"Show anItemOrNil on the right: what it is, and its diff when it is a change"

	current := nil.
	summary text: (anItemOrNil ifNil: [ review title ] ifNotNil: [ :item | item description ]).
	diff
		leftText: (anItemOrNil ifNil: [ '' ] ifNotNil: [ :item | item oldSource ]);
		rightText: (anItemOrNil ifNil: [ '' ] ifNotNil: [ :item | item newSource ]).
	reviewedCheckBox
		state: (anItemOrNil isNotNil and: [ anItemOrNil isReviewed ]);
		enabled: anItemOrNil isNotNil.
	note
		text: (anItemOrNil ifNil: [ '' ] ifNotNil: [ :item | item note ]);
		enabled: anItemOrNil isNotNil.
	browseButton enabled: (anItemOrNil isNotNil and: [ anItemOrNil isBrowsable ]).
	current := anItemOrNil
]

{ #category : 'accessing - tests' }
CRReviewPresenter >> summary [

	^ summary
]

{ #category : 'accessing - tests' }
CRReviewPresenter >> tree [

	^ tree
]
