"
I am a part of what a pull request does: a name, a one-line summary of my purpose, and my children, which are smaller parts or changes.

Build me with part:summary: and fill me with add: or addAll: (a change is in one part only: adding it here takes it out of its previous part).
"
Class {
	#name : 'CRPart',
	#superclass : 'CRItem',
	#instVars : [
		'name',
		'summary',
		'children'
	],
	#category : 'CodeReview',
	#package : 'CodeReview'
}

{ #category : 'instance creation' }
CRPart class >> name: aName summary: aString [

	^ self new setName: aName summary: aString
]

{ #category : 'accessing' }
CRPart >> add: anItem [
	"anItem is in one place only: it leaves its previous part. My sub-parts come first, in the order they were added (the reading order); then my changes, in the review's order (CRChange>>sortsBefore:)"

	| index |
	anItem parent ifNotNil: [ :previous | previous remove: anItem ].
	index := anItem isChange
		         ifTrue: [ children findFirst: [ :each | each isChange and: [ anItem sortsBefore: each ] ] ]
		         ifFalse: [ children findFirst: [ :each | each isChange ] ].
	index = 0
		ifTrue: [ children addLast: anItem ]
		ifFalse: [ children add: anItem beforeIndex: index ].
	anItem parent: self.
	^ anItem
]

{ #category : 'accessing' }
CRPart >> addAll: aCollection [

	aCollection do: [ :each | self add: each ].
	^ aCollection
]

{ #category : 'accessing' }
CRPart >> allChanges [
	"Every change under me, at any depth"

	^ children inject: OrderedCollection new into: [ :all :each |
			  each isChange
				  ifTrue: [ all add: each ]
				  ifFalse: [ all addAll: each allChanges ].
			  all ]
]

{ #category : 'accessing' }
CRPart >> childReviewed: aBoolean [
	"One of my children was marked (or unmarked): I am reviewed when all of them are. Unmarking leaves my other children as they are"

	aBoolean
		ifTrue: [ (reviewed not and: [ children allSatisfy: [ :each | each isReviewed ] ]) ifTrue: [ self reviewed: true ] ]
		ifFalse: [
				reviewed ifTrue: [
						reviewed := false.
						parent ifNotNil: [ :part | part childReviewed: false ] ] ]
]

{ #category : 'accessing' }
CRPart >> children [

	^ children
]

{ #category : 'accessing' }
CRPart >> description [

	^ String streamContents: [ :stream |
			  stream nextPutAll: name.
			  summary ifNotEmpty: [
					  stream
						  nextPutAll: ': ';
						  nextPutAll: summary ].
			  stream
				  cr;
				  print: children size;
				  nextPutAll: ' items, ';
				  print: self lineCount;
				  nextPutAll: ' lines changed' ]
]

{ #category : 'accessing' }
CRPart >> emptyParts [
	"The parts under me, at any depth, that hold nothing"

	^ children inject: OrderedCollection new into: [ :all :each |
			  each isChange ifFalse: [
					  each children ifEmpty: [ all add: each ].
					  all addAll: each emptyParts ].
			  all ]
]

{ #category : 'accessing' }
CRPart >> groupBy: aBlock [
	"Move my changes (not my sub-parts) into new sub-parts, one per key aBlock answers for a change (a String naming the sub-part), in key order. Answer the new sub-parts"

	| groups |
	groups := Dictionary new.
	children do: [ :each |
		each isChange ifTrue: [ (groups at: (aBlock value: each) ifAbsentPut: [ OrderedCollection new ]) add: each ] ].
	^ groups keys sorted collect: [ :key |
			  (self part: key summary: '')
				  addAll: (groups at: key);
				  yourself ]
]

{ #category : 'accessing' }
CRPart >> lineCount [

	^ children inject: 0 into: [ :sum :each | sum + each lineCount ]
]

{ #category : 'accessing' }
CRPart >> name [

	^ name
]

{ #category : 'accessing' }
CRPart >> name: aString [
	"Rename me, keeping what I hold"

	name := aString
]

{ #category : 'accessing' }
CRPart >> part: aName summary: aString [
	"Answer a new part below me"

	^ self add: (CRPart name: aName summary: aString)
]

{ #category : 'accessing' }
CRPart >> remove: anItem [

	children remove: anItem.
	anItem parent: nil
]

{ #category : 'initialization' }
CRPart >> setName: aName summary: aString [

	name := aName.
	summary := aString.
	children := OrderedCollection new
]

{ #category : 'filtering' }
CRPart >> sizeLabel [

	^ self sizeLabelShowing: [ :each | true ]
]

{ #category : 'filtering' }
CRPart >> sizeLabelShowing: aBlock [

	^ String streamContents: [ :stream |
			  stream
				  print: (self childrenShowing: aBlock) size;
				  nextPutAll: ' items, ';
				  print: (self lineCountShowing: aBlock);
				  nextPutAll: ' lines' ]
]

{ #category : 'accessing' }
CRPart >> summary [

	^ summary
]

{ #category : 'accessing' }
CRPart >> summary: aString [

	summary := aString
]

{ #category : 'accessing' }
CRPart >> title [

	^ name
]
