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
        $.tablesorter.addParser({
          id: "customDate",
          is: function(s) {
            //return false;
            //use the above line if you don't want table sorter to auto detected this parser
            //else use the below line.
            //attention: doesn't check for invalid stuff
            //2009-77-77 77:77:77.0 would also be matched
            //if that doesn't suit you alter the regex to be more restrictive
            return /\d{1,2}\/\d{1,2}\/\d{1,2} \d{1,2}:\d{1,2}/.test(s);
          },
          format: function(s) {
            s = s.replace(/\-/g," ");
            s = s.replace(/:/g," ");
            s = s.replace(/\./g," ");
            s = s.split(" ");
            return $.tablesorter.formatFloat(new Date(s[2], s[1]-1, s[0], s[3], s[4]).getTime());
          },
          type: "numeric"} );

        $("#vpn-connections").tablesorter({
          headers: {
            3: { sorter: 'customDate' },
            4: { sorter: 'customDate' },
          }
        });
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
