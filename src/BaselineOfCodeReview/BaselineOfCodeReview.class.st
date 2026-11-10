"
I load the code review tool: CodeReview (the review and its API), CodeReview-Spec (the tool) and CodeReview-Tests.
"
Class {
	#name : 'BaselineOfCodeReview',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfCodeReview',
	#package : 'BaselineOfCodeReview'
}

{ #category : 'baselines' }
BaselineOfCodeReview >> baseline: spec [

	<baseline>
	spec for: #common do: [
			spec
				package: 'CodeReview';
				package: 'CodeReview-Spec' with: [ spec requires: #( 'CodeReview' ) ];
				package: 'CodeReview-Tests' with: [ spec requires: #( 'CodeReview-Spec' ) ].
			spec
				group: 'Core' with: #( 'CodeReview' 'CodeReview-Spec' );
				group: 'default' with: #( 'Core' 'CodeReview-Tests' ) ]
]
