/*------------------------------------------------------------
Author:         Kevin Wu
Company:        Kevin Wu
Description:    Controller for file download and upload
Test Class:
History
<Date>      <Authors Name>      <Brief Description of Change>
21-Dec-16   Kevin Wu       		Created
------------------------------------------------------------*/
public with sharing class FileController {
	
	/*------------------------------------------------------------
    Author:         Kevin Wu
    Company:        Kevin Wu
    Description:    Check the user's profile before deleting the post
    Inputs:         FileName: Name of the file
    Returns:        A signed url for download
    History
    <Date>      <Authors Name>      <Brief Description of Change>
    21-Dec-16   Kevin Wu       		Created
    ------------------------------------------------------------*/
	public static String getDownloadUrl(String fileName) {
		String httpMethod = 'GET';
		String awsSettingName = 'KevinWu32';
		Map<String,String> s3Config = new Map<String,String>();
		s3Config.put('ACCESS_KEY',					AWS_Setting__c.getInstance(awsSettingName).Access_Key_Id__c);
    	s3Config.put('ACCESS_SECRET',				AWS_Setting__c.getInstance(awsSettingName).Secret_Access_Key__c);
    	s3Config.put('BUCKET_NAME',					AWS_Setting__c.getInstance(awsSettingName).Bucket_Name__c);
    	s3Config.put('REGION',						AWS_Setting__c.getInstance(awsSettingName).Region__c);
    	s3Config.put('HOST',						AWS_Setting__c.getInstance(awsSettingName).Endpoint__c);
    	s3Config.put('SERVICE_NAME',				AWS_Setting__c.getInstance(awsSettingName).Service_Name__c);
    	s3Config.put('X-Amz-SignedHeaders',				'host;X-Amz-Server-Side-Encryption');
    	s3Config.put('X-Amz-Server-Side-Encryption',	'AES256');
    	s3Config.put('X-Amz-Expires',					'604800');


		S3Service s3 = new S3Service(httpMethod, s3Config);
		
		// urlEncode replaces whitespace with + instead of %20. + is invalid for AWS as it treats it as a character, so we need to substitute it after encoding
        s3.setCanonicalUri(EncodingUtil.urlEncode(handleFileNameSpecialChar(fileName), 'UTF-8').replace('+', '%20'));
        String signedUrl = s3.getSignedUrl();
		 
		return signedUrl;
	}

	private static String handleFileNameSpecialChar(String fileName){
		return fileName.replaceAll('[^a-zA-Z0-9.-]', '_');
	}
}