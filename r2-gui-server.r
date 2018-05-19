REBOL [
    Title: "R2 GUI server"
    Date: 19-May-2018
    File: %t2-gui-server.r
    Purpose: {
    }
    History: [
]
    Notes: {
        use: view -s r2-gui-server.r
    }
]

; will be passing blocks to Ren-c
_: :none
listen-on: 8081

; download latest r3
ver: reverse rebol/Version
ver: rejoin [ "0." ver/2 "." ver/1]

r3binary: either system/version/4 = 3 [%r3.exe][%r3]
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
    close web
]

if not exists? %httpd.r [
    write %httpd.r read https://raw.githubusercontent.com/gchiu/Scripts-For-Rebol-2/059e962af47e740fbf8963af9327674c5070dd48/httpd.r
]

do %httpd.r

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
    cmd: _
    cancelled: false
]

view/new layout [
    origin 0
    b: banner 140x32 rate 1 
    effect [gradient 0x1 0.0.150 0.0.50]
    feel [engage: func [f a e] [set-face b now/time]]

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
            cmd: "{download complete} | read http://ipv4.download.thinkbroadband.com:8080/200MB.zip"
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
    textarea: area [300x400] join "Listening on port: " listen-on
]

task-queue: []

script: rejoin [{
Rebol [file: client.r3]

system/options/dump-size: 400
client-id: uuid/to-text uuid/generate
dump client-id
print "waiting 5 seconds ..."
wait 5 ; for things to start up

print "Now grabbing tasks"

forever [
    ; grab a task
    ; attempt [
        print ["requesting a task" now/time]
        task: to text! trim read join-of http://localhost:listen-on/tasks?client-id= client-id
        if task <> "none" [
            t1: now/precise
            print "loading task"
            task: do task
            probe task
            cmd: load task/cmd
            probe cmd
            print "doing task"
            result: do cmd
            print "finished task"
            t2: now/precise
            data: spaced ["Task Received by instance" client-id newline
                "Task commenced at:" t1 newline
                "Task finished at:" t2
                #{0D0A0D0A}
            ]
            if binary? result [
                append data result
            ]
            write http://localhost:listen-on/done-tasks compose [POST [content-type: "text/text"] (data)]
        ]
    ; ]
    wait 5
]
}]

replace/all script "listen-on" listen-on

write %script.reb script
call/show to-local-file reform [r3binary "-cs" %script.reb]

open/custom web: join httpd://: listen-on [ 
     ; you have access here to two objects: REQUEST and RESPONSE 
     ; you can set the response by altering the fields in the RESPONSE object 
     ; by default, the server returns 404 
    ;  probe request

    if request/action = "POST /done-tasks" [
        response/status: 200
        response/content: "OK"
        result: to string! request/binary
        parse/all result [copy text to #{0D0A0D0A} thru #{0D0A0D0A} copy binary to end]
        trim text
        trim/head/tail binary
        set-face textarea text
        binary: load binary
        attempt [print to string! binary]
    ]
    
    if request/action =  "GET /tasks" [ 
        either parse request/request-uri ["/tasks?client-id=" copy client-id to end][
            response/status: 200 
            response/type: "text/text"
            ; got a valid request so return a task
            new-task: none
            foreach task task-queue [
                if none? task/start [
                    task/start: now/precise
                    task/client-id: client-id
                    print mold task
                    print "======>sent a task"
                    new-task: mold task 
                    replace/all new-task "none" "_"
                    response/content: new-task
                    break
                ]
            ]
            if none? new-task [
                ; no tasks available to send blank task
                print "No tasks available"
                response/content: "none" 
            ]
        ][
            print "Unrecognized command received"
            response/content: "Unrecognized command received"
            response/status: 400
        ]
    ]
     ; setting RESPONSE/KILL? to TRUE will break the WAIT loop below 
] 
    
wait [] 
