REBOL [
	file: %buildHTML.r
	author: "Graham Chiu"
	date: [ 10-Aug-2010 16-Aug-2010 ]
	rights: 'LGPL
]

; eg: do-ifnot value? 'load-json http://www.ross-gill.com/r/altjson.r
do-ifnot: func [ value [logic!] src [url! file!]][ if not value [ do src ]]

ajoin: func [b [block!]] [
	insert head b copy ""
	rejoin b
]

pop: func [ stack [series!]
	/local tmp
][
    tmp: pick stack 1
	remove head stack
	:tmp
]

Push: func [ Stack[series!] Value 
	/Only
][
	head either Only 
	[insert/only Stack :Value]
	[insert Stack :Value]
]

buildHTML: func [template [block!]
] [
	out: copy ""
	stack: copy []
	build-css: func [ css [block!]
	][
		foreach item css [
			either find reduce [ url! file! ] type? item [
				append out rejoin [ {<link rel="stylesheet" type="text/css" href="} item {">} ]
			][
				if string? item [
					append out rejoin [ newline item newline ]
				]
			]
		]
	]
	build-js: func [ javascript [block!]
	][
		foreach item javascript [
			either find reduce [ url! file! ] type? item [
				append out rejoin [ {<script type="text/javascript" src="} item {">} </script> ]
			][
				if string? item [
					append out rejoin [ newline item newline ]
				]
			]
		]
	]
	id-class-rule: [
			opt [ 'id set id string! (append out rejoin [ { id="} id {"} ]) ]
			opt [ 'class set class string! ( append out rejoin [{ class="} class {"} ]) ]	
	]
	div-rule: [ 
		'div into [ 
			opt unset!
			( append out {<div} push stack </div> )
			id-class-rule
			( append out ">" )
			[	some div-rule |
				some [
					set code word! (attempt [ append out get code ]	) | 
					set tag tag! (append out tag) | 
					unset! | 
					set string string! (append out string) | 
					set function function! (append out do function)
				]
			] ( append out pop stack )
		]
	]
	probe parse compose/deep template [
		'doctype set doctype word! (
			if doctype = 'strict [
				append out <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
			]
		)
		'html into [ 
			( append out <html> push stack </html> )
			'head into [ 
				(append out <head> push stack </head>) 
				'meta set meta tag! (append out meta)
				'css set css block! (build-css css)
				'javascript set javascript block! (build-js javascript)
				'title [ 
					set title string! (append out ajoin [<title> title </title>] ) | 
					set tag tag! (append out tag)
				]
			] (append out pop stack)
			'body into [ 
				( append out {<body} push stack </body>)
				id-class-rule
				( append out ">" )
				some div-rule
			]
			(append out pop stack)
		]
		( append out pop stack)
		end
	]
	out
]

;; start specific page creation to test parser

css-links: [
	https://ajax.googleapis.com/ajax/libs/yui/2.8.1/build/reset-fonts-grids/reset-fonts-grids.css
	https://ajax.googleapis.com/ajax/libs/yui/2.8.1/build/menu/assets/skins/sam/menu.css
	%../css/test.css
	{        <style type="text/css">

            div.yui-b p {
            
                margin:0 0 .5em 0;
                color:#999;
            
            }
            
            div.yui-b p strong {
            
                font-weight:bold;
                color:#000;
            
            }
            
            div.yui-b p em {

                color:#000;
            
            }            
            
            h1 {

                font-weight:bold;
                margin:0 0 1em 0;
                padding:.25em .5em;
                background-color:#ccc;

            }

		#navigationmenu {
			position: static;
		}

		#navigationmenu .yuimenuitemlabel {
			_zoom: 1;
		}

		#navigationmenu .yuimenu .youmenuitemlabel {
			_zoom: normal;
		}
        </style>
	}
]

js-links: [
	https://ajax.googleapis.com/ajax/libs/yui/2.8.1/build/yahoo-dom-event/yahoo-dom-event.js
	https://ajax.googleapis.com/ajax/libs/yui/2.8.1/build/animation/animation-min.js
	https://ajax.googleapis.com/ajax/libs/yui/2.8.1/build/container/container_core-min.js
	https://ajax.googleapis.com/ajax/libs/yui/2.8.1/build/menu/menu-min.js
	%../js/test.js
]

template: [
	doctype strict
	html [
		head [
			meta <meta http-equiv="content-type" content="text/html; charset=utf-8">
			css  [(css-links)]
			javascript [(js-links)]
			title "this is the title!"
		]
		body [
			id "yahoo-com"
			class "yui-skin-sam"
			div [; body div 
				id "doc"
				class "yui-t1"
				div [; header div
					id "hd"
					"header"
				]
				div [
					id "bd"
					div [ 
						id "yui-main"
						div [
							class "yui-b"
							<!-- start: stack grids inside here --> 
						]
					]
					div [
						class "yui-b"
						; another comment
						<!-- secondary columns -->
						"^/secondary column data^/"
					]
				]
				div [ ; footer
					id "ft"
					(aword)
					<tag!>
				]
			]
		]
	]
]

aword: "^/This is some text which is in a word!^/"
result: buildHTML template
replace/all result "><" ">^/<"
probe result

