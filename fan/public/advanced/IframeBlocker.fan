
** (Service) - 
@NoDoc // advanced
mixin IframeBlocker {
	
	abstract Bool block(Uri url)
}

internal class IframeBlockerImpl : IframeBlocker {
	private const Regex[] filters
	
	new make(Regex[] filters) {
		this.filters = filters
	}
	
	override Bool block(Uri url) {
		trimmed := url.toStr.trim
		return filters.any { it.matches(trimmed) }
	}	
}
