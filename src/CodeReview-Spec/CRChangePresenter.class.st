"
I show one change: a header with a large icon and what was done (Added, Removed, Changed), then, for an addition or a removal, its source in one code pane, and for a modification, the old and new side by side. I show nothing for a part.

	presenter change: aChangeOrNil
"
Class {
	#name : 'CRChangePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'change',
		'icon',
		'label',
		'code',
		'diff'
	],
	#category : 'CodeReview-Spec',
	#package : 'CodeReview-Spec'
}

{ #category : 'icons' }
CRChangePresenter class >> iconNameFor: aChange [
	"Moved, added, removed or changed"

	aChange isMoved ifTrue: [ ^ #glamorousRedo ].
	^ (Dictionary newFromPairs: #( #added #changeAdd #removed #changeRemove #changed #changeUpdate )) at: aChange kind
]

{ #category : 'accessing' }
CRChangePresenter >> change: anItemOrNil [
	"Show anItemOrNil when it is a change; nothing otherwise. Moved code is compared with where it came from; a modification with its old version; an addition or a removal is shown alone"

	change := (anItemOrNil isNotNil and: [ anItemOrNil isChange ]) ifTrue: [ anItemOrNil ].
	change ifNil: [ ^ self layout: SpBoxLayout newTopToBottom ].
	icon image: ((self iconNamed: self iconName) scaledToSize: 32 @ 32).
	label label: self headline.
	self showsDiff
		ifTrue: [
				diff
					leftText: (change isMoved
							 ifTrue: [ change originSource ]
							 ifFalse: [ change oldSource ]);
					rightText: change newSource ]
		ifFalse: [ self showCode ].
	self layout: (SpBoxLayout newTopToBottom
			 add: (SpBoxLayout newLeftToRight
					  spacing: 8;
					  add: icon width: 36;
					  add: label;
					  yourself)
			 height: 40;
			 add: (self showsDiff
					  ifTrue: [ diff ]
					  ifFalse: [ code ]);
			 yourself)
]

{ #category : 'accessing' }
CRChangePresenter >> code [

	^ code
]

{ #category : 'initialization' }
CRChangePresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
]

{ #category : 'accessing' }
CRChangePresenter >> diff [

	^ diff
]

{ #category : 'accessing' }
CRChangePresenter >> headline [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: self verb;
				  nextPutAll: '   ';
				  nextPutAll: change name.
			  change isMoved ifTrue: [
					  stream nextPutAll: '   from   '.
					  stream nextPutAll: (', ' join: (change origins collect: [ :each | each name ])) ] ]
]

{ #category : 'accessing' }
CRChangePresenter >> iconName [

	^ self class iconNameFor: change
]

{ #category : 'initialization' }
CRChangePresenter >> initializePresenters [

	icon := self newImage.
	label := self newLabel.
	code := self newCode
		        beNotEditable;
		        yourself.
	diff := self newDiff
]

{ #category : 'accessing' }
CRChangePresenter >> isShowingCode [

	^ self layout children includes: code
]

{ #category : 'accessing' }
CRChangePresenter >> isShowingDiff [

	^ self layout children includes: diff
]

{ #category : 'accessing' }
CRChangePresenter >> label [

	^ label
]

{ #category : 'private' }
CRChangePresenter >> showCode [
	"The source of an addition (the new one) or a removal (the old one), colored as a method when it is one"

	change isMethod
		ifTrue: [
				code
					beForBehavior: (change imageClass ifNil: [ Object ]);
					withSyntaxHighlight ]
		ifFalse: [ code withoutSyntaxHighlight ].
	code text: (change kind = #removed
			 ifTrue: [ change oldSource ]
			 ifFalse: [ change newSource ])
]

{ #category : 'accessing' }
CRChangePresenter >> showsDiff [

	^ change isMoved or: [ change kind = #changed ]
]

{ #category : 'accessing' }
CRChangePresenter >> verb [

	change isMoved ifTrue: [ ^ 'Moved' ].
	^ (Dictionary newFromPairs: #( #added 'Added' #removed 'Removed' #changed 'Changed' )) at: change kind
]
