"
I read the changes between two commits of an Iceberg repository as CRChanges.

Iceberg's diff gives methods and class definitions, but only for the packages the image has; every other changed file (a package not loaded, or a file that is not code) becomes one file change, so that nothing is left out.

	(CRIcebergReader repository: anIceRepository from: aCommit to: anotherCommit) changes
"
Class {
	#name : 'CRIcebergReader',
	#superclass : 'Object',
	#instVars : [
		'repository',
		'fromCommit',
		'toCommit'
	],
	#category : 'CodeReview',
	#package : 'CodeReview'
}

{ #category : 'instance creation' }
CRIcebergReader class >> repository: anIceRepository from: aCommit to: anotherCommit [

	^ self new setRepository: anIceRepository from: aCommit to: anotherCommit
]

{ #category : 'reading' }
CRIcebergReader >> changeFrom: anOperation in: aNode [
	"A change for a method, a class definition or a file Iceberg reports changed; nil for anything else (packages, extensions, unchanged containers)"

	| definition kind change |
	kind := self kindOf: anOperation.
	kind ifNil: [ ^ nil ].
	definition := anOperation definition.
	(definition isMethodDefinition or: [ definition isClassDefinition or: [ definition isFileDefinition ] ]) ifFalse: [ ^ nil ].
	change := CRChange
		          kind: kind
		          from: (anOperation isAddition
				           ifTrue: [ '' ]
				           ifFalse: [ anOperation rightContents ])
		          to: (anOperation isRemoval
				           ifTrue: [ '' ]
				           ifFalse: [ anOperation leftContents ]).
	definition isFileDefinition ifTrue: [
			^ change
				  path: aNode path pathString;
				  yourself ].
	definition isMethodDefinition ifTrue: [
			^ change
				  packageName: (self packageNameOf: aNode) className: (definition classIsMeta
						   ifTrue: [ definition className , ' class' ]
						   ifFalse: [ definition className ])
				  selector: definition name;
				  protocol: definition protocol asString;
				  yourself ].
	^ change
		  packageName: (self packageNameOf: aNode) className: definition name selector: nil;
		  yourself
]

{ #category : 'reading' }
CRIcebergReader >> changes [
	"Every change from fromCommit to toCommit: the code changes Iceberg details, then the other changed files"

	| changes covered |
	changes := OrderedCollection new.
	covered := Set new.
	(IceDiff from: toCommit to: fromCommit) tree allChildrenDo: [ :node |
			| operation |
			operation := node value.
			operation definition isPackageDefinition ifTrue: [ covered add: operation definition name ].
			operation definition isFileDefinition ifTrue: [ covered add: node path pathString ].
			(self changeFrom: operation in: node) ifNotNil: [ :change | changes add: change ] ].
	(toCommit changesTo: fromCommit) do: [ :each |
		(self isCovered: each path by: covered) ifFalse: [ changes add: (self fileChangeAt: each path) ] ].
	^ changes
]

{ #category : 'reading' }
CRIcebergReader >> contentsAt: aPath in: aCommit [
	"The contents of the file at aPath in aCommit, nil when it has none"

	| file |
	file := aCommit fileSystem resolve: aPath.
	^ file exists
		  ifTrue: [ file contents ]
		  ifFalse: [ nil ]
]

{ #category : 'reading' }
CRIcebergReader >> fileChangeAt: aPath [

	| old new |
	old := self contentsAt: aPath in: fromCommit.
	new := self contentsAt: aPath in: toCommit.
	^ (CRChange kind: (old ifNil: [ #added ] ifNotNil: [ new ifNil: [ #removed ] ifNotNil: [ #changed ] ]) from: old to: new)
		  path: aPath pathString;
		  yourself
]

{ #category : 'reading' }
CRIcebergReader >> isCovered: aPath by: aSet [
	"Whether Iceberg's diff already reported the file at aPath: a file it reports, or a file in a package it reports"

	(aSet includes: aPath pathString) ifTrue: [ ^ true ].
	^ aPath size >= 2 and: [ aSet includes: (aPath at: aPath size - 1) ]
]

{ #category : 'reading' }
CRIcebergReader >> kindOf: anOperation [
	"#added, #removed, #changed, or nil when unchanged"

	anOperation isAddition ifTrue: [ ^ #added ].
	anOperation isRemoval ifTrue: [ ^ #removed ].
	anOperation isModification ifTrue: [ ^ #changed ].
	^ nil
]

{ #category : 'reading' }
CRIcebergReader >> packageNameOf: aNode [

	| node |
	node := aNode.
	[ node isNil or: [ node value definition isPackageDefinition ] ] whileFalse: [ node := node parent ].
	^ node ifNotNil: [ node value definition name ]
]

{ #category : 'reading' }
CRIcebergReader >> setRepository: anIceRepository from: aCommit to: anotherCommit [

	repository := anIceRepository.
	fromCommit := aCommit.
	toCommit := anotherCommit
]
