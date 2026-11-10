"
I test how CRIcebergReader decides that Iceberg's diff already reported a changed file. Reading a real repository is not tested here: it needs one.
"
Class {
	#name : 'CRIcebergReaderTest',
	#superclass : 'TestCase',
	#category : 'CodeReview-Tests',
	#package : 'CodeReview-Tests'
}

{ #category : 'tests' }
CRIcebergReaderTest >> testAFileOfAPackageReportedIsCovered [

	self assert:
		(CRIcebergReader new isCovered: (Path from: 'src/Metacello-Core/Metacello.class.st') by: (Set with: 'Metacello-Core'))
]

{ #category : 'tests' }
CRIcebergReaderTest >> testAFileOfAnotherPackageIsNotCovered [

	self deny:
		(CRIcebergReader new isCovered: (Path from: 'src/Debugger-Model/DebugContext.class.st') by: (Set with: 'Metacello-Core'))
]

{ #category : 'tests' }
CRIcebergReaderTest >> testAFileReportedIsCovered [

	self assert: (CRIcebergReader new isCovered: (Path from: '.project') by: (Set with: '.project'))
]
