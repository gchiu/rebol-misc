Rebol [
  date: 7-April-2019
  notes: {
    Docx templating test using JS and Rebol
  
    Ask a few questions, then generate a JS function which we push to the DOM.
    This should convert the template docx to be filled with our data which you download
  }
]

for-each site [
  https://cdnjs.cloudflare.com/ajax/libs/docxtemplater/3.9.1/docxtemplater.js
  https://cdnjs.cloudflare.com/ajax/libs/jszip/2.6.1/jszip.js
  https://cdnjs.cloudflare.com/ajax/libs/FileSaver.js/1.3.8/FileSaver.js
  https://cdnjs.cloudflare.com/ajax/libs/jszip-utils/0.0.2/jszip-utils.js
][
  js-do site
]

js-do {var loadFile = function(url,callback){
        JSZipUtils.getBinaryContent(url,callback);
    };
}

prin "First Name: " until [not empty? fname: input]
prin "Last Name: " until [not empty? lname: input]
prin "Mobile: " until [not empty? mobile: input]
prin "Company: " until [not empty? company: input]

data: {var window.generate = function() {
        loadFile("https://metaeducation.s3.amazonaws.com/tag-example.docx",function(error,content){
            if (error) { throw error };
            var zip = new JSZip(content);
            var doc=new window.docxtemplater().loadZip(zip)
            doc.setData({
                first_name: '$a',
                last_name: '$b',
                phone: '$c',
                description: '$d'
            });
            try {
                // render the document (replace all occurences of {first_name} by John, {last_name} by Doe, ...)
                doc.render()
            }
            catch (error) {
                var e = {
                    message: error.message,
                    name: error.name,
                    stack: error.stack,
                    properties: error.properties,
                }
                console.log(JSON.stringify({error: e}));
                // The error thrown here contains additional information when logged with JSON.stringify (it contains a property object).
                throw error;
            }
            var out=doc.getZip().generate({
                type:"blob",
                mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            }) //Output the document using Data-URI
            saveAs(out,"output.docx")
        })
    };
}

data: reword data [a fname b lname c mobile d company]

js-do data

js-do {window.generate()}

