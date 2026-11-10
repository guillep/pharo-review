"
I am one change of a pull request: a method, a class definition or a file, added, removed or changed. I keep the old and the new source (empty when absent).

- kind: #added, #removed or #changed.
- packageName, className, selector: what I change; selector is nil for a class definition, className is nil for a file.
- protocol: the method's protocol (nil for a class definition or a file).
- path: the file, for a file change (a file of a package not loaded in the image, or not code).
- commitMessages: why, from the history: the messages of the commits that touched me, oldest first. A commit that renamed my class does not lead back to the commits before it.
- origins / destinations: code moved or extracted. movedFrom: links me to the changes my code came from (a removal, or the old version of a modification); the tool then compares my code with theirs.
"
Class {
	#name : 'CRChange',
	#superclass : 'CRItem',
	#instVars : [
		'kind',
		'packageName',
		'className',
		'selector',
		'path',
		'oldSource',
		'newSource',
		'protocol',
		'commitMessages',
		'origins',
		'destinations'
	],
	#category : 'CodeReview',
	#package : 'CodeReview'
}

{ #category : 'instance creation' }
CRChange class >> kind: aSymbol from: anOldString to: aNewString [
	"aSymbol is #added, #removed or #changed. Say then what I change: packageName:className:selector: or path:"

	^ self new setKind: aSymbol from: anOldString to: aNewString
]

{ #category : 'moves' }
CRChange >> addDestination: aChange [

	destinations := self destinations copyWith: aChange
]

{ #category : 'vocabulary' }
CRChange >> addedWords [
	"The words of the names I add: my class and selector when I am added; none otherwise, nor for a file"

	(self isFile or: [ kind ~= #added ]) ifTrue: [ ^ #(  ) ].
	^ self nameWords
]

{ #category : 'accessing' }
CRChange >> baseClassName [
	"The class I change, without ' class' for the class side"

	^ className ifNotNil: [ className copyReplaceAll: ' class' with: '' ]
]

{ #category : 'accessing' }
CRChange >> className [

	^ className
]

{ #category : 'accessing' }
CRChange >> commitMessages [
	"The messages of the commits that touched me, oldest first"

	^ commitMessages ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
CRChange >> commitMessages: aCollection [

	commitMessages := aCollection
]

{ #category : 'accessing' }
CRChange >> description [

	^ String streamContents: [ :stream |
			  stream nextPutAll: self title.
			  packageName ifNotNil: [
					  stream
						  nextPutAll: ' (';
						  nextPutAll: packageName;
						  nextPutAll: ')' ].
			  self origins do: [ :each |
					  stream
						  cr;
						  nextPutAll: 'Moved from: ';
						  nextPutAll: each name ].
			  self destinations do: [ :each |
					  stream
						  cr;
						  nextPutAll: 'Moved to: ';
						  nextPutAll: each name ].
			  self commitMessages ifNotEmpty: [ :messages |
					  stream
						  cr;
						  cr;
						  nextPutAll: 'Why (the commits that touched it):'.
					  messages do: [ :each |
							  stream
								  cr;
								  cr;
								  nextPutAll: each trimBoth ] ] ]
]

{ #category : 'moves' }
CRChange >> destinations [
	"The changes my old code was moved or extracted to"

	^ destinations ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
CRChange >> imageClass [
	"The class I change, as the image has it now; nil for a file or a class the image does not have"

	| class |
	className ifNil: [ ^ nil ].
	class := Smalltalk globals classNamed: (className copyReplaceAll: ' class' with: '').
	class ifNil: [ ^ nil ].
	^ (className endsWith: ' class')
		  ifTrue: [ class class ]
		  ifFalse: [ class ]
]

{ #category : 'accessors' }
CRChange >> isAccessor [
	"Whether I am a method that only answers an instance variable (a getter) or only sets one to its argument (a setter)"

	| method |
	self isMethod ifFalse: [ ^ false ].
	method := [ RBParser parseMethod: (newSource ifNil: [ oldSource ]) ]
		          on: Error
		          do: [ ^ false ].
	method temporaries ifNotEmpty: [ ^ false ].
	^ (self isGetter: method) or: [ self isSetter: method ]
]

{ #category : 'accessing' }
CRChange >> isBrowsable [

	^ self isFile not
]

{ #category : 'accessing' }
CRChange >> isChange [

	^ true
]

{ #category : 'accessing' }
CRChange >> isFile [

	^ className isNil
]

{ #category : 'accessors' }
CRChange >> isGetter: aMethodNode [

	| statements |
	statements := aMethodNode body statements.
	^ aMethodNode arguments isEmpty and: [
		  statements size = 1 and: [ statements first isReturn and: [ self isInstanceVariable: statements first value ] ] ]
]

{ #category : 'accessors' }
CRChange >> isInstanceVariable: aNode [
	"Read without the class: a variable that is neither a pseudo-variable nor a global (capitalized)"

	^ aNode isVariable and: [
		  (#( 'self' 'super' 'thisContext' 'true' 'false' 'nil' ) includes: aNode name) not and: [ aNode name first isLowercase ] ]
]

{ #category : 'accessing' }
CRChange >> isMeta [
	"Whether I change the class side"

	^ className isNotNil and: [ className endsWith: ' class' ]
]

{ #category : 'accessing' }
CRChange >> isMethod [

	^ selector isNotNil
]

{ #category : 'moves' }
CRChange >> isMoved [
	"Whether my code came from other changes"

	^ self origins isNotEmpty
]

{ #category : 'accessors' }
CRChange >> isSetter: aMethodNode [

	| statements assignment |
	statements := aMethodNode body statements.
	aMethodNode arguments size = 1 ifFalse: [ ^ false ].
	(statements size between: 1 and: 2) ifFalse: [ ^ false ].
	assignment := statements first.
	assignment isAssignment ifFalse: [ ^ false ].
	(self isInstanceVariable: assignment variable) ifFalse: [ ^ false ].
	(assignment value isVariable and: [ assignment value name = aMethodNode arguments first name ]) ifFalse: [ ^ false ].
	^ statements size = 1 or: [
		  statements last isReturn and: [ statements last value isVariable and: [ statements last value name = 'self' ] ] ]
]

{ #category : 'testing' }
CRChange >> isTest [
	"Whether I change a test class"

	^ self imageClass ifNil: [ false ] ifNotNil: [ :class | class instanceSide isTestCase ]
]

{ #category : 'accessing' }
CRChange >> key [
	"What identifies what I change across commits"

	^ self name
]

{ #category : 'accessing' }
CRChange >> kind [

	^ kind
]

{ #category : 'accessing' }
CRChange >> lineCount [
	"The lines added and removed"

	| count |
	count := 0.
	(TextDiffBuilder from: oldSource to: newSource)
		patchSequenceDoIfMatch: [ :line |  ]
		ifInsert: [ :line | count := count + 1 ]
		ifRemove: [ :line | count := count + 1 ].
	^ count
]

{ #category : 'filtering' }
CRChange >> lineCountShowing: aBlock [

	^ self lineCount
]

{ #category : 'moves' }
CRChange >> movedFrom: aChange [
	"My code was moved or extracted from aChange (its old source)"

	(self origins includes: aChange) ifTrue: [ ^ self ].
	origins := self origins copyWith: aChange.
	aChange addDestination: self
]

{ #category : 'accessing' }
CRChange >> name [
	"What I change: Class>>selector, a class, or a file"

	self isFile ifTrue: [ ^ path ].
	self isMethod ifTrue: [ ^ className , '>>' , selector ].
	^ className
]

{ #category : 'vocabulary' }
CRChange >> nameWords [
	"The words of my class name, and of my selector when I am a method"

	| words |
	words := OrderedCollection withAll: (CRVocabulary wordsOf: (className copyReplaceAll: ' class' with: '')).
	selector ifNotNil: [ words addAll: (CRVocabulary wordsOf: selector) ].
	^ words asArray
]

{ #category : 'accessing' }
CRChange >> newSource [

	^ newSource
]

{ #category : 'accessing' }
CRChange >> oldSource [

	^ oldSource
]

{ #category : 'vocabulary' }
CRChange >> oldWords [
	"The words of the names there before me: my class and selector when I am changed or removed"

	(self isFile or: [ kind = #added ]) ifTrue: [ ^ #(  ) ].
	^ self nameWords
]

{ #category : 'moves' }
CRChange >> originSource [
	"The code mine was moved from: the old source of my origins"

	^ String cr , String cr join: (self origins collect: [ :each | each oldSource ])
]

{ #category : 'moves' }
CRChange >> origins [
	"The changes my code was moved or extracted from"

	^ origins ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
CRChange >> packageName [

	^ packageName
]

{ #category : 'accessing' }
CRChange >> packageName: aPackageName className: aClassName selector: aSelectorOrNil [
	"I change a method (aSelectorOrNil) or a class definition (nil)"

	packageName := aPackageName.
	className := aClassName.
	selector := aSelectorOrNil
]

{ #category : 'accessing' }
CRChange >> path [

	^ path
]

{ #category : 'accessing' }
CRChange >> path: aPath [
	"I change a whole file"

	path := aPath
]

{ #category : 'accessing' }
CRChange >> protocol [
	"The method's protocol; nil for a class definition or a file"

	^ protocol
]

{ #category : 'accessing' }
CRChange >> protocol: aString [

	protocol := aString
]

{ #category : 'accessing' }
CRChange >> selector [

	^ selector
]

{ #category : 'accessing' }
CRChange >> setKind: aSymbol from: anOldString to: aNewString [

	kind := aSymbol.
	oldSource := anOldString ifNil: [ '' ].
	newSource := aNewString ifNil: [ '' ]
]

{ #category : 'filtering' }
CRChange >> shows: aBlock [

	^ aBlock value: self
]

{ #category : 'accessing' }
CRChange >> sizeLabel [

	^ String streamContents: [ :stream |
			  stream
				  print: self lineCount;
				  nextPutAll: ' lines' ]
]

{ #category : 'filtering' }
CRChange >> sizeLabelShowing: aBlock [

	^ self sizeLabel
]

{ #category : 'comparing' }
CRChange >> sortsBefore: aChange [
	"The order of changes in a review: code before files; by class, its definition before its methods, instance side before class side; then by selector"

	self isFile = aChange isFile ifFalse: [ ^ aChange isFile ].
	self isFile ifTrue: [ ^ path <= aChange path ].
	self baseClassName = aChange baseClassName ifFalse: [ ^ self baseClassName < aChange baseClassName ].
	self isMethod = aChange isMethod ifFalse: [ ^ aChange isMethod ].
	self isMethod ifFalse: [ ^ true ].
	self isMeta = aChange isMeta ifFalse: [ ^ aChange isMeta ].
	^ selector <= aChange selector
]

{ #category : 'accessing' }
CRChange >> title [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: self name;
				  space;
				  nextPutAll: kind ]
]
