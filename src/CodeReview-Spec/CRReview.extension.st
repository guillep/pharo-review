Extension { #name : 'CRReview' }

{ #category : '*CodeReview-Spec' }
CRReview >> open [
	"Open the review tool. Every change must be in the tree first, and no part empty"

	self checkComplete.
	^ (CRReviewPresenter on: self) open
]
