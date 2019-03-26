Rebol [
	file: %latest-of.reb
	date: 26-Mar-2019
	Author: "Graham"
  note: "web utility only"
]

latest-of: function [os [text!]][
	root: https://s3.amazonaws.com/metaeducation/travis-builds/
	commit: copy/part rebol/commit 7
	digit: charset [#"0" - #"6"]
	if parse os [ 1 digit "." 1 2 digit "." 1 2 digit end][
		; looks like it might be valid OS
		filename: unspaced ["r3-" commit]
		debugfilename: append copy filename "-debug"
		if find ["0.3.1" "0.3.40"][
			append filename: %.exe
			append debugfilename: %.exe
		]
		print "searching ..."
		filename.info: js-head filename.url: to-url unspaced [root os "/" filename]
		debugfilename.info: js-head debugfilename.url: to-url unspaced [root os "/" debugfilename]
		-- filename.info
		print filename.url
		-- debugfilename.info
		print debugfilename.url
	] else [
		print "Invalid OS"
	]
]
