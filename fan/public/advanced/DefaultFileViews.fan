
@NoDoc
const class DefaultFileViews {
	
	private const Str:Type extViews
	
	internal new make(Str:Type mappings) {
		extViews = mappings
	}
	
	@Operator
	Type? getView(Str? ext) {
		ext == null ? null : extViews[ext]
	}
}
