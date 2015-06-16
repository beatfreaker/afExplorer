using afIoc

@NoDoc
mixin ExplorerEvents {

	virtual Void onShowHiddenFiles(Bool show)	{ }

	virtual Void onRename(File oldFile, File newFile) { }

	// add cut, copy, paste here...maybe
	
}
