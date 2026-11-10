"
I am the review of a pull request: every change it makes, grouped into a tree of parts.

	review := CRReview repository: 'pharo' from: '6e5455cd' to: 'HEAD'.
	resolution := review part: 'Resolution' summary: 'Choose versions before loading'.
	resolution addAll: (review changesSuchThat: [ :each | each className = 'MetacelloResolution' ]).
	review unfiled.	""the changes in no part yet""
	review open.	""the review tool; refuses while a change is unfiled""
	review markdown.	""the reviewer's notes, as the tool's Export button copies them""

The changes can also be given (CRReview title:changes:), for tests.
"
Class {
	#name : 'CRReview',
	#superclass : 'Object',
	#instVars : [
		'root',
		'changes',
		'vocabulary'
	],
	#category : 'CodeReview',
	#package : 'CodeReview'
}

{ #category : 'instance creation' }
CRReview class >> commit: aCommitish in: anIceRepository [

	aCommitish = 'HEAD' ifTrue: [ ^ anIceRepository headCommit ].
	^ anIceRepository lookupCommit: aCommitish
]

{ #category : 'instance creation' }
CRReview class >> repository: aRepositoryName from: aCommitish to: anotherCommitish [
	"The changes from aCommitish to anotherCommitish (a commit id, or 'HEAD') in the Iceberg repository named aRepositoryName"

	| repository from to |
	repository := IceRepository registry detect: [ :each | each name = aRepositoryName ].
	from := self commit: aCommitish in: repository.
	to := self commit: anotherCommitish in: repository.
	^ self
		  title: aRepositoryName , ' ' , from shortId , '..' , to shortId
		  changes: (CRIcebergReader repository: repository from: from to: to) changes
]

{ #category : 'instance creation' }
CRReview class >> title: aString changes: aCollection [

	^ self new setTitle: aString changes: aCollection
]

{ #category : 'accessing' }
CRReview >> changeNamed: aString [
	"The change of 'Class>>selector', 'Class class>>selector', a class name or a file path"

	^ self changeNamed: aString ifNone: [ self error: 'No change named ' , aString ]
]

{ #category : 'accessing' }
CRReview >> changeNamed: aString ifNone: aBlock [

	^ changes detect: [ :each | each name = aString ] ifNone: aBlock
]

{ #category : 'accessing' }
CRReview >> changes [

	^ changes
]

{ #category : 'accessing' }
CRReview >> changesSuchThat: aBlock [

	^ changes select: aBlock
]

{ #category : 'accessing' }
CRReview >> checkComplete [
	"Signal an error unless every change is in the tree and every part holds something"

	self unfiled ifNotEmpty: [ :missing | ^ self error: missing size printString , ' changes are in no part (see unfiled)' ].
	self emptyParts ifNotEmpty: [ :empty | ^ self error: empty size printString , ' parts are empty (see emptyParts)' ]
]

{ #category : 'vocabulary' }
CRReview >> computeVocabulary [

	| byWord base |
	byWord := Dictionary new.
	changes do: [ :change |
		change addedWords asSet do: [ :word | (byWord at: word ifAbsentPut: [ OrderedCollection new ]) add: change ] ].
	base := self wordsBefore.
	^ (byWord associations collect: [ :each | CRWord word: each key new: (base includes: each key) not changes: each value asArray ])
		  asSortedCollection: [ :a :b |
				  a isNew = b isNew
					  ifTrue: [ a word <= b word ]
					  ifFalse: [ a isNew ] ]
]

{ #category : 'accessing' }
CRReview >> emptyParts [
	"The parts that hold nothing: the tool would show them as 0 items"

	^ root emptyParts
]

{ #category : 'accessing' }
CRReview >> items [
	"Every part and change, depth first"

	| items |
	items := OrderedCollection new.
	root children do: [ :each | each allItemsDo: [ :item | items add: item ] ].
	^ items
]

{ #category : 'accessing' }
CRReview >> lineCount [

	^ changes inject: 0 into: [ :sum :each | sum + each lineCount ]
]

{ #category : 'exporting' }
CRReview >> markdown [
	"The reviewer's notes, for the chat: a header with the progress, every item with a note (its place, whether it is reviewed), then the items not reviewed yet"

	| items noted pending |
	items := self items.
	noted := items select: [ :each | each hasNote ].
	pending := items reject: [ :each | each isReviewed ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: '# Review: ';
				  nextPutAll: self title;
				  lf;
				  lf;
				  print: (items count: [ :each | each isReviewed ]);
				  nextPutAll: ' of ';
				  print: items size;
				  nextPutAll: ' items reviewed.';
				  lf.
			  noted ifNotEmpty: [
					  stream
						  lf;
						  nextPutAll: '## Notes';
						  lf.
					  noted do: [ :each |
							  stream
								  lf;
								  nextPutAll: '### ';
								  nextPutAll: each place;
								  nextPutAll: (each isReviewed
										   ifTrue: [ ' (reviewed)' ]
										   ifFalse: [ ' (not reviewed)' ]);
								  lf;
								  lf;
								  nextPutAll: each note trimBoth;
								  lf ] ].
			  pending ifNotEmpty: [
					  stream
						  lf;
						  nextPutAll: '## Not reviewed yet';
						  lf;
						  lf.
					  pending do: [ :each |
							  stream
								  nextPutAll: '- ';
								  nextPutAll: each place;
								  lf ] ] ]
]

{ #category : 'accessing' }
CRReview >> part: aName summary: aString [
	"Answer a new part of the pull request, at the top of the tree"

	^ root part: aName summary: aString
]

{ #category : 'refreshing' }
CRReview >> reuse: anOldReview [
	"Take the tree of anOldReview (a review of an earlier state of the branch): its parts and their notes, and each change placed where the change of the same name was, with its note, its moves, and its mark when its code is the same. A change anOldReview did not have goes next to a change of its class. Answer the changes left unfiled"

	| partFor |
	partFor := Dictionary new.
	partFor at: anOldReview root put: root.
	anOldReview items do: [ :each |
			each isChange ifFalse: [
					(partFor at: each parent) add: ((partFor at: each put: (CRPart name: each name summary: each summary))
							 note: each note;
							 yourself) ] ].
	changes do: [ :each |
			(anOldReview changeNamed: each name ifNone: [ nil ])
				ifNotNil: [ :old |
						partFor at: old parent ifPresent: [ :part | part add: each ].
						each note: old note ]
				ifNil: [
						(anOldReview changes detect: [ :old | old baseClassName = each baseClassName and: [ old parent isNotNil ] ] ifNone: [ nil ])
							ifNotNil: [ :sibling | (partFor at: sibling parent) add: each ] ] ].
	self reuseMovesOf: anOldReview.
	self reuseMarksOf: anOldReview.
	^ self unfiled
]

{ #category : 'refreshing' }
CRReview >> reuseMarksOf: anOldReview [
	"A change keeps its mark when its code did not change; parts follow their changes"

	changes do: [ :each |
			(anOldReview changeNamed: each name ifNone: [ nil ]) ifNotNil: [ :old |
				(old isReviewed and: [ old oldSource = each oldSource and: [ old newSource = each newSource ] ]) ifTrue: [
					each reviewed: true ] ] ]
]

{ #category : 'refreshing' }
CRReview >> reuseMovesOf: anOldReview [

	anOldReview changes do: [ :old |
			old origins do: [ :origin |
					(self changeNamed: old name ifNone: [ nil ]) ifNotNil: [ :new |
						(self changeNamed: origin name ifNone: [ nil ]) ifNotNil: [ :newOrigin | new movedFrom: newOrigin ] ] ] ]
]

{ #category : 'accessing' }
CRReview >> root [
	"The part holding the whole tree; its children are the parts of the pull request"

	^ root
]

{ #category : 'accessing' }
CRReview >> setTitle: aString changes: aCollection [
	"The changes are kept in the review's order (see CRChange>>sortsBefore:), so any part filled from them is in that order"

	root := CRPart name: aString summary: ''.
	changes := (aCollection asSortedCollection: [ :a :b | a sortsBefore: b ]) asOrderedCollection
]

{ #category : 'accessing' }
CRReview >> title [

	^ root name
]

{ #category : 'accessing' }
CRReview >> unfiled [
	"The changes the tree does not reach: in no part yet, or in a part that is no longer in the tree"

	| filed |
	filed := root allChanges asIdentitySet.
	^ changes reject: [ :each | filed includes: each ]
]

{ #category : 'vocabulary' }
CRReview >> vocabulary [
	"One CRWord per word of the added code, with the changes that use it: the new words first, then the others, each alphabetically. Computed once"

	^ vocabulary ifNil: [ vocabulary := self computeVocabulary ]
]

{ #category : 'vocabulary' }
CRReview >> wordsBefore [
	"The words of the code before the pull request: the old code of my changes, and every method of the packages they touch that they leave as it is (read from the image)"

	| words changed |
	words := Set new.
	changes do: [ :each | words addAll: each oldWords ].
	changed := (changes select: [ :each | each isMethod ]) collect: [ :each | each className -> each selector ] as: Set.
	((changes collect: [ :each | each packageName ] as: Set) reject: [ :each | each isNil ]) do: [ :packageName |
			(PackageOrganizer default packageNamed: packageName ifAbsent: [ nil ]) ifNotNil: [ :package |
					package methods do: [ :method |
							(changed includes: method methodClass name asString -> method selector) ifFalse: [
								words addAll: (CRVocabulary wordsIn: method sourceCode) ] ] ] ].
	^ words
]
