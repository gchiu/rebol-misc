Rebol [
  file: %community-links.reb
  author: "Graham"
  date: 6-Mar-2017
  notes: {
    This page is used for the source for ren-c Community builds as shown on http://metaeducation.s3.amazonaws.com/index.html
    
    Each link needs to return a block! of URLs, and each URL points to a single binary
    
    So, please test your site like this:
    
    >> sites: load http://giuliolunati.altervista.org/r3/ls.php
      == [http://giuliolunati.altervista.org/r3/android5-arm/r3-23a15efe-debug
      http://giuliolunati.altervista.org/r3/android5-arm/r3-271c5b53-debug
      http://giuliolunati.altervista.org/r3/android-arm/r3-489ca6a6-debug
    ]

    >> type-of sites
    == block!
    
    >> type-of sites/1
    == url!

     As shown above, each file URL needs to be of the format
     
     http://mysite.com/my/download/directory/os-name/filename
        where filename is like r3-buildhash[-debug]
     
     The os-name will be used for the platform column,  and the buildhash will be used to link back to the commit 
     on the github ren-c page.  
  }
]

community-links: [
	http://giuliolunati.altervista.org/r3/ls.php
	http://rebolbinaries.0pt.pw/downloads.reb
]
