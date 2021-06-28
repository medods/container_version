    $(document).on("click", ".unaprooved",function(e){
        e.preventDefault();
        $.ajax({type: "POST",
                url: "/change_aproove_status",
                context: this,
                data: { id: $(this).data('id') },
                success:function(result){
                          console.log("Click unaprooved");
                          $(this).removeClass("unaprooved").addClass("aprooved");
        }});
      });

      $(document).on("click", ".aprooved",function(e){
          e.preventDefault();
        $.ajax({type: "POST",
                url: "/change_aproove_status",
                context: this,
                data: { id: $(this).data('id') },
                success:function(result){
                          console.log("Click aprooved");
                          $(this).removeClass("aprooved").addClass("unaprooved");

        }});
      });

      $(document).ready(function() { 
        console.log($("#vpn-connections"))
        $("#vpn-connections").tablesorter();
      }); 

      $(document).on("click", ".delete",function(e){
        if (confirm('Удалить сообщение?')) {
          $.ajax({type: "POST",
                  url: "/delete_msg",
                  context: this,
                  data: { id: $(this).data('id') },
                  success:function(result){
                            console.log("Click delete");
                            $(this).parents('tr').remove();
          }});
        };
      });
