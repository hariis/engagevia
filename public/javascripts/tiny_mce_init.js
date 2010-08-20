
var tinymce_advanced_options = {
  mode : "textareas",
  theme : "advanced",
  editor_deselector : "mceNoEditor",
  skin : "o2k7",
  skin_variant : "black",
  theme_advanced_resizing_min_width : 500,
  theme_advanced_resizing_max_width : 800,
  plugins : "autoresize,paste,safari,table,paste",

  width: "760",
  button_title_map: false,
  apply_source_formatting: true,
  theme_advanced_toolbar_align: "left",

  theme_advanced_buttons1: "formatselect,outdent,indent,seperator,undo,redo",
  theme_advanced_buttons2: "justifyleft,justifycenter,justifyright,separator,bold,italic,separator,bullist,numlist,link",
  theme_advanced_buttons3: "", //you have to have this to get an empty third row otherwise you get some elements 
  theme_advanced_toolbar_location: "bottom",
  theme_advanced_resizing : true,
  theme_advanced_blockformats : "p,h2,h3,blockquote"
};

tinyMCE.init(tinymce_advanced_options);