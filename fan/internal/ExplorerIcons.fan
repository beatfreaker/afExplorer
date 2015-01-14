using afIoc

internal class ExplorerIcons {
	static const Str:Uri iconMap := [

		// ---- File Explorer -------------------
		"icoFoldersPanel"		: `filenav_nav.gif`,
		"icoFolderView"			: `fldr_obj.gif`,
		"icoImageView"			: `image_obj.gif`,
		"icoTextEditorView"		: `file_obj.gif`,
		
		"cmdOpenFile"			: ``,
		"cmdActionFile"			: ``,
		"cmdRenameFile"			: ``,
		"cmdDeleteFile"			: `delete_obj.gif`,
		"cmdCutFile"			: `cut_edit.gif`,
		"cmdCopyFile"			: `copy_edit.gif`,
		"cmdPasteFile"			: `paste_edit.gif`,
		"cmdNewFile"			: `new_untitled_text_file.gif`,
		"cmdNewFolder"			: `newfolder_wiz.gif`,
		"cmdCopyFileName"		: ``,
		"cmdCopyFilePath"		: ``,
		"cmdCopyFileUri"		: ``,

		"icoFile"				: `file_obj.gif`,
		"icoFileImage"			: `image_obj.gif`,
		"icoFolder"				: `fldr_obj.gif`,
		"icoFolderRoot"			: `prj_obj.gif`,
		
		// ---- Image View ----------------------
		"icoImageNotFound"		: `delete_obj.gif`,
		"cmdImageFitToWindow"	: `collapseall.gif`,
		"cmdImageFullSize"		: `image_obj.gif`,

		
		// ---- Html View -----------------------
		"icoHtmlView"			: `fan://afReflux/res/icons-file/fileTextHtml.png`
	]
}
