Rebol [
	title: "Update Download List"
    file: %update-downloads.reb
    author: "Graham Chiu"
    Date: 26-March-2017
    Version: 0.3.5
    notes: {
        this script reads the xml returned by a S3 bucket listing, and then descending sorts the results by date and build number.
        It then generates the html tables that are inserted into a HTML template to create the index.html file

        The file is to uploaded to http://metaeducation.s3.amazonaws.com/index.html

        5-Mar-2017 will now process a community link that lists all the builds available
        6-Mar-2017 create a latest block in a HTML comment
    }
]

; get community-links which direct to community builds
; do a PR on https://github.com/gchiu/rebol-misc/blob/master/community-links.reb to add your builds
do https://raw.githubusercontent.com/gchiu/rebol-misc/master/community-links.reb

community-urls: copy []
tmp: copy []

; newer builds info? is working correctly on urls
info: func [ {gets name size and date from a url using the HTTP HEAD verb}
    p [url!]
][
    write p [HEAD]
]

site: http://metaeducation.s3.amazonaws.com/
drops: "travis-builds"
git: https://github.com/metaeducation/ren-c/commit/
template: https://raw.githubusercontent.com/gchiu/rebol-misc/master/index-template.txt

OS-table: ["0.2.40" "OSX x64" "0.3.1" "Win32 x86" "0.3.40" "Win64 x86" "0.4.4" "Linux32 x86" "0.4.40" "Linux64 x86" "0.13.2" "android5-arm" "0.13.1" "Android-arm"]
os-table-reverse: reverse copy os-table

; not going to get more then 1000 listings so ignore if truncated

files: copy []
builds: copy []
oss: copy []
dates: copy []
build-dates: copy []
build-rule: complement charset [ #"." #"-"]
; "os-string" [ url size date]
latest: copy []

os: build: filename: filesize: filepath: _

build-row: func [obj [object!]
    /local data
][  data: copy "<tr>"
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

Latest-obj: first files

Latest-build-no: sorted-builds/1
latest-build-date: build-dates/1/1

wanted: ["0.3.40" "0.4.40"]

; create a new table for each build number (limit to 5)
counter: 0
for-each build sorted-builds [
    ++ counter
    ; dump build
    either counter < 6 [
        append filelist table-header
        for-each obj files [ 
            if obj/build = build [
                append filelist build-row obj 
                if not find latest obj/os [
                    append latest obj/os
                    append/only latest reduce [
                        rejoin [site drops "/" obj/os "/" obj/name ]
                        obj/date
                    ]
                ]
            ]
        ]
        append filelist </table>
        append filelist <p>
    ][
        if counter > 20 [
            for-each obj files [
                if obj/build = build [
                    print spaced ["deleting ..." obj/name "of date" obj/date]
                    Delete-s3 obj/os obj/name
                ]
            ]
        ]
    ]
]

; now process community builds
; we need to get the file date so we can sort them in reverse order 

for-each site community-links [
    attempt [
        sites: load site
        append community-urls sites
    ]
    community-urls: unique community-urls
    for-each url community-urls [
        i: info url
        repend tmp [i/3 url]
    ]
]
sort/skip/reverse tmp 2
clear community-urls
append community-urls tmp

if error? try [
    ; now to fetch community builds
    row-data: copy ""
    for-each [date community] community-urls [
        attempt [
            android-info: info community: to url! community
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
                ; android-info/3
                date
                </td><td>"<a href=" git
                build
                ">" build </a>
                </td><td>
                round/to android-info/2 / 1000000 .01   
                " Mib"
                </td></tr>
            ]
            if o: select os-table-reverse os [
                if not find latest o [
                    append latest o
                    repend/only latest [
                        community
                        date
                    ]
                ]
            ]
        ]
    ]
    if not empty? row-data [
        append filelist 
        {<h4 class="muted">Community Builds</h4>
        <p>
        These are one-off community provided binaries created to test specific build combinations or platforms. Community builds are not automatically updated from the latest sources, and might be unstable.
        </p>
        }

        append filelist table-header
        append filelist row-data
        append filelist {</table><br>}
    ]
][
    print "Community builds not available"
]

; read and insert into the html template
page: read template
for-each [tag val] reduce [
    {<latest>} rejoin ["<rebol>" newline mold latest </rebol>]
    {<generated-file-list>} filelist
    {<update-date>} form now/precise
][
    replace page tag val
]
write %index.html page
