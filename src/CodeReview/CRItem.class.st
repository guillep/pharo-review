"
I am one item of a code review: a part of what the pull request does, or one change. The reviewer marks me reviewed and writes a note on me.

My subclasses: CRPart (a part, with children) and CRChange (a change, a leaf).
"
Class {
	#name : 'CRItem',
	#superclass : 'Object',
	#instVars : [
		'parent',
		'reviewed',
		'note'
	],
	#category : 'CodeReview',
	#package : 'CodeReview'
}

{ #category : 'accessing' }
CRItem >> acceptsNote [
	"Whether the reviewer can write a note on me"

	^ true
]

{ #category : 'accessing' }
CRItem >> allItemsDo: aBlock [
	"Me and everything below me, depth first"

	aBlock value: self.
	self children do: [ :each | each allItemsDo: aBlock ]
]

{ #category : 'accessing' }
CRItem >> children [

	^ #(  )
]

{ #category : 'filtering' }
CRItem >> childrenShowing: aBlock [
	"My children that hold a change aBlock accepts"

	^ self children select: [ :each | each shows: aBlock ]
]

{ #category : 'accessing' }
CRItem >> description [
	"A few lines saying what I am, for the tool"

	^ self subclassResponsibility
]

{ #category : 'accessing' }
CRItem >> hasNote [

	^ note trimBoth isNotEmpty
]

{ #category : 'accessing' }
CRItem >> initialize [

	super initialize.
	reviewed := false.
	note := ''
]

{ #category : 'accessing' }
CRItem >> isBrowsable [
	"Whether I name code in the image"

	^ false
]

{ #category : 'accessing' }
CRItem >> isChange [

	^ false
]

{ #category : 'accessing' }
CRItem >> isReviewed [

	^ reviewed
]

{ #category : 'accessing' }
CRItem >> lineCount [
	"The lines added and removed under me"

	^ self subclassResponsibility
]

{ #category : 'filtering' }
CRItem >> lineCountShowing: aBlock [

	^ (self childrenShowing: aBlock) inject: 0 into: [ :sum :each | sum + (each lineCountShowing: aBlock) ]
]

{ #category : 'private' }
CRItem >> markWithChildren: aBoolean [

	reviewed := aBoolean.
	self children do: [ :each | each markWithChildren: aBoolean ]
]

{ #category : 'accessing' }
CRItem >> newSource [
	"What I am after the pull request: empty unless I am a change"

	^ ''
]

{ #category : 'accessing' }
CRItem >> note [

	^ note
]

{ #category : 'accessing' }
CRItem >> note: aString [

	note := aString
]

{ #category : 'accessing' }
CRItem >> oldSource [
	"What I was before the pull request: empty unless I am a change"

	^ ''
]

{ #category : 'accessing' }
CRItem >> parent [

	^ parent
]

{ #category : 'accessing' }
CRItem >> parent: aPart [

	parent := aPart
]

{ #category : 'accessing' }
CRItem >> place [
	"Where I am in the tree, from the first part below the review: 'Resolution › Interactive resolver › MetacelloResolution>>add:'"

	| names item |
	names := OrderedCollection new.
	item := self.
	[ item isNotNil and: [ item parent isNotNil ] ] whileTrue: [
			names addFirst: item title.
			item := item parent ].
	^ ' › ' join: names
]

{ #category : 'accessing' }
CRItem >> reviewed: aBoolean [
	"Mark me, and everything under me. A part is reviewed when everything under it is: marking my last unreviewed sibling marks my parent, and unmarking me unmarks my parents"

	self markWithChildren: aBoolean.
	parent ifNotNil: [ :part | part childReviewed: aBoolean ]
]

{ #category : 'filtering' }
CRItem >> shows: aBlock [
	"Whether a change under me is accepted by aBlock"

	^ (self childrenShowing: aBlock) isNotEmpty
]

{ #category : 'accessing' }
CRItem >> sizeLabel [
	"What the tree shows after my title: '12 lines', and the items for a part"

	^ self subclassResponsibility
]

{ #category : 'accessing' }
CRItem >> title [
	"One line naming me in the tree"

	^ self subclassResponsibility
]
