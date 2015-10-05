using afIoc

internal class TestFandocResolver : Test {
	
	override Void setup() {
		reg := RegistryBuilder().addModule(ExplorerModule#).addModulesFromPod("afExplorer").setOption("afReflux.appName", "wotever").build
		reg.rootScope.inject(this)
	}

	// From compilerDoc::DocLink
	//
	// The following link formats are built-in:
	//
	//    Format             Display     Links To
	//    ------             -------     --------
	//    pod::index         pod         absolute link to pod index
	//    pod::pod-doc       pod         absolute link to pod doc chapter
	//    pod::Type          Type        absolute link to type qname
	//    pod::Types.slot    Type.slot   absolute link to slot qname
	//    pod::Chapter       Chapter     absolute link to book chapter
	//    pod::Chapter#frag  Chapter     absolute link to book chapter anchor
	//    Type               Type        pod relative link to type
	//    Type.slot          Type.slot   pod relative link to slot
	//    slot               slot        type relative link to slot
	//    Chapter            Chapter     pod relative link to book chapter
	//    Chapter#frag       Chapter     pod relative link to chapter anchor
	//    #frag              heading     chapter relative link to anchor
	//
	// TODO: Should we support relative links?
	
	@Autobuild FandocResolver? resolver
	
	Void testCaseSensitiveBug() {
		verifyEq(resolveUri("fandoc:/afMongo/index"),		`fandoc:/afMongo/index`)
	}

	Void testResolvedUris() {
		// index URIs
		verifyEq(resolveUri("fandoc:"),						`fandoc:/`)
		verifyEq(resolveUri("fandoc:/"),					`fandoc:/`)

		// pod URIs
		verifyEq(resolveUri("fandoc:/afReflux"),			`fandoc:/afReflux/index`)
		verifyEq(resolveUri("fandoc:/afReflux/"),			`fandoc:/afReflux/index`)
		verifyEq(resolveUri("fandoc:/afReflux/index"),		`fandoc:/afReflux/index`)
		verifyEq(resolveUri("fandoc:/AFREFLUX"),			`fandoc:/afReflux/index`)

		// type URIs
		verifyEq(resolveUri("fandoc:/afReflux/View"),		`fandoc:/afReflux/View`)
		verifyEq(resolveUri("fandoc:/afReflux/View/"),		`fandoc:/afReflux/View`)
		verifyEq(resolveUri("FANDOC:/AFREFLUX/VIEW"),		`fandoc:/afReflux/View`)

		// slot URIs
		verifyEq(resolveUri("fandoc:/afReflux/View/save"),	`fandoc:/afReflux/View/save`)
		verifyEq(resolveUri("fandoc:/afReflux/View/save/"),	`fandoc:/afReflux/View/save`)
//		verifyEq(resolveUri("FANDOC:/AFREFLUX/VIEW/SAVE"),	`fandoc:/afReflux/View/save`)	// TODO: check slots
		
		// doc URIs
		verifyEq(resolveUri("fandoc:/afReflux/src-View.fan"),`fandoc:/afReflux/src-View.fan`)

		// non-existant
		verifyEq(resolveUri("afWotever"),					null)
		verifyEq(resolveUri("fandic:/afWotever"),			null)
		verifyEq(resolveUri("fandoc:/afWotever"),			null)
		verifyEq(resolveUri("fandoc:/afReflux/Wotever"),	null)		
//		verifyEq(resolveUri("fandoc:/afReflux/View/wot"),	null)	// TODO: check slots

		// FANDOC notation
		verifyEq(resolveUri("afReflux"),					`fandoc:/afReflux/index`)
		verifyEq(resolveUri("AFREFLUX"),					`fandoc:/afReflux/index`)
		verifyEq(resolveUri("afReflux::View"),				`fandoc:/afReflux/View`)
		verifyEq(resolveUri("AFREFLUX::VIEW"),				`fandoc:/afReflux/View`)
		verifyEq(resolveUri("afReflux::View.save"),			`fandoc:/afReflux/View/save`)
		verifyEq(resolveUri("afReflux::View#save"),			`fandoc:/afReflux/View/save`)
//		verifyEq(resolveUri("AFREFLUX::VIEW.SAVE"),			`fandoc:/afReflux/View/save`)	// TODO: check slots

		// FANDOC non-existant
		verifyEq(resolveUri("afWotever"),					null)
		verifyEq(resolveUri("afReflux::Wotever"),			null)
//		verifyEq(resolveUri("afReflux::View.wotever"),		null)	// TODO: check slots
	}
	
	Uri? resolveUri(Str uri) {
		resolver.resolve(uri)?.uri
	}
}
