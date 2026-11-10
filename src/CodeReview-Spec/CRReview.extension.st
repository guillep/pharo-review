Extension { #name : 'CRReview' }

{ #category : '*CodeReview-Spec' }
CRReview >> open [
	"Open the review tool. Every change must be in a part first"

	self unfiled ifNotEmpty: [ :missing | ^ self error: missing size printString , ' changes are in no part (see unfiled)' ].
	^ (CRReviewPresenter on: self) open
]
