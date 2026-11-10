"
I extract the vocabulary of Smalltalk code: the words of its identifiers (selectors, variables, class names and symbols, not comments nor strings), split at capitals and colons, lowercased, plurals made singular, and the words that say nothing left out (a, an, the, self...).

	CRVocabulary wordsIn: 'at: aKey put: resolvedProjects'   ""#('at' 'key' 'put' 'resolved' 'project')""
"
Class {
	#name : 'CRVocabulary',
	#superclass : 'Object',
	#category : 'CodeReview',
	#package : 'CodeReview'
}

{ #category : 'extracting' }
CRVocabulary class >> identifierOf: aToken [
	"The identifier aToken names: an identifier, a keyword or a symbol; nil for anything else (strings, numbers, punctuation)"

	(aToken isIdentifier or: [ aToken isKeyword ]) ifTrue: [ ^ aToken value ].
	(aToken isLiteralToken and: [ aToken value isSymbol ]) ifTrue: [ ^ aToken value ].
	^ nil
]

{ #category : 'extracting' }
CRVocabulary class >> lineOf: aPosition in: aCollectionOfLineStarts [

	^ (aCollectionOfLineStarts findLast: [ :start | start <= aPosition ]) max: 1
]

{ #category : 'extracting' }
CRVocabulary class >> lineStartsOf: aString [

	| starts |
	starts := OrderedCollection with: 1.
	aString doWithIndex: [ :char :index | (char = Character cr or: [ char = Character lf ]) ifTrue: [ starts add: index + 1 ] ].
	^ starts
]

{ #category : 'extracting' }
CRVocabulary class >> normalize: aWord [
	"Lowercase and singular"

	| word |
	word := aWord asLowercase.
	(word size > 4 and: [ word endsWith: 'ies' ]) ifTrue: [ ^ (word allButLast: 3) , 'y' ].
	(word size > 3 and: [ (word endsWith: 's') and: [ (#( 'ss' 'us' 'is' ) anySatisfy: [ :ending | word endsWith: ending ]) not ] ])
		ifTrue: [ ^ word allButLast ].
	^ word
]

{ #category : 'extracting' }
CRVocabulary class >> splitCamelCase: aString [

	| words current |
	words := OrderedCollection new.
	current := WriteStream on: String new.
	aString doWithIndex: [ :char :index |
			| previous next |
			previous := index > 1 ifTrue: [ aString at: index - 1 ].
			next := index < aString size ifTrue: [ aString at: index + 1 ].
			(char isUppercase and: [
				 previous notNil and: [ previous isLowercase or: [ previous isUppercase and: [ next notNil and: [ next isLowercase ] ] ] ] ])
				ifTrue: [
						words add: current contents.
						current := WriteStream on: String new ].
			char isAlphaNumeric ifTrue: [ current nextPut: char ] ].
	words add: current contents.
	^ words reject: [ :each | each isEmpty ]
]

{ #category : 'extracting' }
CRVocabulary class >> stopWords [

	^ #( 'an' 'the' 'self' 'super' 'thiscontext' 'true' 'false' 'nil' 'of' 'to' 'in' 'on' 'or' 'and' 'with' 'for' 'at' 'by' 'is' 'it'
	     'if' 'do' 'as' ) asSet
]

{ #category : 'extracting' }
CRVocabulary class >> wordsIn: aSource [
	"The words of every identifier in aSource"

	^ self wordsIn: aSource onLines: nil
]

{ #category : 'extracting' }
CRVocabulary class >> wordsIn: aSource onLines: aSetOfLineNumbersOrNil [
	"The words of the identifiers in aSource, only those on aSetOfLineNumbersOrNil when given (1-based). Code that does not scan has no words"

	| tokens lineStarts words |
	tokens := [ (RBScanner on: aSource readStream) contents ]
		          on: Error
		          do: [ ^ #(  ) ].
	lineStarts := self lineStartsOf: aSource.
	words := OrderedCollection new.
	tokens do: [ :token |
			(aSetOfLineNumbersOrNil isNil or: [ aSetOfLineNumbersOrNil includes: (self lineOf: token start in: lineStarts) ]) ifTrue: [
				(self identifierOf: token) ifNotNil: [ :identifier | words addAll: (self wordsOf: identifier) ] ] ].
	^ words asArray
]

{ #category : 'extracting' }
CRVocabulary class >> wordsOf: anIdentifier [
	"anIdentifier split at colons and capitals (an acronym stays one word: MVSGraph -> mvs, graph), normalized, without the words that say nothing"

	| words |
	words := OrderedCollection new.
	(anIdentifier substrings: ':') do: [ :part | words addAll: (self splitCamelCase: part) ].
	^ (words collect: [ :each | self normalize: each ]) reject: [ :each | each size < 2 or: [ self stopWords includes: each ] ]
]
