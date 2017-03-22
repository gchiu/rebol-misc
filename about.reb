Rebol [
    file: %about.reb
    author: "Graham Chiu"
    Date: 23-March-2017
    Version: 0.1.0
    notes: {
        This script reads the xml returned by a S3 bucket listing, and then descending sorts the results by date and build number.
        It then incorporates the commit hash for the build you have into text about your build if still avaialble on S3.
    }
]

about: function ["Displays build information"][
    site: http://metaeducation.s3.amazonaws.com/
    drops: "travis-builds"
    git: https://github.com/metaeducation/ren-c/commit/
    build-dates: copy []
    build-rule: complement charset [ #"." #"-"]
    filename: filesize: filepath: _

    content-rule: [ thru <Contents> thru <key> copy filename to </key>
        (
            build: _
            filepath: split filename "/"
            if 3 = length filepath [
                ; travis-builds os filename
                if drops = take filepath [
                    take filepath
                    filename: take filepath
                    parse filename [ "r3-" copy build some build-rule to end]
                ]
            ]
        )
        thru <LastModified> copy filedate to </LastModified> (
            ; 2017-03-03T01:19:21.000Z<
            if build [
                replace filedate "T" "/"
                replace filedate "Z" ""
                filedate: load filedate
            ]
        )
        thru <Size> copy filesize to </Size>
        thru </Contents> (
            if build [
                append/only build-dates reduce [:filedate :build]
            ]
        )
    ]

    parse to string! read site [some content-rule]
    build-dates: sort/reverse unique build-dates

    diff: 365 * 24:00
    commit: _

    for-each build build-dates [
        if negative? candidate: difference build/1 rebol/build [break]
        if candidate < diff [
            diff: candidate
            commit: build/2
        ]
    ]
    commit: either diff > 0:05:00 [
        "N/A"
    ][
        commit
    ]
    spaced [
        "Version:" rebol/version "Platform:" form rebol/platform "Build:" rebol/build "Commit:" join-of git commit 
    ]
]
