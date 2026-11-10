"
I am one word of the vocabulary of a review: the changes whose added code uses it, and whether it is new (the code before the pull request did not use it). The tool shows me when grouping by vocabulary; my changes stay in their parts, so marking me marks them there.
"
Class {
	#name : 'CRWord',
	#superclass : 'CRItem',
	#instVars : [
		'word',
		'isNew',
		'changes'
	],
	#category : 'CodeReview',
	#package : 'CodeReview'
}

{ #category : 'instance creation' }
CRWord class >> word: aString new: aBoolean changes: aCollection [

	^ self new setWord: aString new: aBoolean changes: aCollection
]

{ #category : 'accessing' }
CRWord >> acceptsNote [
	"A note goes on a change or a part, where the export finds it"

	^ false
]

{ #category : 'accessing' }
CRWord >> children [

	^ changes
]

{ #category : 'accessing' }
CRWord >> description [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (isNew
						   ifTrue: [ 'A new word: ' ]
						   ifFalse: [ 'A word already used before the pull request: ' ]);
				  nextPutAll: word;
				  nextPutAll: '. The changes whose added code uses it.' ]
]

{ #category : 'accessing' }
CRWord >> isNew [

	^ isNew
]

{ #category : 'accessing' }
CRWord >> isReviewed [
	"Reviewed when all my changes are"

	^ changes allSatisfy: [ :each | each isReviewed ]
]

{ #category : 'accessing' }
CRWord >> lineCount [

	^ changes inject: 0 into: [ :sum :each | sum + each lineCount ]
]

{ #category : 'accessing' }
CRWord >> reviewed: aBoolean [
	"Mark my changes, in their parts"

	changes do: [ :each | each reviewed: aBoolean ]
]

{ #category : 'accessing' }
CRWord >> setWord: aString new: aBoolean changes: aCollection [

	word := aString.
	isNew := aBoolean.
	changes := aCollection
]

{ #category : 'filtering' }
CRWord >> sizeLabel [

	^ self sizeLabelShowing: [ :each | true ]
]

{ #category : 'filtering' }
CRWord >> sizeLabelShowing: aBlock [

	^ String streamContents: [ :stream |
			  stream
				  print: (self childrenShowing: aBlock) size;
				  nextPutAll: ' changes' ]
]

{ #category : 'accessing' }
CRWord >> title [

	^ isNew
		  ifTrue: [ word , ' (new)' ]
		  ifFalse: [ word ]
]

{ #category : 'accessing' }
CRWord >> word [

	^ word
]
