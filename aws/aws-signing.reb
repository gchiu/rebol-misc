rebol [
	file: %aws-signing.reb
 	type: module
    name: signing
    date: 17-Mar-2017
    version: 0.1.0
    exports: [ 
    	get-amz-date 
    	Make-Authorization
    	unsplit
    	canreq
    	sts
	]	
	notes: {
		needs a build later than https://github.com/metaeducation/ren-c/commit/3bd00a9 from 12-Mar-2017
		which includes the hmac-sha256 function
		documentation: https://github.com/gchiu/rebol-misc/wiki
	}
]

; do %hmac.reb

hmac-sha256: :lib/hmac-sha256
; stringtosign, and Canonical-Request
sts: canreq: _

url-encode: use [as-is space percent-encode][
    as-is: charset ["-." #"0" - #"9" #"A" - #"Z" #"-" #"a" - #"z" #"~"]
    percent-encode: func [text][
        insert next text enbase/base copy/part text 1 16 change text "%"
    ]

    func [
        "Encode text using percent-encoding for URLs and Web Forms"
        text [any-string!] "Text to encode"
        /aws "Use %20 to represent spaces"
    ][
        space: either aws ["%20"][#"+"]
        either parse text: to binary! text [
            copy text any [
                  text: some as-is | end | change " " space
                | [ #"."] (either aws [percent-encode text][text])
                | skip (percent-encode text)
            ]
        ][to string! text][""]
    ]
]

fract: function [
	{turns the fraction of a decimal into 0-99}
	d [decimal!]
][
	d: d + .001
	to integer! 100 * (d - to integer! d)
]

f10: function [n][
	next form 100 + n
]

Get-amz-date: function [
	{converts a UTC date to amz format}
	d [string!]
][
	d: to date! d
	return unspaced [
		d/year 
		f10 d/month 
		f10 d/day "T" 
		f10 d/4/1 					; hour
		f10 d/4/2 					; minutes
		f10 to integer! d/4/3 		; seconds
	"Z"]
]

sort-query-string: function [
	{takes a http query string and sorts it into its parts}
	QueryString][
	;Param2=value2&Param1=value1
	result: sort split QueryString "&"
]

unsplit: function [ 
	{takes a block and builds it back into a string combining using param}
	b [block!] param [string!]
][
	result: unspaced collect [ 
		for-each a b [ 
			keep ajoin [a param ]
		]
	]
	loop length param [ take/last result]
	result
]

SignedHeaders: copy []

Make-CanonicalHeaders: function [
	{takes a http header and sorts the headers, returns a string}
	req
][
	clear SignedHeaders
	; collect all the headers
	headers: sort exclude remove split req newline [""]
	CanonicalHeaders: collect [
		for-each header headers [
			keep copy name: copy/part lowercase/part header i: index-of find header ":" i
			take/last name
			append SignedHeaders name
			header: trim/head/tail skip header i
			while [find header "  "][
				replace/all header "  " " "
			]
			keep header
			keep newline
		]
	]
	unspaced CanonicalHeaders
]

lc-bin: function [
	{takes a binary and returns a text version in lowercase}
	b [binary!]
][
	r: lowercase form b
	take/last r
	remove/part r 2
	r
]

lc-hash: function [
	{returns a lowercase string of the sha256 of s}
	s [binary! string!]
][
	lc-bin sha256 s
]

mcr: Make-Canonical-Request: function [req body][
	dump req
	CanonicalQueryString: CanonicalURI: _

	CanonicalRequest: collect [
		parse req [copy method to space (keep method keep newline)
			any space [
				[	copy CanonicalURI to "?" "?" copy CanonicalQueryString to space
					|
					copy CanonicalURI to space
				]
			]
		]
		keep join-of CanonicalURI: default [copy "/"] newline
		keep either blank? CanonicalQueryString [newline][
			join-of unsplit sort-query-string CanonicalQueryString "&" newline
		]
		keep Make-CanonicalHeaders req 
		keep newline
		keep unsplit SignedHeaders ";"
		keep newline
		keep lc-hash body
	]
	return unspaced CanonicalRequest
]

StringToSign: function [scope request body][
	either parse request [thru "x-amz-date:" any space copy date [to newline | to end] to end][
		canreq: Make-Canonical-Request request body	
		unspaced [
			"AWS4-HMAC-SHA256" newline
			date newline
			scope newline
			lc-hash canreq
		]
	][
		make error! [
			type: 'Access 
			id: 'Protocol 
			arg1: "Unable to parse x-amz-date" 
		]
	]
]
getSignatureKey: function [key dateStamp regionName serviceName][
	kSecret: to binary! join-of "AWS4" key
	kDate: hmac-sha256 kSecret to-binary dateStamp
	kRegion: hmac-sha256 kDate to-binary regionName kDate
	kService: hmac-sha256 kRegion to-binary serviceName
	kSigning: hmac-sha256 kService to-binary "aws4_request" 
	kSigning
]

; should be x-amz-date, returns the new signed request]
Make-Authorization: function [req body scope access secret dateStamp regionName service][
	signingkey: getSignatureKey secret dateStamp regionName service
	sts: StringToSign scope req body
	signature: hmac-sha256 signingkey to binary! sts
	Authorization: unspaced [
		"Authorization: "
		"AWS4-HMAC-SHA256 "
		"Credential=" access "/" scope ", SignedHeaders=" unsplit SignedHeaders ";" ", "
		"Signature=" lc-bin signature
	]
	unspaced [req CRLF Authorization]
]
