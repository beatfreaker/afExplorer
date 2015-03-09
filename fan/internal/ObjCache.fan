using afIoc

internal class ObjCache {
	@Inject	private Registry 	registry
			private Type[] 		serviceTypeCache
			private Type:Obj	constTypeCache		:= Type:Obj[:]
			private Type[]		autobuildTypeCache	:= Type[,]

	new make(|This|in) {
		in(this) 
		this.serviceTypeCache = registry.serviceDefinitions.vals.map { it.serviceType }
	}

	@Operator
	Obj? get(Type? type) {
		if (type == null)
			return null
		
		obj := null
		if (serviceTypeCache.contains(type))
			obj = registry.dependencyByType(type)

		if (constTypeCache.containsKey(type))
			obj = constTypeCache[type]
		
		if (autobuildTypeCache.contains(type))
			obj = registry.autobuild(type)
		
		if (obj == null) {
			if (type.isConst) {
				obj = registry.autobuild(type)
				constTypeCache.set(type, obj)
				
			} else {
				autobuildTypeCache.add(type)
				obj = registry.autobuild(type)
			}
		}

		return obj
	}
}
