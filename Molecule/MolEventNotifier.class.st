"
I am responsable for trigger events.
"
Class {
	#name : #MolEventNotifier,
	#superclass : #Object,
	#instVars : [
		'interface',
		'originator',
		'isActive',
		'connections',
		'subscribers'
	],
	#category : #'Molecule-Core'
}

{ #category : #constructor }
MolEventNotifier class >> interface: aMolUsedEvents originator: aComponent [
	^ self new interface: aMolUsedEvents; originator: aComponent
]

{ #category : #actions }
MolEventNotifier >> activate [
	isActive := true
]

{ #category : #actions }
MolEventNotifier >> deactivate [
	isActive := false
]

{ #category : #'reflective operations' }
MolEventNotifier >> doesNotUnderstand: aMessage [

	"Event message is called by a Notifier, the message not exists in MolEventNotifier so the system called doesNotUnderstand: message. Check if the event message is known by the event interface and trigger the event."

	| isEventExist |
	interface ifNil: [ ^ super doesNotUnderstand: aMessage ].
	originator ifNil: [ 
		MolUtils log:
			'Originator not defined for event: ' , aMessage selector.
		^ self ].
	isEventExist := interface includesSelector: aMessage selector.

	isEventExist
		ifTrue: [ 
			isActive
				ifTrue: [
					MolUtils log:
						originator printString , ' send event: ' , aMessage selector.

					"--------------------------Time Travel--------------------------"
					originator isUsingTimeTravel
						ifFalse: [ 
							originator
								triggerEvent: aMessage selector
								withArguments: aMessage arguments ]
						ifTrue: [
							"Collect all the component that are subscribed to the event."
							connections := MolComponentManager default locatorServices
								               eventsSubscribers
								               at: interface
								               ifAbsent: [ ^ nil ].
							connections ifNotNil: [ 
								connections := connections observersConnection ].
							subscribers := OrderedCollection new.
							connections associationsDo: [ :assoc | 
								(assoc value includes: originator componentName) ifTrue: [ 
									subscribers add: assoc key ] ].
							"The variable : 'subscribers' , now contains all the subscribed components."
							"For each subscribed component, we check if it is a component that uses time travel and if so we log the event and the state of the component."
							subscribers do: [ :aComponent | 
								aComponent componentConnector ifNotNil: [ 
									aComponent getTimeTravelServicesProvider isNotFoundServices
										ifFalse: [ 
											aComponent getTimeTravelServicesProvider isRestoring 
												ifFalse: [ 
													aComponent getTimeTravelServicesProvider
														saveEvent: aMessage selector
														performBy: aComponent
														withParameters: aMessage arguments.

													aComponent
														perform: aMessage selector
														withArguments: aMessage arguments.

													aComponent saveForTimeTravel ] ]
										ifTrue: [ 
											aComponent
												perform: aMessage selector
												withArguments: aMessage arguments ] ] ] ] 
					"---------------------------------------------------------------"
				] ifFalse: [ 
					MolUtils log:
						'An inactive component: ' , originator printString
						, ' send event: ' , aMessage selector ].
			^ self ]
		ifFalse: [ 
			MolUtils log:
				originator printString , ' send an undefined event: '
				, aMessage selector ].

	^ super doesNotUnderstand: aMessage
]

{ #category : #'initialize-release' }
MolEventNotifier >> initialize [
	super initialize.
	self deactivate.
]

{ #category : #accessing }
MolEventNotifier >> interface [
	^ interface
]

{ #category : #accessing }
MolEventNotifier >> interface: anInterface [
	interface := anInterface
]

{ #category : #accessing }
MolEventNotifier >> isActive [
	^ isActive
]

{ #category : #'initialize-release' }
MolEventNotifier >> isNotFoundEventsNotifier [ 
	^false
]

{ #category : #accessing }
MolEventNotifier >> originator [
	^ originator
]

{ #category : #accessing }
MolEventNotifier >> originator: aComponent [
	originator := aComponent
]

{ #category : #'initialize-release' }
MolEventNotifier >> release [
	self deactivate.
	interface := nil.
	originator := nil.
	super release.
]
