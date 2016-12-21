({
	selectFile: function(component){
		component.set('v.result','');
	},
	upload : function(component, event, helper) {
		console.log('Getting a pre signed url for uploading file...');

		// file detail
		var fileInput = component.find("file").getElement();
    	var file = fileInput.files[0];

    	// get a pre signed download URL first 
		var action = component.get("c.getUploadUrl");
		action.setParams({
            fileName: file.name
        });

        action.setCallback(this, function(response) {
        	console.log(response.getState());
        	var state = response.getState();
        	if (state === "SUCCESS") {
        		var url = response.getReturnValue();
        	
        		// upload file
				$.ajax({
				    type : 'PUT',
				    url : url,
				    data : file,
				    headers:{'x-amz-server-side-encryption':'AES256'},
				    processData: false,  // tell jQuery not to convert to form data
				    contentType: file.type,
				    success: function(json) { 
				    	console.log('Upload complete!');
				    	component.set('v.result', 'Upload complete!');
				    },
				    error: function (XMLHttpRequest, textStatus, errorThrown) {
				        console.log('Upload error: ' + XMLHttpRequest.responseText);
				        component.set('v.result', XMLHttpRequest.responseText);
				    }
				});
        	}else if (state === "ERROR") {
        		var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +  errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                    component.set('v.result', 'Unknown error');
                }
        	}
        });
        $A.enqueueAction(action);
	}
})