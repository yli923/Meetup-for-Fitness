$(document).ready(function(){
  my_activity_trigger();
});
function getQueryVariable(variable)
{
       var query = window.location.search.substring(1);
       var vars = query.split("&");
       for (var i=0;i<vars.length;i++) {
               var pair = vars[i].split("=");
               if(pair[0] == variable){return pair[1];}
       }
       return(false);
}
function my_activity_trigger()
{
    var userId = getQueryVariable("userId");
    console.log( 'test' );
    console.log( userId );
     $.ajax({
                "dataType" : "json",
                "async": true,
                "crossDomain": true,
                "url": ,
                "method": "POST",

                "success" : function(data){
                    //拿到数据
                    console.log(data);
                }
            });
}