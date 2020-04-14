const express = require("express") 
const path = require("path") 
const multer = require("multer") 
const bodyParser = require("body-parser")
const fs = require("fs")
const app = express() 
	
// View Engine Setup 
app.set("views",path.join(__dirname,"views")) 
app.use(express.static(path.join(__dirname, "public")))
app.set("view engine", "ejs") 

app.use(bodyParser.json()); 
app.use(bodyParser.urlencoded({
	extended: true
}))
	
var storage = multer.diskStorage({ 
	destination: function (req, file, cb) { 

		// Uploads is the Upload_folder_name 
		var output_path = path.join("uploads", req.params["userID"])
		console.log("checking if exists")
		if (!fs.existsSync(output_path)){
			fs.mkdirSync(output_path);
		}
		cb(null, output_path) 
	}, 
	filename: function (req, file, cb) { 
	cb(null, req.body["part_name"] + "-" + Date.now()+path.extname(file.originalname).toLowerCase()) 
	} 
}) 
	
var upload = multer({ 
	storage: storage
});	 

app.get("/audition/:userID", function(req, res){
	res.render("Signup", {userID:req.params["userID"]})
})
	
app.post("/uploadProfilePicture/:userID", upload.single("mypic"),function (req, res, next) { 
	console.log(req.body)
	res.render("success", {userID:req.params["userID"]})
}) 
	
// Take any port number of your choice which 
// is not taken by any other process 
app.listen(80,function(error) { 
	if(error) throw error 
		console.log("Server created Successfully on PORT 80") 
}) 
