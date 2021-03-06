using afIoc
using afReflux
using gfx
using compilerDoc

internal class FandocResolver : UriResolver {
	private static const Str 	root	:= "fandoc:/" 
	
	@Inject private Scope		scope
	@Inject private Explorer	explorer
			private Str[]		podNames
			private DocEnv		silentDocEnv := SilentDocEnv()

	new make(|This|in) {
		in(this)
		// BugFix: Pod.list throws an Err if any pod is invalid (wrong dependencies etc) 
		// this way we don't even load the pod into memory!
		podNames = Env.cur().findAllPodNames
	}	
	
	override Resource? resolve(Str str) {
		try {
			uri := str.trim.toUri
			if (uri.scheme == "fandoc")
				return fandocResource(uri)
		} catch { }
		
		try {
			uri := fromFandocStr(str.trim)
			if (uri != null)
				return fandocResource(uri)
		} catch { }
		
		return null
	}	

	private Resource? fandocResource(Uri fandocUri) {
		uri := normalise(fandocUri)
		
		if (uri == null)
			return null
		
		return scope.build(FandocResource#, [uri])
	}

	// Yeah, I know all this is messy. It was cut'n'paste from FandocViewer, shoehorned in and messed with.
	// It needs a good tidy up. - But currently it works, the tests pass and I've got a girl to satisfy...
	Uri? normalise(Uri uri) {
		// expand 'fandoc:/afFancom' to 'fandoc:/afFancom/index' 
		if (uri.path.size == 1)
			uri = uri.plusSlash.plusName("index")
		
		// ensure uri is absolute, `fandoc:afFancom` to `fandoc:/afFancom`
		if (!uri.isPathAbs)
			uri = root.toUri + uri.pathOnly

		if (uri.path.size > 3)
			uri = root.toUri + uri.path[0..<3].join("/").toUri

		if (uri.path.isEmpty)
			return root.toUri

		// check case insensitive
		type := uri.path.getSafe(1)
		meth := uri.path.getSafe(2)
		u := toType(uri.path[0], type)
		
		if (u != null && meth != null)
			u = u.plusSlash.plusName(meth)
		
		return u
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
			
			slotName := (Str?) null
			if (typeName.contains(".")) {	
				slotName = typeName.split('.').getSafe(1)
				typeName = typeName.split('.')[0]
			}
			if (typeName.contains("#")) {	
				slotName = typeName.split('#').getSafe(1)
				typeName = typeName.split('#')[0]
			}
			
			typeUri   = toType(podName, typeName)
			if (typeUri != null) {
				if (slotName != null)
					typeUri = typeUri.plusSlash.plusName(slotName)
				return typeUri
			}
		}
		
		return null
	}
	
	private Uri? toType(Str podName, Str? typeName) {
		podNameQ := podNames.find { it.equalsIgnoreCase(podName) }
		if (podNameQ == null)
			return null
		
		if (typeName == null)
			return `${root}${podNameQ}`

		typeNameQ := Pod.find(podNameQ).types.find { it.name.equalsIgnoreCase(typeName) }?.name
		if (typeNameQ == null || typeName == "index") {
			// if no type, look for a pod doc or source file
			podFile := Env.cur.findPodFile(podNameQ)
			
			// See http://fantom.org/forum/topic/2489#c1
			// this line produces a lot of messy output that I can't control
			// compilerDoc::DocChapter.buildHeadingsTree() reports missing anchor IDs to
			// compilerDoc::DocPodLoader.err() which just dumps it to echo()
			docPod 	:= DocPod.load(silentDocEnv, podFile)
			doc 	:= docPod.doc(typeName, false)
			typeNameQ = doc?.docName				
			
			if (typeNameQ == null)
				return null
		}
		
		return `${root}${podNameQ}/${typeNameQ}`
	}
}

// Suppress msgs like: acme::releaseNotes.fandoc [Line 1]: Heading missing anchor id: v1.0.0
// see http://fantom.org/forum/topic/2489
const class SilentDocEnv : DocEnv {
	override DocSpace? space(Str name, Bool checked := true) { null }
	override DocErr errReport(DocErr err) { err }
}
