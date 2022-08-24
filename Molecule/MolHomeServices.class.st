"
I am responsible for manage components life cycle. 

When a component is instanciated, it is initialized. After, you can alternatively activate and passivate a component as you want. At system closure, all the components are passivate, then removed.

See examples of my use in Tests and Examples packages.

"
Class {
	#name : #MolHomeServices,
	#superclass : #Object,
	#instVars : [
		'deployedComponents',
		'waitingForActivation'
	],
	#category : #'Molecule-Core'
}

{ #category : #'life cycle' }
MolHomeServices >> activateAllComponents [
	| waitingComponents |
	
	waitingComponents := waitingForActivation copy.
	waitingComponents do: [ :component |
		self activateComponent: component class named: component componentName.
	]
]

{ #category : #'life cycle' }
MolHomeServices >> activateComponent: aComponentClass [
	^ self activateComponent: aComponentClass named: #default
]

{ #category : #private }
MolHomeServices >> addDeployedComponent: aComponentClass [
	self deployedComponents at: aComponentClass ifAbsentPut: [Dictionary new]
]

{ #category : #private }
MolHomeServices >> checkInstanciationOfComponent: arg1 named: arg2 [

	| tmp1 tmp2 tmp3 |
	arg2 ifNil: [ 
		^ WrongComponentNameError new messageText:
			  'Can not instanciate a component without name' ].
	arg2 isSymbol ifFalse: [ 
		^ WrongComponentNameError new messageText:
			  'Can not instanciate a component with a name wish is not a symbol' ].
	tmp1 := self deployedComponents at: arg1 ifAbsent: [ 
		        ^ ComponentNotDeployedError new messageText:
			          'Can not instanciate a non deployed component' ].
	tmp1 at: arg2 ifPresent: [ :arg3 | 
		arg3 ifNotNil: [ 
			^ ComponentAlreadyExistsError new messageText:
				  'Can not instanciate a component with the same name of another component, please change the name of the component' ] ].
	tmp2 := MolComponentManager default locatorServices
		        searchComponentTypeImplementorFor: arg1 componentType
		        named: arg2.
	tmp2 ifNotNil: [ 
		^ ComponentAlreadyExistsError new messageText:
			  'Can not instanciate a component with the same type and name of another component, please change the name of the component' ].
	arg1 componentType allProvidedServices do: [ :arg4 | 
		(MolComponentManager default locatorServices
			 searchServicesProviderFor: arg4
			 named: arg2) isNotFoundServices ifFalse: [ 
			^ ComponentProvidedServicesAlreadyExistsError new messageText:
				  'Can not instanciate a component with the same services and name of another component, please change the name of the component' ] ].
	arg1 componentType allProvidedParameters do: [ :arg5 | 
		(MolComponentManager default locatorServices
			 searchParametersProviderFor: arg5
			 named: arg2) isNotFoundParameters ifFalse: [ 
			^ ComponentProvidedParametersAlreadyExistsError new messageText:
				  'Can not instanciate a component with the same parameters and name of another component, please change the name of the component' ] ].
	arg1 isOverrideComponentType ifTrue: [ 
		tmp3 := arg1 overridedComponentTypes.
		tmp3 do: [ :arg6 | 
			arg6 allProvidedServices do: [ :arg7 | 
				(MolComponentManager default locatorServices
					 searchServicesProviderFor: arg7
					 named: arg2) isNotFoundServices ifFalse: [ 
					^ ComponentProvidedServicesAlreadyExistsError new messageText:
						  '(Inheritance problem) Can not instanciate a component with the same services and name of another component, please change the name of the component' ] ].
			arg6 allProvidedParameters do: [ :arg8 | 
				(MolComponentManager default locatorServices
					 searchParametersProviderFor: arg8
					 named: arg2) isNotFoundParameters ifFalse: [ 
					^ ComponentProvidedServicesAlreadyExistsError new messageText:
						  '(Inheritance problem) Can not instanciate a component with the same parameters and name of another component, please change the name of the component' ] ] ] ].
	^ nil
]

{ #category : #accessing }
MolHomeServices >> deployedComponents [
	^ deployedComponents
]

{ #category : #'initialize-release' }
MolHomeServices >> initialize [
	super initialize.
	deployedComponents := Dictionary new.
	waitingForActivation := Set new.
]

{ #category : #accessing }
MolHomeServices >> instanceOf: aClass named: aName [
	^(self deployedComponents at: aClass ifAbsent: [^nil]) at: aName ifAbsent: [^nil]
]

{ #category : #'life cycle' }
MolHomeServices >> instanciateAllComponents [
	self deployedComponents keysDo: [ :aClass | self instanciateComponent: aClass ]
]

{ #category : #'life cycle' }
MolHomeServices >> instanciateComponent: aComponentClass [
	^ self instanciateComponent: aComponentClass named: #default
]

{ #category : #private }
MolHomeServices >> isDeployedComponent: aComponentClass [

	^ self deployedComponents includesKey: aComponentClass
]

{ #category : #testing }
MolHomeServices >> isWaitingForActivation: aComponentClass [
	^ self isWaitingForActivation: aComponentClass named: #default
]

{ #category : #testing }
MolHomeServices >> isWaitingForActivation: aComponentClass named: aComponentName [
	| component |

	component := self instanceOf: aComponentClass named: aComponentName.
	component isNil
		ifFalse: [^waitingForActivation includes: component]
		ifTrue: [^false]
]

{ #category : #'life cycle' }
MolHomeServices >> passivateAllComponents [
	self deployedComponents do: [ :aDictionary | 
		aDictionary keysAndValuesDo: [ :aName :aComponent | 
			(waitingForActivation includes: aComponent) ifFalse: [self passivateComponent: aComponent class named: aName]
		]
	]
]

{ #category : #'life cycle' }
MolHomeServices >> passivateComponent: aComponentClass [
	^ self passivateComponent: aComponentClass named: #default
]

{ #category : #'initialize-release' }
MolHomeServices >> release [
	self removeAllComponents.
	deployedComponents := nil.
	waitingForActivation := nil.
	super release.
]

{ #category : #'life cycle' }
MolHomeServices >> removeAllComponents [
	| components |
	components := self deployedComponents.
	components keysAndValuesDo: [ :key :values | 
		values copy do:[ :component | self removeComponent: key named: component componentName]
	]
]

{ #category : #'life cycle' }
MolHomeServices >> removeComponent: aComponentClass [
	^self removeComponent: aComponentClass named: #default
]

{ #category : #private }
MolHomeServices >> removeDeployedComponent: aComponentClass [
	"Remove a deployed component"
	self deployedComponents at: aComponentClass ifPresent:[ :compDict | 
		"Check if this component class have running instances"
		compDict isEmpty 
			ifTrue:[self deployedComponents removeKey: aComponentClass] 
			ifFalse:[
				"Remove existing components"
				compDict copy keysAndValuesDo: [ :k :v | self removeComponent: (v class) named: k ].
			].
	] ifAbsent:[ ^self ].
]

{ #category : #private }
MolHomeServices >> resetComponentConnection: aComponent withRemovedComponent: aRemovedComponent [
	"Unlink component connections with a removed component, this action reset component connexion in case of a new instance appears"
	| eventAndComponentNameAssocList eventsSubscribers |
	
	self flag:'PLA : test it'.
	(aComponent isNil or:[aRemovedComponent isNil]) ifTrue:[ ^ self ].
	eventsSubscribers := MolComponentManager default locatorServices eventsSubscribers.
	eventsSubscribers ifEmpty: [ ^ self ].
	
	eventAndComponentNameAssocList := aRemovedComponent class allProducedEvents collect: [ :event | 
		event -> aRemovedComponent componentName
	].

	eventAndComponentNameAssocList do: [ :eventAndComponentNameAssoc |
		
		eventsSubscribers keysAndValuesDo:[ :anEventInterface :eventSubscriber |
			
			(anEventInterface = eventAndComponentNameAssoc key) ifTrue:[ 
				
				eventSubscriber notNil ifTrue:[ | newObserversSet |
					
					eventSubscriber unlinkOriginator: aRemovedComponent.
					newObserversSet := eventSubscriber observersConnection at: aComponent ifAbsent:[ nil ].
					newObserversSet ifNotNil:[
						newObserversSet remove: aComponent componentName ifAbsent:[ nil ].
						eventSubscriber observersConnection at: aComponent put: newObserversSet.
					].
				]. 
			].	
		].
	].
]

{ #category : #accessing }
MolHomeServices >> waitingForActivation [
	^ waitingForActivation
]
