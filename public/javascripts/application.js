jQuery.noConflict();
var $j = jQuery;
$j(function(){  // $(document).ready shorthand
   $j('#flash-notice').fadeOut(5000);
    // Tabs
   $j('#tabs').tabs();
   $j('input[name=sticky_check_box]').attr('checked', false);
});
function clearElements(el){
    var object = new Array();
    object[0] = document.getElementById(el).getElementsByTagName('input');
    object[1] = document.getElementById(el).getElementsByTagName('textarea');
    object[2] = document.getElementById(el).getElementsByTagName('select');
    var type = null;
    for (var x=0; x<object.length; x++){
      for (var y=0; y<object[x].length; y++){
        type = object[x][y].type
        switch(type){
          case "text":
          case "textarea":
            object[x][y].value = "";
            break;
          break;
        }
      }
    }
  }