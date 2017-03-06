rebol [
	file: %update.reb
	notes: {
		scans for the lastest build for your OS regardless whether it's a debug build, cpp or c build
	}
]

update: use [page url block latest file][
	func [][
		page: to string! read http://metaeducation.s3.amazonaws.com/index.html
		either parse page [ thru <rebol> copy latest to </rebol> to end][
			latest: load latest
			either block: select latest unspaced [rebol/version/3 "." rebol/version/4 "." rebol/version/5][
				url: block/1
				dump block
				either rebol/build < block/2 [
					print spaced ["This build is from" rebol/build "There is one from" block/2 "Do you want to update? (y/n)"]
					tf: input 
					either tf = "y" [
						print ["OK, downloading ..." file: last split-path url]
						write file read url
					][print "Update declined"]
				][
					print "You have the latest build."
				]
			][
				print "No update found for your OS version."
			]
		][
			print "Unable to read update data."
		]
		print "Finished."
	]
]
