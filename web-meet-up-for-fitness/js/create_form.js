  $(document).ready(function() {
    document.getElementById ("submit_activity_id").addEventListener ("click", submit_new_activity, false);

    var select_id = document.getElementById("se-control");
    var option_fragment = document.createDocumentFragment();
    var userId = getQueryVariable("userId");
    var url_addr = "http://@ec2-52-7-74-13.compute-1.amazonaws.com/friends/" + userId;

    $.ajax({
        "dataType" : "json",
        "async": false,
        "crossDomain": true,
        "url": url_addr,
        "method": "GET",

        success : function(data){
            //拿到数据
            console.log(data);
            console.log(data["Friends List"].length);
            var friends_array = data["Friends List"];
            var friens_num = friends_array.length;

            for (var i = 0; i < friens_num; i++) {
                var option = document.createElement('option');
                option.value = i;
                option.appendChild(document.createTextNode( friends_array[i]['username']));
                option_fragment.appendChild(option);
            }
            select_id.appendChild(option_fragment);
        },
        error: function(xhr, txtstatus, errorthrown) {
             console.log(xhr);
             console.log(txtstatus);
        }
    });


    // for (var i = 1; i <= 30; i++) {
    //     var option = document.createElement('option');
    //     option.value = i;
    //     option.appendChild(document.createTextNode("option #" + i));
    //     df.appendChild(option);
    // }
    // elm.appendChild(df);

    $('#contact_form').bootstrapValidator({
        // To use feedback icons, ensure that you use Bootstrap v3.1.0 or later
        feedbackIcons: {
            valid: 'glyphicon glyphicon-ok',
            invalid: 'glyphicon glyphicon-remove',
            validating: 'glyphicon glyphicon-refresh'
        },
        fields: {
            first_name: {
                validators: {
                        stringLength: {
                        min: 2,
                    },
                        notEmpty: {
                        message: 'Please supply your first name'
                    }
                }
            },
             last_name: {
                validators: {
                     stringLength: {
                        min: 2,
                    },
                    notEmpty: {
                        message: 'Please supply your last name'
                    }
                }
            },
            activity_name: {
                validators: {
                    notEmpty: {
                        message: 'Please supply your activity name '
                    }
                }
            },
            sports: {
                validators: {
                    notEmpty: {
                        message: 'Please supply your sports type '
                    }
                }
            },
            people: {
                validators: {
                    notEmpty: {
                        message: 'Please supply your number of people you '
                    }
                }
            },
            phone: {
                validators: {
                    notEmpty: {
                        message: 'Please supply your phone number'
                    },
                    phone: {
                        country: 'US',
                        message: 'Please supply a vaild phone number with area code'
                    }
                }
            },
            address: {
                validators: {
                    notEmpty: {
                        message: 'Please supply your address'
                    }
                }
            },
            comment: {
                validators: {
                      stringLength: {
                        min: 10,
                        max: 200,
                        message:'Please enter at least 10 characters and no more than 200'
                    },
                    notEmpty: {
                        message: 'Please supply a description of your project'
                    }
                    }
                }
            }
        })
        .on('success.form.bv', function(e) {
            $('#success_message').slideDown({ opacity: "show" }, "slow") // Do something ...
                $('#contact_form').data('bootstrapValidator').resetForm();
            console.log('second');
            // Prevent form submission
            e.preventDefault();

            // Get the form instance
            var $form = $(e.target);

            // Get the BootstrapValidator instance
            var bv = $form.data('bootstrapValidator');


        });
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
function submit_new_activity() 
{
            var userId = getQueryVariable("userId");
            console.log( userId );

            var formData = {
                "aName": $('#activity_name_input').val(),
                "sportsType": $('#sports-type option:selected').val(),
                "aTime"   : $('#time-input').val(),
                "friendList"  : "69",
                "maxPeople": $('#maximum').val(),
                "teamId": "-1",
                "aInfo" : "fun game",
                "location" : $('#autocomplete').val()
            }    
            console.log( JSON.stringify(formData) );
     
     $.ajax({
                "data" : JSON.stringify(formData),
                "async": false,
                "crossDomain": true,
                "url": "http://@ec2-52-7-74-13.compute-1.amazonaws.com/activity/add/allInfo/" + userId,
                "method": "POST",
                "headers": {
                    "content-type": "application/json; charset=utf-8",
                },

                "processData": false,

                success : function(data){
                    console.log("success");
                    console.log(data);
                },

                error: function(jqxhr, textStatus, errorThrown){
                    console.log("error");
                    console.log(textStatus);
                    console.log(errorThrown);

                }
        });
    return false;

}

