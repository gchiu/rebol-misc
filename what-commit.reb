Rebol [
    file: %what-commit.reb
    date: 22-Mar-2017
    author: "Graham Chiu"
    Notes: {attempts to return the commit url for a ren-c downloaded travis binary} 
]

what-commit: function [{attempts to return the commit url for a ren-c downloaded travis binary}][
    builds: copy []
    page: to string! read http://metaeducation.s3.amazonaws.com/index.html
    version: unspaced [rebol/version/3 "." rebol/version/4 "." rebol/version/5]
    directory: unspaced ["href=" http://metaeducation.s3.amazonaws.com/travis-builds/ version "/"]
    build-rule: [thru directory copy binary to ">" 
        thru binary thru <td> copy date to </td> thru "https://github.com/metaeducation/ren-c/commit"
        thru ">" copy build-no to "<"
        (repend builds [build-no date])
    ]
    parse page [some build-rule]
    commit: diffcandidate: _
    diff: 24:00 * 365 ; make it a year - really pessimistic
    for-each [build-no date] builds [
        date: to date! date
        ; d will always be older then rebol/build
        diffcandidate: min diff d: difference date rebol/build  
        if diffcandidate < diff [
            diff: diffcandidate
            commit: unspaced [https://github.com/metaeducation/ren-c/commit "/" build-no]
        ]
    ]
    ; dump diff
    either diff > 0:05:00 [
        print "This binary is no longer listed so commit can not be ascertained!"
    ][
        to url! commit
    ]
]
