rebol [
	file: %test-aws.reb
	notes: {
		need:

		get-amz-date 
    	Make-Authorization
    	unsplit


	}
]

do https://raw.githubusercontent.com/rgchris/Scripts/master/ren-c/altjson.reb
; hmac-sha256 is in a C crypt extension, and so needs to be imported into lib for use within modules
append lib compose [hmac-sha256: (:hmac-sha256)]

import/no-lib %aws-signing.reb

; we need to copy these to lib from the module so we can use them
append lib compose [get-amz-date: (:get-amz-date)]
append lib compose [Make-Authorization: (:Make-Authorization)]
append lib compose [unsplit: (:unsplit)]

import/no-lib %prot-http.reb



comment {
; the request
GET /?Param2=value2&Param1=value1 HTTP/1.1
Host:example.amazonaws.com
X-Amz-Date:20150830T123600Z

; canonical request
GET
/
Param1=value1&Param2=value2
host:example.amazonaws.com
x-amz-date:20150830T123600Z

host;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

; string to sign
AWS4-HMAC-SHA256
20150830T123600Z
20150830/us-east-1/service/aws4_request
816cd5b414d056048ba4f7c5386d6e0533120fb1fcfa93762cf0fc39e2cf19e0

; Authorization string
AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=b97d918cfa904a5beff61c982a1b6f458b799221646efd99d3219ec94cdf2500

; signed request
GET /?Param2=value2&Param1=value1 HTTP/1.1
Host:example.amazonaws.com
X-Amz-Date:20150830T123600Z
Authorization: AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=b97d918cfa904a5beff61c982a1b6f458b799221646efd99d3219ec94cdf2500
}

signed-req: {GET /?Param2=value2&Param1=value1 HTTP/1.0
Host:example.amazonaws.com
X-Amz-Date:20150830T123600Z
Authorization: AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=b97d918cfa904a5beff61c982a1b6f458b799221646efd99d3219ec94cdf2500

}

req: to string! make-http-request "GET" "/?Param2=value2&Param1=value1" [
	Host: "example.amazonaws.com"
	aws-debug: "service" datestamp: "30-Aug-2015/12:36:00" region: "us-east-1" 
	secret: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY" access: "AKIDEXAMPLE"
] ""

dump req

print unspaced ["Should get this" newline "{" signed-req "}"]
print ["And they're the same?" req = signed-req]
