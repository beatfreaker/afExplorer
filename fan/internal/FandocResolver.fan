using afIoc
using afReflux
using gfx

internal class FandocResolver : UriResolver {
	
	@Inject private Registry	registry
	@Inject private Explorer	explorer

	new make(|This|in) { in(this) }	
	
	override Resource? resolve(Str str) {
		try {
			uri := str.toUri
			if (uri.scheme == "fandoc")
				return registry.autobuild(FandocResource#, null, [
					FandocResource#uri	: uri,
					FandocResource#name	: uri.name,
					FandocResource#icon	: Image(`fan://afExplorer/res/icons-file/fileFandoc.png`)
				])
		} catch { }
		
		return null
	}	
}


//	override Obj? get(Uri uri, Obj? base) {
//		
//		// we don't need canonicalize top level docs 
//		if (uri.host == null || uri.host.isEmpty)
//			return FandocResource(`fandoc://`, base)
//		
//		// to start off, ensure we have a full and complete uri
//		// expand 'fandoc://afFancom' to 'fandoc://afFancom/index' 
//		if (uri.basename.isEmpty) {
//			if (!uri.isDir)
//				uri = uri.plusSlash
//			uri = uri.plusName("index")
//		}
//
//		// canonicalize 'fandoc://afFancom/../sys/Obj' to 'fandoc://sys/Obj'
//		// it's a lot trickier than you'd think!
//		scheme	:= "fandoc"
//		type	:= uri.name
//		frag	:= uri.frag ?: ""
//		// working our way backwacks through the path, ignoring the first element, find the first
//		// element not equal to ".."
//		pod 	:= uri.path.rw.reverse.find |p, i| {
//			p != ".." && i >= 1
//		} ?: uri.host
//
//		if (!frag.isEmpty)
//			frag = "#$frag"
//		
//		// reassemble the uri
//		uri = `${scheme}://${pod}/${type}${frag}`
//		return FandocResource(uri, base)
//	}


//	** *Some people, when confronted with a problem, think "I know, I'll use regular expressions." Now they have two problems.*
//	** 
//	** > Jamie Zawinski (1997)
//	** 
//	** See `http://regex.info/blog/2006-09-15/247`
//	internal static Uri toUri(Str str) {
//		if (str == "/" || str == "//")
//			return `fandoc://`
//		
//		typeUri := toType(str, null)
//		if (typeUri != null)
//			return typeUri
//		
//		if (str.split('/').size == 2) {
//			podName  := str.split('/')[0]
//			typeName := str.split('/')[1]
//			typeUri   = toType(podName, typeName)
//			if (typeUri != null)
//				return typeUri
//		}
//
//		if (str.split(':').size == 3) {
//			podName  := str.split(':')[0]
//			typeName := str.split(':')[2]
//			typeUri   = toType(podName, typeName)
//			if (typeUri != null)
//				return typeUri
//		}
//		
//		// check if str is too small to have a scheme
//		if (str.size <= 3)
//			return str.toUri
//
//		if (str.chars[0].isAlpha && str.chars[1] == ':' && (str.chars[2] == '\\' || str.chars[2] == '/'))
//			str = File.os(str).normalize.toStr
//		return str.toUri
//	}
//	
//	** TODO: Move into FandocResource, so all uris benefit.
//	private static Uri? toType(Str podName, Str? typeName) {
//		// BugFix: Pod.list throws an Err if any pod is invalid (wrong dependencies etc) 
//		// this way we don't even load the pod into memory!
//		podNameQ := Env.cur().findAllPodNames.find { it.equalsIgnoreCase(podName) }
//		if (podNameQ == null)
//			return null
//		
//		if (typeName == null)
//			return `fandoc://${podNameQ}`
//
//		typeNameQ := Pod.find(podNameQ).types.find { it.name.equalsIgnoreCase(typeName) }
//		if (typeNameQ == null)
//			return null
//		
//		return `fandoc://${podNameQ}/${typeNameQ.name}`
//	}
	