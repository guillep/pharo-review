"
I show the description of the pull request under review, which the reviewer may edit, and the reviewer's note on it. CRReviewPresenter shows me in its Pull request tab.
"
Class {
	#name : 'CRPullRequestPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'review',
		'description',
		'note'
	],
	#category : 'CodeReview-Spec',
	#package : 'CodeReview-Spec'
}

{ #category : 'layout' }
CRPullRequestPresenter >> defaultLayout [
	^ SpPanedLayout newTopToBottom
		  positionOfSlider: 0.75;
		  add: description;
		  add: note;
		  yourself
]

{ #category : 'accessing' }
CRPullRequestPresenter >> description [
	^ description
]

{ #category : 'initialization' }
CRPullRequestPresenter >> initializePresenters [
	description := self newText
		               text: review description;
		               whenTextChangedDo: [ :text | review description: text asString ];
		               yourself.
	note := self newText
		        placeholder: 'Note on the description';
		        text: review descriptionNote;
		        whenTextChangedDo: [ :text | review descriptionNote: text asString ];
		        yourself
]

{ #category : 'accessing' }
CRPullRequestPresenter >> note [
	^ note
]

{ #category : 'initialization' }
CRPullRequestPresenter >> setModelBeforeInitialization: aReview [
	review := aReview
]
