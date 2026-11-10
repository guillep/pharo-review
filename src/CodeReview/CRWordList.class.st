Class {
	#name : 'CRWordList',
	#superclass : 'CRItem',
	#instVars : [
		'name',
		'words'
	],
	#category : 'CodeReview',
	#package : 'CodeReview'
}

{ #category : 'instance creation' }
CRWordList class >> name: aString words: aCollection [

	^ self new setName: aString words: aCollection
]

{ #category : 'accessing' }
CRWordList >> acceptsNote [
	"A note goes on a change or a part, where the export finds it"

	^ false
]

{ #category : 'accessing' }
CRWordList >> children [

	^ words
]

{ #category : 'accessing' }
CRWordList >> description [

	^ name , ': the words of the class and method names the pull request adds, new ones first.'
]

{ #category : 'accessing' }
CRWordList >> isReviewed [
	"Reviewed when all my words are"

	^ words allSatisfy: [ :each | each isReviewed ]
]

{ #category : 'accessing' }
CRWordList >> isWordList [

	^ true
]

{ #category : 'accessing' }
CRWordList >> lineCount [

	^ words inject: 0 into: [ :sum :each | sum + each lineCount ]
]

{ #category : 'accessing' }
CRWordList >> reviewed: aBoolean [
	"Mark the changes of my words, in their parts"

	words do: [ :each | each reviewed: aBoolean ]
]

{ #category : 'accessing' }
CRWordList >> setName: aString words: aCollection [

	name := aString.
	words := aCollection
]

{ #category : 'accessing' }
CRWordList >> sizeLabel [

	^ self sizeLabelShowing: [ :each | true ]
]

{ #category : 'accessing' }
CRWordList >> sizeLabelShowing: aBlock [

	^ String streamContents: [ :stream |
			  stream
				  print: (self childrenShowing: aBlock) size;
				  nextPutAll: ' words' ]
]

{ #category : 'accessing' }
CRWordList >> title [

	^ name
]
