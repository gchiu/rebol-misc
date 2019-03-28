Rebol [
	file: %latest-of.reb
	date: 26-Mar-2019
	Author: "Graham"
  	note: "web utility only"
]

latest-of: function [os [tuple!]][
  parse to text! read https://metaeducation.s3.amazonaws.com/travis-builds/0.16.2/last_git_commit_short.js
     [{last_git_commit_short = '} copy commit to {'} to end] 
	root: https://s3.amazonaws.com/metaeducation/travis-builds/
	; commit: copy/part rebol/commit 7
	digit: charset [#"0" - #"6"]
	inf?: if find form rebol/version "2.102.0.16.2" [
    fsize-of: function [o [object!][to integer! o/content-length]
    fdate-of: function [o [object!][
        date: o/last-modified
    ]
		pr: specialize 'replpad-write [html: true]
		:js-head] 
	else [
    fsize-of: function [o [object!][o/size]
    fdate-of: function [o [object!][
      o/date    
    ]
		pr: :print
		:info?
	]
	os: form os
	if parse os [ 1 digit "." 1 2 digit "." 1 2 digit end][
		; looks like it might be valid OS
		filename: unspaced ["r3-" commit]
		debugfilename: append copy filename "-debug"
		if find ["0.3.1" "0.3.40"] os [
			append filename %.exe
			append debugfilename %.exe
		]
    latest: 1-Jan-1980
		print "searching ..."
		if error? entrap [
			filename.info: inf? filename.url: to-url unspaced [root os "/" filename]
			print mold filename.info
			pr unspaced ["<a href=" filename.url ">" filename.url </a> <br/>]
		][
			print ["file:" filename "doesn't exist, it may still be being deployed"]
		]
		if error? entrap [
			debugfilename.info: inf? debugfilename.url: to-url unspaced [root os "/" debugfilename]
			print mold debugfilename.info
			pr unspaced ["<a href=" debugfilename.url ">" debugfilename.url </a> <br/>]
		][
			print ["file:" debugfilename "doesn't exist, it may still be being deployed"]
		]
			
	] else [
		print "Invalid OS"
	]
]
