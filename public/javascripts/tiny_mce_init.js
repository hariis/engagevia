var tinymce_options = {
  mode : "textareas",
  theme : "simple",
  editor_deselector : "mceNoEditor"
};

var tinymce_advanced_options = {
  mode : "textareas",
  theme : "advanced",
  editor_deselector : "mceNoEditor",
  theme_advanced_resizing_min_width : 500,
  theme_advanced_resizing_max_width : 800,
  plugins : "autoresize,paste,preview,safari,spellchecker,table,contextmenu,advimage,advlink,paste,fullscreen,imagepopup",

  width: "800",
  button_title_map: false,
  apply_source_formatting: true,
  theme_advanced_toolbar_align: "left",
  theme_advanced_buttons1: "formatselect,outdent,indent,seperator,undo,redo",
  theme_advanced_buttons2: "justifyleft,justifycenter,justifyright,separator,bold,italic,separator,bullist,numlist,link,separator,imagepopup,table,separator",
  theme_advanced_buttons3: "",
  theme_advanced_toolbar_location: "bottom",
  theme_advanced_resizing : true,
  content_css : "/style/editable.css",
  theme_advanced_blockformats : "p,h2,h3,blockquote"

};

var tinymce_advanced_with_save_options = {
  mode : "textareas",
  theme : "advanced",  
  plugins: 'save,autoresize,paste,preview,safari,spellchecker,table,contextmenu,advimage,advlink,paste,fullscreen,imagepopup',
  editor_deselector : "mceNoEditor",
  theme_advanced_resizing_min_width : 500,
  theme_advanced_resizing_max_width : 800,
   width: "800",
  button_title_map: false,
  apply_source_formatting: true,
  theme_advanced_toolbar_align: "left",
  theme_advanced_buttons1: "save,cancel,formatselect,outdent,indent,seperator,undo,redo",
  theme_advanced_buttons2: "justifyleft,justifycenter,justifyright,separator,bold,italic,separator,bullist,numlist,link,separator,imagepopup,table,separator",
  theme_advanced_buttons3: "",
  theme_advanced_toolbar_location: "bottom",
  theme_advanced_resizing : true,
  content_css : "/style/editable.css",
  theme_advanced_blockformats : "p,h2,h3,blockquote"
};

tinyMCE.init(tinymce_advanced_with_save_options);
