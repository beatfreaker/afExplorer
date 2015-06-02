using afIoc

internal class ExplorerIcons {
	static const Str:Uri iconMap := [

		// ---- Global Commands -----------------
		"cmdFind"				: ``,
		"cmdFindPrev"			: `nav_backward.gif`,
		"cmdFindNext"			: `nav_forward.gif`,
		"cmdReplace"			: ``,
		"cmdGoto"				: ``,
		"cmdShowHiddenFiles"	: ``,

		"cmdEditPrefs"			: `thread_view.gif`,
		"cmdWordWrap"			: `word-wrap.gif`,
		"cmdFandocIndex"		: `fan://afExplorer/res/icons-file/fileFandoc.png`,

		// ---- File Explorer -------------------
		"icoFoldersPanel"		: `filenav_nav.gif`,
		"icoFolderView"			: `fldr_obj.gif`,

		"cmdOpenInNewTab"		: ``,

		"cmdOpenInSystem"		: ``,
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
		"cmdCopyOSPath"			: ``,
		"cmdCopyURI"			: ``,
		"cmdEditText"			: `fan://afExplorer/res/icons-file/fileText.png`,
		"cmdCompressToZip"		: `fan://afExplorer/res/icons-file/fileZip.png`,

		"icoFile"				: `file_obj.gif`,
		"icoFileImage"			: `image_obj.gif`,
		"icoFolder"				: `fldr_obj.gif`,
		"icoFolderRoot"			: `prj_obj.gif`,
		
		// ---- Image Viewer --------------------
		"icoImageViewer"		: `image_obj.gif`,
		"icoImageNotFound"		: `delete_obj.gif`,
		"cmdImageFitToWindow"	: `collapseall.gif`,
		"cmdImageFullSize"		: `image_obj.gif`,
		
		// ---- Html Viewer ---------------------
		"icoHtmlViewer"			: `fan://afExplorer/res/icons-file/fileTextHtml.png`,

		// ---- Text Editor ---------------------
		"icoTextEditor"			: `file_obj.gif`,

		// ---- Fandoc Viewer -------------------
		"icoFandocViewer"		: `fan://afExplorer/res/icons-file/fileFan.png`,

	]
}
