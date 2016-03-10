$(document).ready(function(){
    $("#button1").click(function(){
        var d = $("#indate").val();
        var e = $("#inetime").val();
        var s = $("#instime").val();
        var l = $("#inlunch").val();
        
        date = d.split('-');                                                                                                               

        var redate = /[2][0]\d\d-([0][1-9]|[1][0-2])-([0][1-9]|[1-2][0-9]|[3][0-1])/; 
        var retime = /\d{2}:\d{2}/; 
        var m = true;
                                                                                                               
        if (!retime.test(e) || e.length != 5) {
            m = false;
            $("#inetime").css( "background-color", "red" );
        }else{
            $("#inetime").css( "background-color", "white" );
        }
        if (!retime.test(s) || s.length != 5) {
            m = false;
            $("#instime").css( "background-color", "red" );
        }else{
            $("#instime").css( "background-color", "white" );
        }
   
        if (!retime.test(l) || l.length != 5) {
            m = false;
            $("#inlunch").css( "background-color", "red" );
        }else{
            $("#inlunch").css( "background-color", "white" );
        }
        if (!redate.test(d) || d.length != 10) {
            m = false;
            $("#indate").css( "background-color", "red" );
        }else{
            $("#indate").css( "background-color", "white" );
        } 
        if (m){
            $.post("/inside.yaws",
            {
                year: date[0],
                month: date[1],
                day: date[2],
                date: d,
                start: s.replace(':',''),
                ending: e.replace(':',''),
                lunch: l.replace(':','')
            },location.reload());
        }
    });
    
    $(".delTine").click(function(){
        $.post("/inside.yaws/delete/" + $(this).closest('tr').attr('id'),
            {
                method: 'DELETE'
            });
    });
});
