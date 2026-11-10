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
	"anItem is in one place only: it leaves its previous part"

	anItem parent ifNotNil: [ :previous | previous remove: anItem ].
	children add: anItem.
	anItem parent: self.
	^ anItem
]

{ #category : 'accessing' }
CRPart >> addAll: aCollection [

	aCollection do: [ :each | self add: each ].
	^ aCollection
]

{ #category : 'accessing' }
CRPart >> children [

	^ children
]

{ #category : 'accessing' }
CRPart >> description [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: name;
				  nextPutAll: ': ';
				  nextPutAll: summary;
				  cr;
				  print: self lineCount;
				  nextPutAll: ' lines changed' ]
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
CRPart >> part: aName summary: aString [
	"Answer a new part below me"

	^ self add: (CRPart name: aName summary: aString)
]

{ #category : 'accessing' }
CRPart >> remove: anItem [

	children remove: anItem.
	anItem parent: nil
]

{ #category : 'accessing' }
CRPart >> setName: aName summary: aString [

	name := aName.
	summary := aString.
	children := OrderedCollection new
]

{ #category : 'accessing' }
CRPart >> summary [

	^ summary
]

{ #category : 'accessing' }
CRPart >> title [

	^ name
]
