"
I am one change of a pull request: a method, a class definition or a file, added, removed or changed. I keep the old and the new source (empty when absent).

- kind: #added, #removed or #changed.
- packageName, className, selector: what I change; selector is nil for a class definition, className is nil for a file.
- protocol: the method's protocol (nil for a class definition or a file).
- path: the file, for a file change (a file of a package not loaded in the image, or not code).
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
		'protocol'
	],
	#category : 'CodeReview',
	#package : 'CodeReview'
}

{ #category : 'instance creation' }
CRChange class >> kind: aSymbol from: anOldString to: aNewString [
	"aSymbol is #added, #removed or #changed. Say then what I change: packageName:className:selector: or path:"

	^ self new setKind: aSymbol from: anOldString to: aNewString
]

{ #category : 'accessing' }
CRChange >> className [

	^ className
]

{ #category : 'accessing' }
CRChange >> description [

	^ String streamContents: [ :stream |
			  stream nextPutAll: self title.
			  packageName ifNotNil: [
					  stream
						  nextPutAll: ' (';
						  nextPutAll: packageName;
						  nextPutAll: ')' ] ]
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

{ #category : 'accessing' }
CRChange >> isMethod [

	^ selector isNotNil
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

{ #category : 'accessing' }
CRChange >> name [
	"What I change: Class>>selector, a class, or a file"

	self isFile ifTrue: [ ^ path ].
	self isMethod ifTrue: [ ^ className , '>>' , selector ].
	^ className
]

{ #category : 'accessing' }
CRChange >> newSource [

	^ newSource
]

{ #category : 'accessing' }
CRChange >> oldSource [

	^ oldSource
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

{ #category : 'accessing' }
CRChange >> sizeLabel [

	^ String streamContents: [ :stream |
			  stream
				  print: self lineCount;
				  nextPutAll: ' lines' ]
]

{ #category : 'accessing' }
CRChange >> title [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: self name;
				  space;
				  nextPutAll: kind ]
]
