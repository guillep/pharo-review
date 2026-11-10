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
	"aString split before capitals (keeping acronyms) and around numbers"

	| words current |
	words := OrderedCollection new.
	current := WriteStream on: String new.
	aString doWithIndex: [ :char :index |
			| previous next |
			previous := index > 1 ifTrue: [ aString at: index - 1 ].
			next := index < aString size ifTrue: [ aString at: index + 1 ].
			(previous notNil and: [
					 (char isUppercase and: [
						  previous isLowercase or: [ previous isDigit or: [ previous isUppercase and: [ next notNil and: [ next isLowercase ] ] ] ] ])
						 or: [ char isDigit ~= previous isDigit ] ]) ifTrue: [
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
CRVocabulary class >> wordsOf: anIdentifier [
	"anIdentifier split at colons and capitals (an acronym stays one word: MVSGraph -> mvs, graph), normalized, without numbers and the words that say nothing"

	| words |
	words := OrderedCollection new.
	(anIdentifier substrings: ':') do: [ :part | words addAll: (self splitCamelCase: part) ].
	^ (words collect: [ :each | self normalize: each ]) reject: [ :each |
		  each size < 2 or: [ each isAllDigits or: [ self stopWords includes: each ] ] ]
]
