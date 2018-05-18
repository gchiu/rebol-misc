REBOL [
    Title: "Micro Web Server"
    Date: 10-Jun-2000
    File: %webserver.r
    Purpose: {
        Here is a web server that works quite well and can be
        run from just about any machine. It's not only fast,
        but its also small so it's easy to enhance.
    }
    History: [
    10-Jun-2000 "Buffers the entire request, adds address" 
    22-Jun-1999 "First posted"
]
    Notes: {
        Set the web-dir to point to the file directory that
        contains your web site files, such as index.html.
    }
    library: [
        level: 'intermediate 
        platform: none 
        type: none 
        domain: [web other-net] 
        tested-under: none 
        support: none 
        license: none 
        see-also: none
    ]
]

; download latest r3
ver: reverse rebol/Version
ver: rejoin [ "0." ver/2 "." ver/1]

r3binary: either system/version/4 = 3 [ %r3.exe][%r3]
if not exists? r3binary [
    downloads: read http://metaeducation.s3.amazonaws.com/index.html
    either parse downloads [thru <rebol> copy data to </rebol> to end][
        data: load data
        binary: select data ver
        fl: flash join "Download binary from " binary/1
        write/binary r3binary read/binary binary/1
        unview/only fl
        ; in linux should now set the permissions to executable
    ][
        print "Unable to find a current binary"
        halt
    ]
]

; setup web server
web-dir: %.   ; the path to where you store your web files

attempt [
    unview/all
    close listen-port
]

listen-port: open/lines tcp://:8080  ; port used for web connections

errors: [
    400 "Forbidden" "No permission to access:"
    404 "Not Found" "File was not found:"
]

send-error: function [err-num file] [err] [
    err: find errors err-num
    insert http-port join "HTTP/1.0 " [
        err-num " " err/2 "^M^/Content-type: text/html^M^/^M^/" 
        <HTML> <TITLE> err/2 </TITLE>
        "<BODY><H1>SERVER-ERROR</H1><P>REBOL Webserver Error:"
        err/3 " " file newline <P> </BODY> </HTML>
    ]
]

send-page: func [data mime /local headers] [
    headers: rejoin ["HTTP/1.0 200 OK^M^/Content-type: " mime "^M^/" "Content-length: " length? data {^M^/^M^/}]
    print "calling send-page"
    write-io http-port append headers data (add length? headers length? data)
    data: none
] 

buffer: make string! 1024  ; will auto-expand if needed

makeUUID: func [ 
     "Generates a Version 4 UUID that is compliant with RFC 4122" 
     /local data ; so 'data doesn't leak 
][ 
     ; COLLECT/KEEP is a handy accumulator 
     data: collect [ 
         loop 16 [keep -1 + random/secure 256] 
     ] 
    
     ; don't need to wrap each expression with DO 
     ; Rebol infix evaluation is left to right, so don't need to parenthesize 
     data/7: data/7 and 15 or 64 
     data/9: data/9 and 63 or 128 
    
     ; TO BINARY! converts a block of integers to code points 
     ; ENBASE converts the codepoints to hex 
     data: enbase/base to binary! data 16 
    
     ; We'll just modify this new string and return the head 
     data: insert skip data 8 "-" 
     data: insert skip data 4 "-" 
     data: insert skip data 4 "-" 
     data: insert skip data 4 "-" 
     head data 
] 

random/seed now/precise  ; needed for the makeUUID

task: make object! [
    id: 
    client-id: 
    callback: 
    created: 
    start: 
    end: 
    cmd: none
    cancelled: false
]

view/new layout [
    button "Print hello" [print "hello"]
    button "Rebol.com" 100 [
        t: make task compose [
            id: (makeUUID)
            created: (now/precise)
            cmd: "read http://www.rebol.com"
            callback: func [data][
                set-face textarea data
            ]
        ]
        append task-queue t
    ]
    button "https://forum.rebol.info" 150 [
        t: make task compose [
            id: (makeUUID)
            created: (now/precise)
            cmd: "read https://forum.rebol.info"
            callback: func [data][
                set-face textarea data
            ]
        ]
        append task-queue t
    ]
    text "This won't work on R2/View since it lacks the correct cipher suite"
    button "Download 200 Mb file" 150 [
        t: make task compose [
            id: (makeUUID)
            created: (now/precise)
            cmd: "read http://ipv4.download.thinkbroadband.com:8080/200MB.zip"
            callback: func [data][
                set-face textarea data
            ]
        ]
        append task-queue t
    ]
    button "Browse Index" [
        append task-queue make task compose [
            id: (makeUUID)
            created: (now/precise)
            cmd: "browse http://metaeducation.s3.amazonaws.com/index.html"
            callback: func [data][
                set-face textarea "Browsed to http://metaeducation.s3.amazonaws.com/index.html"
            ]
        ]
    ]
    button "Task Queue" [probe task-queue]
    button "Halt" [unview/all halt]
    textarea: area [300x400]
]

task-queue: []

script: {
Rebol [file: client.r3]

system/options/dump-size: 400
client-id: uuid/to-text uuid/generate
dump client-id
wait 5 ; for things to start up

print "Now grabbing tasks"

forever [
    ; grab a task
    ; attempt [
        print ["requesting a task" now/time]
        task: to text! trim read join-of http://localhost:8080/tasks?client-id= client-id
        dump task
        if task <> "none" [
            print "loading task"
            task: do task
            dump task
        ]
    ; ]
    wait 5
]
}

write %script.reb script
call/show to-local-file reform [r3binary "-cs" %script.reb]

forever [
    either not error? set/any 'err try [
        http-port: first wait listen-port
        clear buffer
        while [not empty? request: first http-port][
            repend buffer [request newline]
        ]
        repend buffer ["Address: " http-port/host newline] 
        print buffer
        file: "index.html"
        mime: "text/plain"
        parse buffer ["get" ["http" | "/ " | copy file to " "]]
        ; {/tasks?client-id=24230C17-B413-48B7-9B63-972C377AA42B}
        ?? file
        either parse file ["/tasks?client-id=" copy client-id to end][
            ; got a valid request so return a task
            new-task: none
            foreach task task-queue [
                if none? task/start [
                    task/start: now/precise
                    task/client-id: client-id
                    print mold task
                    print "======>sent a task"
                    task: mold task
                    replace/all task "none" "_"
                    send-page mold task "text/text"
                    break
                ]
            ]
            if none? new-task [
                ; no tasks available to send blank task
                print "No tasks available"
                send-page "none" "text/text"
            ]
        ][
            print "Unrecognized command received"
            send-error 400 file
        ]
        close http-port
    ][
        print "Successful request" now/precise
    ][
        print mold disarm get/any 'err
    ]
]
