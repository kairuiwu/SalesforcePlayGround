/*------------------------------------------------------------
Author:         Kevin Wu
Company:        Kevin Wu
Description:    Service class for AWS S3
Test Class:
History
<Date>      <Authors Name>      <Brief Description of Change>
21-Dec-16   Kevin Wu            Created
------------------------------------------------------------*/
public with sharing class S3Service {

    private  static final String AWS_HEADER_ENCRYPTION_SCHEME    = 'AWS4-HMAC-SHA256';
    private  static final String AWS_ENCRYPTION_SCHEME           = 'SHA-256';
    private  static final String S3_TIMEOUT                      = '86400';
	private  String              awsRegion                       {get; set;}
    private  String              awsHost                         {get; set;}
    private  String              awsRequestType                  {get; set;}
    private  String              awsServiceName                  {get; set;}
    private  String              bucketName                      {get; set;}
    private  String              httpVerb                        {get; set;}
    private  String              canonicalUri                    {get; set;}
    private  String              expiresSeconds                  {get; set;}
    private  String              accessKey                       {get; set;}
    private  String              accessSecret                    {get; set;}
    private  String              xAmzSignedHeadersValue          {get; set;}
    private  Date                dateStamp                       {get; set;}
    private  Map<String, String> additionalCanonicalHeaders      {get; set;}
    private  Map<string, String> canonicalHeaders                {get; set;}
    private  List<String>        signedHeaders                   {get; set;}
    

	private  Map<String, String> canonicalQueryMap   {
        get {
            if (canonicalQueryMap != null) {
                return canonicalQueryMap;
            } else {
                // provide defaults if not manually set.
                // Map out the canonical query string elements
                Map<String, String> queryParams = new Map<String, String>();
                queryParams.put('X-Amz-Algorithm'       , AWS_HEADER_ENCRYPTION_SCHEME);
                queryParams.put('X-Amz-Credential'      , this.accessKey + '/' + this.dateStampYYYYMMDD + '/' + this.awsRegion + '/s3/aws4_request');
                queryParams.put('X-Amz-Date'            , this.dateStampISO); // convert to ISO 8601 format
                queryParams.put('X-Amz-Expires'         , this.expiresSeconds);
                queryParams.put('X-Amz-SignedHeaders'   , xAmzSignedHeadersValue == null ? 'host' : xAmzSignedHeadersValue);
        
                return queryParams;
            }
        }
        set;
    }


    /*------------------------------------------------------------
    Author:         Kevin Wu
    Company:        Kevin Wu
    Description:    Constructor 
    Inputs:         httpMethod: method of the http request
                    s3Config: details and parameters of the http request
    History
    <Date>      <Authors Name>      <Brief Description of Change>
    21-Dec-16   Kevin Wu            Created
    ------------------------------------------------------------*/
    public S3Service(String httpMethod, Map<String,String> s3Config) {
        this.accessKey 		= s3Config.get('ACCESS_KEY');
        this.accessSecret 	= s3Config.get('ACCESS_SECRET');
        this.bucketName 	= s3Config.get('BUCKET_NAME');
        this.awsServiceName = s3Config.get('SERVICE_NAME');
        this.awsHost 		= s3Config.get('HOST');
        this.awsRegion 		= s3Config.get('REGION');
        this.expiresSeconds = s3Config.get('X-Amz-Expires') != null ? s3Config.get('X-Amz-Expires') : S3_TIMEOUT;
        this.httpVerb       = httpMethod;

        if(httpMethod == 'PUT' && s3Config.containsKey('X-Amz-SignedHeaders')){   
            this.xAmzSignedHeadersValue = s3Config.get('X-Amz-SignedHeaders');
        }

        // Map out the canonical header elements
        this.canonicalHeaders = new Map<string,string>();
        this.canonicalHeaders.put('host', this.awsHost);

        // List out the signed headers
        this.signedHeaders = new List<string>();
        this.signedHeaders.add('host');
        if(httpMethod == 'PUT' && s3Config.containsKey('X-Amz-Server-Side-Encryption')){
            this.signedHeaders.add('X-Amz-Server-Side-Encryption');  
            this.canonicalHeaders.put('X-Amz-Server-Side-Encryption',s3Config.get('X-Amz-Server-Side-Encryption'));
        }

        this.additionalCanonicalHeaders = new Map <String, String>();
    }

    /*------------------------------------------------------------
    Author:         Kevin Wu
    Company:        Kevin Wu
    Description:    Get a signed URL  
    History
    <Date>      <Authors Name>      <Brief Description of Change>
    21-Dec-16   Kevin Wu            Created
    ------------------------------------------------------------*/
    public String getSignedUrl() {
        string url = 'https://' + this.awsHost + '/' + bucketName + '/' + canonicalUri + '?';

        for (string key: this.canonicalQueryMap.keySet()) {
            url += key + '=' + this.canonicalQueryMap.get(key) + '&';
        }

        for (string key: this.additionalCanonicalHeaders.keySet()) {
            url += key + '=' + this.additionalCanonicalHeaders.get(key) + '&';
        }

        url += 'X-Amz-Signature=' + this.getSignature();
        return url;
    }

    /*------------------------------------------------------------
    Author:         Kevin Wu
    Company:        Kevin Wu
    Description:    Set the canonicalUri String  
    Input:          canonicalUri: uri string
    History
    <Date>      <Authors Name>      <Brief Description of Change>
    21-Dec-16   Kevin Wu            Created
    ------------------------------------------------------------*/
    public void setCanonicalUri(String canonicalUri){
        this.canonicalUri = canonicalUri;
    }

    /*
     *	Construct the string to sign
     */
    private String getStringToSign() {
        String stringToSign = AWS_HEADER_ENCRYPTION_SCHEME + '\n'
                            + this.dateStampISO + '\n'
                            + this.dateStampYYYYMMDD + '/' + this.awsRegion + '/s3/aws4_request' + '\n'
                            + EncodingUtil.convertToHex(Crypto.generateDigest(AWS_ENCRYPTION_SCHEME, blob.valueOf(this.getRequestString())));
        return stringToSign;
    }

    /*
     *	Generate the signature
     */
    private String getSignature() {
        return this.generateSignature(this.getStringToSign(), this.getSigningKey());
    }

    /*
     *	Generate the signing key
     */
    private Blob getSigningKey() {
        Blob dateKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.dateStampYYYYMMDD), Blob.valueOf('AWS4' + this.accessSecret));
        Blob dateRegionKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.awsRegion), dateKey);
        Blob dateRegionServiceKey = Crypto.generateMac('hmacSHA256', blob.valueOf(this.awsServiceName), dateRegionKey);
        Blob signingKey = Crypto.generateMac('hmacSHA256', blob.valueOf('aws4_request'), dateRegionServiceKey);
        return signingKey;
    }

    private String generateSignature(string stringToSign, blob signingKey) {
        blob signatureBlob = Crypto.generateMac('hmacSHA256', blob.valueOf(stringToSign), signingKey);
        return EncodingUtil.convertToHex(signatureBlob);
    }

    
    /*
     *	Construct the request string from the data
     */
    private String getRequestString() {
        // Now construct the canonical request string from these elements.
        String canonicalRequestString = this.httpVerb + '\n'
            + '/' + bucketName + '/' + this.canonicalUri + '\n';

        // Add the query string
        // we assume the elements remain in alphabetical order. 
        for (String key : this.canonicalQueryMap.keySet()) {
            canonicalRequestString += awsUriEncode(key) + '=' + awsUriEncode(this.canonicalQueryMap.get(key)) + '&';
        }

        for (String key : this.additionalCanonicalHeaders.keySet()) {
            canonicalRequestString += awsUriEncode(key) + '=' + awsUriEncode(this.additionalCanonicalHeaders.get(key)) + '&';
        }

        // replace the last & with a \n
        canonicalRequestString = canonicalRequestString.left(canonicalRequestString.length() - 1) + '\n';

        // Add the canonical headers with a linefeed at the end of each
        for (String key : this.canonicalHeaders.keySet()) {
            if(this.canonicalHeaders.get(key) != null) {
                canonicalRequestString += key.toLowerCase() + ':' + this.canonicalHeaders.get(key).trim() + '\n';
            }
        }

        // add an additional linefeed
        canonicalRequestString += '\n';


        // Add signed headers
        // we assume the elements remain in alphabetical order.
        Integer keyNum = 0;
        for (String key : this.signedHeaders) {
            keyNum ++;
            if(keyNum > 1) {
                canonicalRequestString += ';';
            }
            canonicalRequestString += key.toLowerCase();
        }

        // add an additional linefeed
        canonicalRequestString += '\n';


        // Add the final line which specifies that we aren't sure of the file size.
        canonicalRequestString += 'UNSIGNED-PAYLOAD';

        return canonicalRequestString;
    }

    /*
     *	Encode the string
     */
    public static String awsUriEncode (String str) {
        str = str == null ? 'null' : str;
        return EncodingUtil.urlEncode(str, 'UTF-8');
    }

    /**
     * Returns the dateStamp in the ISO format
     */
    public String dateStampISO {
        get {
            if (this.dateStamp == null) {
                String gmtHour      = String.valueOf(System.now().hourGmt());
                String gmtMinute    = String.valueOf(System.now().minuteGmt());
                String gmtSecond    = String.valueOf(System.now().secondGmt());
                
                if(gmtHour.length()==1){ gmtHour = '0' + gmtHour; }
                if(gmtMinute.length()==1){ gmtMinute = '0' + gmtMinute; }
                if(gmtSecond.length()==1){ gmtSecond = '0' + gmtSecond; }
                
                // add GMT ThhmmssZ
                return dateStampYYYYMMDD + 'T' + gmtHour + gmtMinute + gmtSecond + 'Z';
            }else{
                return dateStampYYYYMMDD + 'T000000Z';
            } 
        }
    }

     /**
     * Returns the dateStamp in the format YYYYMMDD
     * If dateStamp is not available, defaults to current day
     */
    public String dateStampYYYYMMDD {
        get {
            Date dateToday;
            if (this.dateStamp == null) {
                // Current date (GMT)
                Datetime datetimeToday = System.now();
                dateToday = date.newinstance(datetimeToday.yearGmt(), datetimeToday.monthGmt(), datetimeToday.dayGmt());
            } else {
                dateToday = this.dateStamp;
            }

            // Calculate today as yyyymmdd
            String sMonth = String.valueof(dateToday.month());
            String sDay = String.valueof(dateToday.day());
            if(sMonth.length()==1){ sMonth = '0' + sMonth; }
            if(sDay.length()==1){ sDay = '0' + sDay;}
            String sToday = String.valueof(dateToday.year()) + sMonth + sDay ;

            return sToday;
        }
    }
}