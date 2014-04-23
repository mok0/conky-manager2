/*
 * EditWindow.vala
 * 
 * Copyright 2012 Tony George <teejee2008@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */
 
using Gtk;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public class SettingsWindow : Dialog {
	
	private Notebook notebook;
	private Switch switch_startup;
	private Switch switch_capture_bg;
	private FileChooserButton fcb_theme_dir;
	private Button btn_install_theme_pack;
	private Button btn_add_folder;
	private Button btn_remove_folder;
	private Button btn_apply_changes;
	private Button btn_cancel_changes;
	private TreeView tv_folders;
	private Gee.ArrayList<string> folder_list_user;
	
	public SettingsWindow() {
		title = "Application Settings";
        window_position = WindowPosition.CENTER_ON_PARENT;
		set_destroy_with_parent (true);
		set_modal (true);
        skip_taskbar_hint = false;
        set_default_size (400, 20);	
		icon = App.get_app_icon(16);
		
	    folder_list_user = new Gee.ArrayList<string>();
	    foreach(string path in App.search_folders){
			folder_list_user.add(path);
		}
		
	    Box vbox_main = get_content_area();

        //notebook
        notebook = new Notebook ();
		notebook.margin = 6;
		notebook.expand = true;
		notebook.set_size_request(-1,400);
		vbox_main.add(notebook);
		
		//options -----------------------------------------------------
		
		//vbox_options
        Box vbox_options = new Box (Orientation.VERTICAL, 6);
		vbox_options.margin = 6;

        //lbl_options
		Label lbl_options = new Gtk.Label(_("General"));

		notebook.append_page (vbox_options, lbl_options);

        //lbl_header_theme_dir
		Label lbl_header_theme_dir = new Gtk.Label("<b>" + _("Theme Directory") + "</b>");
		lbl_header_theme_dir.set_use_markup(true);
		lbl_header_theme_dir.xalign = (float) 0.0;
		lbl_header_theme_dir.margin_bottom = 6;
		vbox_options.add(lbl_header_theme_dir);
		
		// fcb_theme_dir
		fcb_theme_dir = new FileChooserButton (_("Theme Directory"), FileChooserAction.SELECT_FOLDER);
		fcb_theme_dir.margin_bottom = 6;
		fcb_theme_dir.margin_left = 6;
		fcb_theme_dir.create_folders = true;
		if ((App.data_dir.length > 0) && dir_exists (App.data_dir)){
			fcb_theme_dir.set_filename (App.data_dir);
		}
		vbox_options.add (fcb_theme_dir);

        //lbl_header_options
		Label lbl_header_options = new Gtk.Label("<b>" + _("Options") + "</b>");
		lbl_header_options.set_use_markup(true);
		lbl_header_options.xalign = (float) 0.0;
		lbl_header_options.margin_bottom = 6;
		vbox_options.add(lbl_header_options);

        //hbox_startup --------------------------------------------------
        
        Box hbox_startup = new Box (Gtk.Orientation.HORIZONTAL, 6);
        vbox_options.add (hbox_startup);
        
        //lbl_startup
		Label lbl_startup = new Gtk.Label(_("Run Conky at system startup") );
		lbl_startup.set_use_markup(true);
		lbl_startup.hexpand = true;
		lbl_startup.xalign = (float) 0.0;
		lbl_startup.valign = Align.CENTER;
		hbox_startup.add(lbl_startup);
		
		//switch_startup
        switch_startup = new Gtk.Switch();
        switch_startup.set_size_request(100,20);
        switch_startup.active =  App.check_startup();
        hbox_startup.pack_end(switch_startup,false,false,0);

        //hbox_capture_bg --------------------------------------------------
        
        Box hbox_capture_bg = new Box (Gtk.Orientation.HORIZONTAL, 6);
        vbox_options.add (hbox_capture_bg);
        
        //lbl_capture_bg
		Label lbl_capture_bg = new Gtk.Label(_("Preview Generation: Capture Background") );
		lbl_capture_bg.hexpand = true;
		lbl_capture_bg.xalign = (float) 0.0;
		lbl_capture_bg.valign = Align.CENTER;
		lbl_capture_bg.set_tooltip_text(_("When enabled, the generated preview images will have the same background as the desktop wallpaper. Otherwise the background will be a solid color (the widget's background color)."));
		hbox_capture_bg.add(lbl_capture_bg);
		
		//switch_capture_bg
        switch_capture_bg = new Gtk.Switch();
        switch_capture_bg.set_size_request(100,20);
        switch_capture_bg.active =  App.capture_background;
        hbox_capture_bg.pack_end(switch_capture_bg,false,false,0);
        
        //hbox_import_themepack  --------------------------------------------------
        
        Box hbox_import_themepack = new Box (Gtk.Orientation.HORIZONTAL, 6);
        vbox_options.add (hbox_import_themepack);
        
		//lbl_theme_pack
		Label lbl_theme_pack = new Gtk.Label(_("Import Theme Pack (*.cmtp.7z)"));
		lbl_theme_pack.xalign = (float) 0.0;
		hbox_import_themepack.add(lbl_theme_pack);

		//btn_install_theme_pack
		btn_install_theme_pack = new Button.with_label("   " + _("Import") + "   ");
        btn_install_theme_pack.clicked.connect (btn_install_theme_pack_clicked);
        btn_install_theme_pack.set_size_request(100,20);
		hbox_import_themepack.pack_end(btn_install_theme_pack,false,false,0);

		//vbox_folders -----------------------------------------------
		
		//vbox_folders
        Box vbox_folders = new Box (Orientation.VERTICAL, 6);
		vbox_folders.margin = 6;

        //lbl_folders
		Label lbl_folders = new Gtk.Label(_("Search Folders"));

		notebook.append_page (vbox_folders, lbl_folders);
		
		//tv_folders -----------------------------------------------
		
        //lbl_search_folders
		Label lbl_search_folders = new Gtk.Label(_("Additional locations to search for Conky themes"));
		lbl_search_folders.xalign = (float) 0.0;
		vbox_folders.add(lbl_search_folders);
		
		//tv_folders
		tv_folders = new TreeView();
		tv_folders.get_selection().mode = SelectionMode.MULTIPLE;
		tv_folders.headers_visible = true;
		tv_folders.set_rules_hint (true);
		//tv_folders.row_activated.connect(tv_folders_row_activated);
		
		//sw_folders
		ScrolledWindow sw_folders = new ScrolledWindow(null, null);
		sw_folders.set_shadow_type (ShadowType.ETCHED_IN);
		sw_folders.add (tv_folders);
		sw_folders.expand = true;
		vbox_folders.add(sw_folders);

        //col_path
		TreeViewColumn col_path = new TreeViewColumn();
		col_path.title = _("Location");
		col_path.expand = true;
		
		CellRendererText cell_margin = new CellRendererText ();
		cell_margin.text = "";
		col_path.pack_start (cell_margin, false);
		
		CellRendererPixbuf cell_icon = new CellRendererPixbuf ();
		cell_icon.stock_id = "gtk-directory";
		col_path.pack_start (cell_icon, false);
		
		CellRendererText cell_text = new CellRendererText ();
		col_path.pack_start (cell_text, false);
		col_path.set_cell_data_func (cell_text, (cell_layout, cell, model, iter) => {
			string path;
			model.get (iter, 0, out path, -1);
			(cell as Gtk.CellRendererText).text = path;
		});
		tv_folders.append_column(col_path);
		
		//hbox_folder_actions
        Box hbox_folder_actions = new Box (Orientation.HORIZONTAL, 6);
        vbox_folders.add(hbox_folder_actions);
        
		//btn_add_folder
		btn_add_folder = new Button.with_label("  " + _("Add"));
		btn_add_folder.set_image (new Image.from_stock ("gtk-add", IconSize.MENU));
        btn_add_folder.clicked.connect (btn_add_folder_clicked);
		hbox_folder_actions.add(btn_add_folder);

		//btn_remove_folder
		btn_remove_folder = new Button.with_label("  " + _("Remove"));
		btn_remove_folder.set_image (new Image.from_stock ("gtk-remove", IconSize.MENU));
        btn_remove_folder.clicked.connect (btn_remove_folder_clicked);
		hbox_folder_actions.add(btn_remove_folder);
		
		//hbox_commands --------------------------------------------------
		
		Box hbox_action = (Box) get_action_area();
		
		//btn_apply_changes
		btn_apply_changes = new Button.with_label("  " + _("OK"));
		btn_apply_changes.set_image (new Image.from_stock ("gtk-apply", IconSize.MENU));
        btn_apply_changes.clicked.connect (btn_apply_changes_clicked);
		hbox_action.add(btn_apply_changes);
		
		//btn_cancel_changes
		btn_cancel_changes = new Button.with_label("  " + _("Cancel"));
		btn_cancel_changes.set_image (new Image.from_stock ("gtk-cancel", IconSize.MENU));
        btn_cancel_changes.clicked.connect (btn_cancel_changes_clicked);
		hbox_action.add(btn_cancel_changes);
		
		tv_folders_refresh();
	}

	private void tv_folders_refresh(){
		ListStore model = new ListStore(1, typeof(string));
		TreeIter iter;
		foreach	(string path in folder_list_user){
			model.append(out iter);
			model.set (iter, 0, path);
		}
		tv_folders.set_model(model);
		tv_folders.columns_autosize();
	}
	
	private void btn_add_folder_clicked () {
		var list = browse_folder();
		
		if (list.length() > 0){
			foreach(string path in list){
				if (!folder_list_user.contains(path)){
					folder_list_user.add(path);
				}
			}
		}
		
		tv_folders_refresh();
	}

	private void btn_remove_folder_clicked () {
		TreeSelection sel = tv_folders.get_selection ();
		TreeIter iter;
		bool iterExists = tv_folders.model.get_iter_first (out iter);
		while (iterExists) { 
			if (sel.iter_is_selected (iter)){
				string path;
				tv_folders.model.get (iter, 0, out path);
				folder_list_user.remove(path);
			}
			iterExists = tv_folders.model.iter_next (ref iter);
		}
		tv_folders_refresh();
	}

	private SList<string> browse_folder(){
		var dialog = new Gtk.FileChooserDialog(_("Select directory"), this, Gtk.FileChooserAction.OPEN,
							"gtk-cancel", Gtk.ResponseType.CANCEL,
							"gtk-open", Gtk.ResponseType.ACCEPT);
		dialog.action = FileChooserAction.SELECT_FOLDER;
		dialog.local_only = true;
		dialog.set_transient_for(this);
 		dialog.set_modal (true);
 		dialog.set_select_multiple (false);
 		
		dialog.run();
		var list = dialog.get_filenames();
	 	dialog.destroy ();
	 	
	 	return list;
	}
	
	private void btn_apply_changes_clicked () {
		
		//theme directory
		string dir = fcb_theme_dir.get_filename ();
		if (!dir_exists(dir)){
			create_dir(dir);
		}
		if (dir_exists(dir)){
			App.data_dir = dir;
		}
		App.init_directories();
		//App.init_theme_packs();
		//App.load_themes();
		//load_themes();
		
		//options
		App.autostart(switch_startup.active);
		App.capture_background = switch_capture_bg.active;
		
		//search folders
		App.search_folders = folder_list_user;
		
		App.save_app_config();
		
		this.destroy();
	}

	private void btn_cancel_changes_clicked () {
		this.destroy();
	}

	private void btn_install_theme_pack_clicked (){
		var dlgAddFiles = new Gtk.FileChooserDialog(_("Import Theme Pack") + " (*.cmtp.7z)", this, Gtk.FileChooserAction.OPEN,
							"gtk-cancel", Gtk.ResponseType.CANCEL,
							"gtk-open", Gtk.ResponseType.ACCEPT);
		dlgAddFiles.local_only = true;
 		dlgAddFiles.set_modal (true);
 		dlgAddFiles.set_select_multiple (true);
 		
		Gtk.FileFilter filter = new Gtk.FileFilter ();
		dlgAddFiles.set_filter (filter);
		filter.add_pattern ("*.cmtp.7z");
		
		//show the dialog and get list of files
		
		SList<string> files = null;
 		if (dlgAddFiles.run() == Gtk.ResponseType.ACCEPT){
			files = dlgAddFiles.get_filenames();
	 	}

		//install theme packs
		
		gtk_set_busy(true, dlgAddFiles);

		int count = 0;
		if (files != null){
	 		foreach (string file in files){
				if (file.has_suffix(".cmtp.7z")){
					count += App.install_theme_pack(file);
				}
			}
		}
		
		//refresh theme list
		
	 	//App.load_themes();
	 	//load_themes();
	 	dlgAddFiles.destroy ();
	 	
	 	//show message
	 	
	 	if (files != null){
			gtk_messagebox(_("Themes Imported"), count.to_string() + " " + _("new themes were imported."),this);
		}
	}

}