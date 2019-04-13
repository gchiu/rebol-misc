Rebol [
	file: %setup-rebolweb.reb
	date: 13-April-2019
]

cd %replpad

root: http://hostilefork.com/media/shared/replpad-js/
html: to text! read join root %index.html

files: collect [
	parse html [
		some [
			thru ["href=" | "src="] {"} copy link to {"} thru {"} (
				if suffix? link [
					if "./" = copy/part link 2 [
						replace link "./" root
					] else [
						if not find "http" copy/part link 4 [
							insert link root
						]
					]
					keep link
				]
			)
		]
	]
]

write %index.html html
for-each file files [
	print ["Writing:" file]
	write last split-path file read to url! file
]
