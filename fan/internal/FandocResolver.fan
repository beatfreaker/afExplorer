using afIoc
using afReflux
using gfx

internal class FandocResolver : UriResolver {
	private static const Str 	root	:= "fandoc:/" 
	
	@Inject private Registry	registry
	@Inject private Explorer	explorer
			private Str[]		podNames

	new make(|This|in) {
		in(this)
		// BugFix: Pod.list throws an Err if any pod is invalid (wrong dependencies etc) 
		// this way we don't even load the pod into memory!
		podNames = Env.cur().findAllPodNames
	}	
	
	override Resource? resolve(Str str) {
		try {
			try {
				uri := str.toUri
				if (uri.scheme == "fandoc")
					return fandocResource(uri)
			} catch { }
			
			try {
				uri := fromFandocStr(str)
				if (uri != null)
					return fandocResource(uri)
			} catch { }
		} catch { }
		
		return null
	}	

	private Resource fandocResource(Uri fandocUri) {
		uri := normalise(fandocUri)
		// the URI / resource may or may not exist
		return registry.autobuild(FandocResource#, null, [
			FandocResource#uri	: uri,
			FandocResource#name	: uri.name,
			FandocResource#icon	: Image(`fan://afExplorer/res/icons-file/fileFandoc.png`)
		])		
	}

	Uri normalise(Uri uri) {
		// expand 'fandoc:/afFancom' to 'fandoc:/afFancom/index' 
		if (uri.path.size == 1)
			uri = uri.plusSlash.plusName("index")
		
		// ensure uri is absolute, `fandoc:afFancom` to `fandoc:/afFancom`
		if (!uri.isPathAbs)
			uri = root.toUri + uri.pathOnly

		return uri
	}


	** *Some people, when confronted with a problem, think "I know, I'll use regular expressions." Now they have two problems.*
	** 
	** > Jamie Zawinski (1997)
	** 
	** See `http://regex.info/blog/2006-09-15/247`
	private Uri? fromFandocStr(Str str) {
		
		// is it just a pod name? e.g. afExplorer
		typeUri := toType(str, null)
		if (typeUri != null)
			return typeUri

		// is it in Fandoc form? e.g. afExploer::Explorer
		if (str.contains("::") && str.split(':').size == 3) {
			// FIXME: use # and . for chapter / slot names
			podName  := str.split(':')[0]
			typeName := str.split(':')[2]
			typeUri   = toType(podName, typeName)
			if (typeUri != null)
				return typeUri
		}
		
		return null
	}
	
	private Uri? toType(Str podName, Str? typeName) {
		podNameQ := podNames.find { it.equalsIgnoreCase(podName) }
		if (podNameQ == null)
			return null
		
		if (typeName == null)
			return `${root}${podNameQ}`

		typeNameQ := Pod.find(podNameQ).types.find { it.name.equalsIgnoreCase(typeName) }
		if (typeNameQ == null)
			return null
		
		return `${root}${podNameQ}/${typeNameQ.name}`
	}
}
