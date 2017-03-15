rebol [

]

import/no-lib %fract.reb
append lib compose [fract: (:fract)]

do %prot-http.r

foo: read http://www.rebol.com
