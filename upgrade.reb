rebol [
	file: %upgrade.reb
	notes: {
		scans for the lastest build for your OS regardless whether it's a debug build, cpp or c build
	}
]

upgrade: use [page url block latest file tf][
	func [][
		page: to string! read http://metaeducation.s3.amazonaws.com/index.html
		either parse page [ thru <rebol> copy latest to </rebol> to end][
			latest: load latest
			either block: select latest unspaced [rebol/version/3 "." rebol/version/4 "." rebol/version/5][
				url: block/1
				either rebol/build < block/2 [
					file: last split-path url
					print spaced ["This build is from" rebol/build "There is" file "from" block/2 "Do you want to update? (Y/n)"]
					tf: input 
					either any [tf = "y" empty? tf][
						print ["OK, downloading ..." file]
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
