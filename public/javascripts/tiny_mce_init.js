var tinymce_options = {
  mode : "textareas",
  theme : "simple",
  editor_deselector : "mceNoEditor",
  width: "800",
  theme_advanced_disable : "bold,italic,underline,strikethrough,undo,redo,bullist,numlist,cleanup "
};

var tinymce_advanced_options = {
  mode : "textareas",
  theme : "advanced",
  editor_deselector : "mceNoEditor",
  skin : "o2k7",
  skin_variant : "black",
  theme_advanced_resizing_min_width : 500,
  theme_advanced_resizing_max_width : 800,
  plugins : "",

  width: "780",
  button_title_map: false,
  apply_source_formatting: true,
  theme_advanced_toolbar_align: "left",
  
  theme_advanced_buttons1: "bold,italic,underline,strikethrough,separator,undo,redo,separator,bullist,numlist,link",
  theme_advanced_buttons2: "",
  theme_advanced_buttons3: "",  

  theme_advanced_toolbar_location: "bottom",
  theme_advanced_resizing : true,
  theme_advanced_blockformats : "p,h2,h3,blockquote"
};

var tinymce_advanced_with_save_options = {
  mode : "textareas",
  theme : "advanced",  
  plugins: 'save,autoresize,paste,preview,safari,table,contextmenu,paste,imagepopup,emotions',
  editor_deselector : "mceNoEditor",
  theme_advanced_resizing_min_width : 500,
  theme_advanced_resizing_max_width : 800,
  height : "20",
   width: "800",
  button_title_map: false,
  apply_source_formatting: true,
  theme_advanced_toolbar_align: "left",
  theme_advanced_buttons1: "save,cancel,formatselect,outdent,indent,seperator,undo,redo,separator,emotions",
  theme_advanced_buttons2: "justifyleft,justifycenter,justifyright,separator,bold,italic,separator,bullist,numlist,link,separator,imagepopup,table,separator",
  theme_advanced_buttons3: "",
  save_enablewhendirty : true,

  forced_root_block : false,
    force_p_newlines : false,
    remove_linebreaks : false,
    force_br_newlines : true,
    remove_trailing_nbsp : false,
    verify_html : false,

  theme_advanced_toolbar_location: "bottom",
  theme_advanced_resizing : true,
  content_css : "/style/editable.css",
  theme_advanced_blockformats : "p,h2,h3,blockquote"
};
var tinymce_advanced_stripped_options = {
  mode : "textareas",
  theme : "advanced",
  editor_deselector : "mceNoEditor",
  plugins : "",
  height : "20",
  width: "430",
  button_title_map: false,
  apply_source_formatting: true,
  theme_advanced_toolbar_align: "left",
  theme_advanced_disable: "justifyleft,justifycenter,justifyright,justifyfull,outdent,indent,cut,copy,paste,undo,redo,link,unlink,image,cleanup,help,code,hr,removeformat,formatselect,fontselect,fontsizeselect,styleselect,sub,sup,forecolor,backcolor,forecolorpicker,backcolorpicker,charmap,visualaid,anchor,newdocument,blockquote,separator",
  theme_advanced_buttons1: "bold,italic,underline,strikethrough,bullist,numlist",
  theme_advanced_buttons2: "",
  theme_advanced_buttons3: "",
  forced_root_block : false,
    force_p_newlines : false,
    remove_linebreaks : false,
    force_br_newlines : true,
    remove_trailing_nbsp : false,
    verify_html : false,
  theme_advanced_toolbar_location: "bottom",
  content_css : "/style/editable.css",
  theme_advanced_blockformats : "p,h2,h3,blockquote"

};
tinyMCE.init(tinymce_advanced_options);
tinyMCE.init(tinymce_advanced_stripped_options);
tinyMCE.init(tinymce_advanced_with_save_options);
