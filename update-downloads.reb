Rebol [
	file: %update-downloads.reb
	author: "Graham Chiu"
	Date: 3-March-2017
	Version: 0.3.1
	notes: {
		this script reads the xml returned by a S3 bucket listing, and then descending sorts the results by date and build number.
		It then generates the html tables that are inserted into a HTML template to create the index.html file

		The file is uploaded to http://metaeducation.s3.amazonaws.com/index.html
	}
]

; these contain community builds of format http://address.xxx/.../os-name/r3-buildno
; the os-name is used for the download table
community-urls: reduce [
	http://giuliolunati.altervista.org/r3/android-arm/r3-489ca6a6-debug
	http://giuliolunati.altervista.org/r3/android5-arm/r3-23a15efe-debug
]

site: http://metaeducation.s3.amazonaws.com/
drops: "travis-builds"
git: https://github.com/metaeducation/ren-c/commit/
template: https://raw.githubusercontent.com/gchiu/rebol-misc/master/index-template.txt

OS-table: ["0.3.1" "Win32 x86" "0.3.40" "Win64 x86" "0.4.4" "Linux32 x86" "0.4.40" "Linux64 x86" "0.13.2" "android5-arm" "0.13.1" "Android-arm"]

; not going to get more then 1000 listings so ignore if truncated

files: copy []
builds: copy []
oss: copy []
dates: copy []
build-dates: copy []
build-rule: complement charset [ #"." #"-"]

os: build: filename: filesize: filepath: _

build-row: func [obj [object!]
	/local data
][	data: copy "<tr>"
	os: select OS-table obj/os
	append data ajoin [<td><b> os </b>] ; platform
	append data ajoin [<td> "<a href=" site drops "/" obj/os "/" obj/name ">" <i class='icon-file'></i> obj/name </a> </td>] ; downloads
	append data ajoin [<td> form obj/date </td>] ; build-dates
	append data ajoin [<td> "<a href=" git obj/build ">" obj/build "</a>" </td>] ; commit
	append data ajoin [<td> form round/to obj/size / 1000000 .01 " Mib" </td> </tr>] ; size in Mbs
]

content-rule: [ thru <Contents> thru <key> copy filename to </key>
	(
		build: _
		filepath: split filename "/"
		if 3 = length filepath [
			; travis-builds os filename
			if drops = take filepath [
				; os filename
				append oss os: take filepath
				; r3-build[-cpp[.exe]]
				filename: take filepath
				if parse filename [ "r3-" copy build some build-rule to end][
					append builds build
				]
			]
		]
	)
	thru <LastModified> copy filedate to </LastModified> (
		; 2017-03-03T01:19:21.000Z<
		if build [
			replace filedate "T" "/"
			replace filedate "Z" ""
			filedate: load filedate
			append dates filedate
		]
	)
	thru <Size> copy filesize to </Size> (
		if build [
			filesize: load filesize
		]
	)

	thru </Contents> (
		if build [
			append files make object! compose [
				build: (build)
				os: (os)
				name: :filename
				date: :filedate
				size: :filesize
			]
			append/only build-dates reduce [:filedate :build]
		]
	)
]

parse to string! read site [some content-rule]

oss: unique oss
builds: unique builds
dates: sort/reverse unique dates
build-dates: sort/reverse unique build-dates

sorted-builds: copy []

; [[3-Mar-2017/1:19:21 "e60dc7f1"] [2-Mar-2017/23:26:50 "e60dc7f1"]

; let's get the builds now in reverse date order
for-each build build-dates [
	append sorted-builds build/2
]

sorted-builds: unique sorted-builds

; now let's build up a list of urls

filelist: copy ""

table-header: {<table class='table'>
<thead>
<tr>
<th>Platform</th>
<th>Download</th>
<th>Build Date (UTC)</th>
<th>Commit</th>
<th>Size</th>
</tr>
</thead>
}

; create a new table for each build number
for-each build sorted-builds [
	append filelist table-header
	for-each obj files [ 
		if obj/build = build [
			append filelist build-row obj 
		]
	]
	append filelist </table>
	append filelist <p/>
]

info: func [ p [url!]
	/local path port target result
][
	path: sys/decode-url p
	if blank? find path 'path [append path [path: "/"]]
	target: to file! path/path
	path/path: "/"
	port: open path
	result: write port compose [HEAD (target)]
	close port
	return result
]

; now process community builds
if error? try [
	; now to fetch community builds
	row-data: copy ""
	for-each community community-urls [
		attempt [
			android-info: info community
			; // == [%/r3/renc-23a15efe-debug 2501412 2-Mar-2017/23:28:36]
			os: form last split-path first Android-paths: split-path community
			if #"/" = last os [
				take/last os
				change/part os uppercase os/1 1
			]
			parse android-paths/2 [ thru "-" copy build [to "-"| to end]]

			append row-data ajoin [
				<tr><td><b>
				os
				</b><td>
				"<a href="
				community
				"><i class='icon-file'></i>"
				android-paths/2
				</a></td><td>
				android-info/3
				</td><td>"<a href=" git
				build
				">" build </a>
				</td><td>
				round/to android-info/2 / 1000000 .01	
				" Mib"
				</td></tr>
			]
		]
	]
	if not empty? row-data [
		append filelist 
		{<h4 class="muted">Community Builds</h4>
		<p>
		These are one-off binaries created to test specific build combinations or platforms. Experimental builds are not automatically updated from the latest sources, and might be unstable.
		</p>
		}

		append filelist table-header
		append filelist row-data
		append filelist {</table><p/>}
	]
][
	print "Community builds not available"
]


; read and insert into the html template
page: read template
replace page {<generated-file-list>} filelist
replace page {<update-date>} form now/precise
write %www/index.html page
; cd %www
; call/shell "aws s3 cp index.html s3://metaeducation/"
; cd %../
