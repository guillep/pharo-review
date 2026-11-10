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
		'changes'
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
CRReview >> changes [

	^ changes
]

{ #category : 'accessing' }
CRReview >> changesSuchThat: aBlock [

	^ changes select: aBlock
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

{ #category : 'accessing' }
CRReview >> root [
	"The part holding the whole tree; its children are the parts of the pull request"

	^ root
]

{ #category : 'accessing' }
CRReview >> setTitle: aString changes: aCollection [

	root := CRPart name: aString summary: ''.
	changes := aCollection asOrderedCollection
]

{ #category : 'accessing' }
CRReview >> title [

	^ root name
]

{ #category : 'accessing' }
CRReview >> unfiled [
	"The changes in no part yet"

	^ changes select: [ :each | each parent isNil ]
]
