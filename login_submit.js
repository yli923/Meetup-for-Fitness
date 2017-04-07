function login_submit() {
	var formdata = {
		"username": $('#login-username').val(),
		"password": $('#login-password').val()
	}
	console.log(formdata);
	$.ajax({
  		"dataType" : "json",
  		"data": JSON.stringify(formdata),
  		"async" : true,
  		"crossDomain": true,
  		"url": "http://@ec2-52-7-74-13.compute-1.amazonaws.com/auth/login",
  		"method": 'POST',
  		"headers": {
    		"content-type": "application/json",
  		},
 
		success: function(result) {
			console.log(result);
			if(!result.userID){
				return 0;
			} else {
				return result.userID;
			}
			//var json = jQuery.parseJSON(result);

		},
		error: function(xhr, txtstatus, errorthrown) {
			console.log(xhr);
			console.log(txtstatus);
			//console.log("\n{\n\t\"username\":\"demo\",\n\t\"password\":\"123\"\n}");
		}
	});
	return false;


}