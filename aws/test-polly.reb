rebol [
	file: %test-polly.reb
	author: "Graham Chiu"
	purpose: {
		tests an API call to polly

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

append lib compose [sts: (:sts)]
append lib compose [canreq: (:canreq)]

access: "..provided by amazon IAM ..."
secret: "..provided by IAM ..."

do %prot-http.reb

req: write https://polly.us-east-1.amazonaws.com/v1/voices?LanguageCode=en-AU compose/deep [
	GET [aws: "polly" datestamp: (form now/utc) region: "us-east-1" access: (access) secret: (secret) ]
]

probe load-json req
