Rebol [
  notes: {Docx templating test using JS and Rebol}
  date: 7-April-2019
]
comment {
  Ask a few questions, then generate a JS function which we push to the DOM.
  This should convert the template docx to filled with our data
}

prin "First Name: " until [not empty? fname: input]
prin "Last Name: " until [not empty? lname: input]
prin "Mobile: " until [not empty? mobile: input]
prin "Company: " until [not empty? company: input]

data: {function generate() {
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
    }}

data: reword data [a fname b lname c mobile d company]
