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
CRIcebergReader >> addCommitMessagesTo: aCollectionOfChanges [
	"Each change gets the messages of the commits in the range that touched what it changes"

	| messages |
	messages := Dictionary new.
	self commitsInRange do: [ :commit |
			(self changesFrom: commit ancestors first to: commit) do: [ :each |
				(messages at: each key ifAbsentPut: [ OrderedCollection new ]) add: commit comment ] ].
	aCollectionOfChanges do: [ :each | each commitMessages: (messages at: each key ifAbsent: [ #(  ) ]) ]
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
	"Every change from fromCommit to toCommit: the code changes Iceberg details, then the other changed files; each knows the commits that touched it"

	| changes |
	changes := self changesFrom: fromCommit to: toCommit.
	self addCommitMessagesTo: changes.
	^ changes
]

{ #category : 'reading' }
CRIcebergReader >> changesFrom: aCommit to: anotherCommit [

	| changes covered |
	changes := OrderedCollection new.
	covered := Set new.
	(IceDiff from: anotherCommit to: aCommit) tree allChildrenDo: [ :node |
			| operation |
			operation := node value.
			operation definition isPackageDefinition ifTrue: [ covered add: operation definition name ].
			operation definition isFileDefinition ifTrue: [ covered add: node path pathString ].
			(self changeFrom: operation in: node) ifNotNil: [ :change | changes add: change ] ].
	(anotherCommit changesTo: aCommit) do: [ :each |
		(self isCovered: each path by: covered) ifFalse: [ changes add: (self fileChangeAt: each path from: aCommit to: anotherCommit) ] ].
	^ changes
]

{ #category : 'reading' }
CRIcebergReader >> commitsInRange [
	"The commits after fromCommit up to toCommit, oldest first, following first parents"

	| commits commit |
	commits := OrderedCollection new.
	commit := toCommit.
	[ commit id = fromCommit id or: [ commit ancestors isEmpty ] ] whileFalse: [
			commits addFirst: commit.
			commit := commit ancestors first ].
	^ commits
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
CRIcebergReader >> fileChangeAt: aPath from: aCommit to: anotherCommit [

	| old new |
	old := self contentsAt: aPath in: aCommit.
	new := self contentsAt: aPath in: anotherCommit.
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
