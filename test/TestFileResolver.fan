using afIoc

internal class TestFileResolver : Test {
	
	@Autobuild FileResolver? resolver
	
	Void testFandocUrl() {
		verifyNull(resolver.resolve("afIoc::Registry"))
	}
	
	
	Scope? scope
	
	override Void setup() {
		reg := RegistryBuilder().addModule(ExplorerModule#).addModulesFromPod("afExplorer").setOption("afReflux.appName", "wotever").build
		reg.activeScope.createChild("uiThread") { this.scope = it.jailBreak }
		scope.inject(this)
	}
	
	override Void teardown() {
		scope?.destroy
		scope?.registry?.shutdown
	}
	
	private Uri? resolveUri(Str uri) {
		resolver.resolve(uri)?.uri
	}
}
