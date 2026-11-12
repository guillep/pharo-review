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
		'reviewedCheckBox',
		'note',
		'browseButton',
		'exportButton',
		'changeView',
		'hideAccessorsCheckBox',
		'groupByList',
		'sortList',
		'description',
		'tabs'
	],
	#category : 'CodeReview-Spec',
	#package : 'CodeReview-Spec'
}

{ #category : 'actions' }
CRReviewPresenter >> browseCurrent [
	"Browse the changed method, or the changed class when the method is gone"

	| class |
	class := current imageClass.
	class ifNil: [ ^ self inform: current name , ' is not in the image' ].
	(current isMethod and: [ class includesSelector: current selector asSymbol ])
		ifTrue: [ (class >> current selector asSymbol) browse ]
		ifFalse: [ class browse ]
]

{ #category : 'accessing - tests' }
CRReviewPresenter >> changeView [

^ changeView
]

{ #category : 'tree' }
CRReviewPresenter >> childrenOf: anItem [
	"What the tree shows under anItem: the words of a list in the chosen order"

	| children |
	children := anItem childrenShowing: self filter.
	^ anItem isWordList
		  ifTrue: [ self sortWords: children ]
		  ifFalse: [ children ]
]

{ #category : 'tree' }
CRReviewPresenter >> defaultLayout [

	^ SpPanedLayout newLeftToRight
		  positionOfSlider: 0.35;
		  add: (SpBoxLayout newTopToBottom
				   add: (SpBoxLayout newLeftToRight
						    add: groupByList;
						    add: sortList;
						    addLast: hideAccessorsCheckBox expand: false;
						    yourself)
				   expand: false;
				   add: tree;
				   yourself);
		  add: (SpPanedLayout newTopToBottom
				   positionOfSlider: 0.75;
				   add: (SpPanedLayout newTopToBottom
						    positionOfSlider: 0.3;
						    add: tabs;
						    add: changeView;
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

{ #category : 'accessing' }
CRReviewPresenter >> description [
	"The text of the pull request description, in its own tab: the reviewer edits it there"

	^ description
]

{ #category : 'actions' }
CRReviewPresenter >> export [

	Clipboard clipboardText: review markdown.
	self inform: 'The review notes are in the clipboard'
]

{ #category : 'tree' }
CRReviewPresenter >> filter [
	"Which changes the tree shows"

	^ hideAccessorsCheckBox state
		  ifTrue: [ [ :change | change isAccessor not ] ]
		  ifFalse: [ [ :change | true ] ]
]

{ #category : 'tree' }
CRReviewPresenter >> groupByList [

	^ groupByList
]

{ #category : 'tree' }
CRReviewPresenter >> hideAccessorsCheckBox [

	^ hideAccessorsCheckBox
]

{ #category : 'actions' }
CRReviewPresenter >> iconFor: anItem [
	"Moved, added, removed or changed, for a change; none for a part"

	anItem isChange ifFalse: [ ^ nil ].
	^ self iconNamed: (CRChangePresenter iconNameFor: anItem)
]

{ #category : 'initialization' }
CRReviewPresenter >> initializePresenters [

	tree := self newTree
		        children: [ :each | self childrenOf: each ];
		        display: [ :each | self labelFor: each ];
		        displayIcon: [ :each | self iconFor: each ];
		        contextMenu: [ self reviewMenu ];
		        whenSelectionChangedDo: [ :selection | self show: selection selectedItem ];
		        yourself.
	hideAccessorsCheckBox := self newCheckBox
		                         label: 'Hide accessors';
		                         whenChangedDo: [ self updateTree ];
		                         yourself.
	groupByList := self newDropList
		               items: #( 'Parts' 'Vocabulary' );
		               display: [ :each | 'Group by: ' , each ];
		               whenSelectedItemChangedDo: [ self updateTree ];
		               yourself.
	sortList := self newDropList
		            items: #( 'Alphabetical' 'Occurrences' );
		            display: [ :each | 'Sort: ' , each ];
		            whenSelectedItemChangedDo: [ self updateTree ];
		            yourself.
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
		                yourself.
	description := self newText
		               text: review description;
		               whenTextChangedDo: [ :text | review description: text asString ];
		               yourself.
	tabs := self newNotebook
		        addPageTitle: 'Item' provider: [ summary ];
		        addPageTitle: 'Pull request' provider: [ description ];
		        yourself.
	exportButton := self newButton
		                label: 'Export';
		                action: [ self export ];
		                yourself.
	self updateTree
]

{ #category : 'initialization' }
CRReviewPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Review: ' , review title;
		initialExtent: 1300 @ 850
]

{ #category : 'tree' }
CRReviewPresenter >> labelFor: anItem [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (anItem isReviewed
						   ifTrue: [ '✓ ' ]
						   ifFalse: [ '   ' ]);
				  nextPutAll: anItem title;
				  nextPutAll: '  (';
				  nextPutAll: (anItem sizeLabelShowing: self filter);
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

{ #category : 'tree' }
CRReviewPresenter >> roots [
	"The parts of the review, or the words of its code and of its tests"

	| byVocabulary |
	byVocabulary := groupByList selectedItem = 'Vocabulary'.
	sortList enabled: byVocabulary.
	^ (byVocabulary
		   ifTrue: [ review vocabulary ]
		   ifFalse: [ review root children ]) select: [ :each | each shows: self filter ]
]

{ #category : 'initialization' }
CRReviewPresenter >> setModelBeforeInitialization: aReview [

	review := aReview
]

{ #category : 'tree' }
CRReviewPresenter >> show: anItemOrNil [
	"Show anItemOrNil on the right: what it is and why, and the change itself (the description of the pull request has its own tab)"

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

{ #category : 'tree' }
CRReviewPresenter >> sortList [

	^ sortList
]

{ #category : 'tree' }
CRReviewPresenter >> sortWords: aCollectionOfWords [
	"New words first, as the review gives them; then alphabetically or by the changes adding them, most first"

	sortList selectedItem = 'Occurrences' ifFalse: [ ^ aCollectionOfWords ].
	^ aCollectionOfWords asSortedCollection: [ :a :b |
			  a isNew = b isNew
				  ifTrue: [ a occurrences > b occurrences or: [ a occurrences = b occurrences and: [ a word <= b word ] ] ]
				  ifFalse: [ a isNew ] ]
]

{ #category : 'accessing - tests' }
CRReviewPresenter >> summary [

	^ summary
]

{ #category : 'accessing' }
CRReviewPresenter >> tabs [
	^ tabs
]

{ #category : 'accessing - tests' }
CRReviewPresenter >> tree [

	^ tree
]

{ #category : 'tree' }
CRReviewPresenter >> updateTree [
	"Show the tree again after the filter or the grouping changed"

	tree roots: self roots.
	self show: nil
]
