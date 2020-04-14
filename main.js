const express = require("express") 
const path = require("path") 
const multer = require("multer") 
const app = express() 
	
// View Engine Setup 
app.set("views",path.join(__dirname,"views")) 
app.set("view engine","ejs") 
	
// var upload = multer({ dest: "Upload_folder_name" }) 
// If you do not want to use diskStorage then uncomment it 
	
var storage = multer.diskStorage({ 
	destination: function (req, file, cb) { 

		// Uploads is the Upload_folder_name 
		cb(null, "uploads/"+req.params["userID"]) 
	}, 
	filename: function (req, file, cb) { 
	cb(null, file.fieldname + "-" + Date.now()+path.extname(file.originalname).toLowerCase()) 
	} 
}) 
	
// Define the maximum size for uploading 
// picture i.e. 1 MB. it is optional 
//const maxSize = 1 * 1000 * 1000; 
	
var upload = multer({ 
	storage: storage//, 
//  limits: { fileSize: maxSize }, 
  
// mypic is the name of file attribute 
}).single("mypic");	 

app.get("/",function(req,res){ 
	res.render("Signup"); 
}) 

app.get("/auditions/:userID", function(req, res){
	res.render("Signup", {userID:req.params["userID"]})
})
	
app.post("/uploadProfilePicture/:userID",function (req, res, next) { 
	console.log(req)
		
	// Error MiddleWare for multer file upload, so if any 
	// error occurs, the image would not be uploaded! 
	upload(req,res,function(err) { 

		if(err) { 

			// ERROR occured (here it can be occured due 
			// to uploading image of size greater than 
			// 1MB or uploading different file type) 
			res.send(err) 
		} 
		else { 

			// SUCCESS, image successfully uploaded 
			res.send("Success, Image uploaded!") 
		} 
	}) 
}) 
	
// Take any port number of your choice which 
// is not taken by any other process 
app.listen(8080,function(error) { 
	if(error) throw error 
		console.log("Server created Successfully on PORT 8080") 
}) 
