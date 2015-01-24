using afIoc
using fwt

** (Service) -
** Populates the content menu / popup menu for folder resources.
mixin FolderPopupMenu {
	
	** Populates the given popup menu.
	abstract Menu populatePopup(Menu menu, FolderResource resource)
}

internal class FolderPopupMenuImpl : FolderPopupMenu {
	@Inject private Registry registry
	@Inject private ObjCache objCache
			private Method[] methods
	
	new make(Method[] methods, |This|in) {
		in(this)
		this.methods = methods
	}
	
	override Menu populatePopup(Menu menu, FolderResource resource) {
		methods.each |method| {
			target := objCache.get(method.parent) 
			method.callOn(target, [menu, resource])
		}
		return menu
	}
}
