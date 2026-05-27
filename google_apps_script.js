/**
 * JSS College PG Admission - Google Apps Script Backend
 * 
 * Instructions:
 * 1. Create a Google Sheet and name it (e.g., "PG Admissions").
 *    The sheet must have a sheet named "Sheet1" (default).
 * 2. Create a Google Drive Folder where uploaded documents will be saved.
 * 3. Copy your Google Sheet ID (from the browser URL) and Google Drive Folder ID.
 * 4. Paste these IDs in the global variables below (SPREADSHEET_ID and DRIVE_FOLDER_ID).
 * 5. Open https://script.google.com, create a New Project, paste this entire file's content, and save.
 * 6. Click "Deploy" -> "New deployment".
 * 7. Choose type "Web App", Execute as: "Me", Access: "Anyone".
 * 8. Deploy, authorize permissions, and copy the Web App URL.
 * 9. Paste the Web App URL in the Flutter project's `api_service.dart`.
 */
var SPREADSHEET_ID = "1LczBsfFEcaLMfxM0rF0DMiBrV2M6qWuxeIZBS6OtNbY";
var DRIVE_FOLDER_ID = "1JtEIAQtxUIiYnV46gtGFRMDBi1VxzGqs";

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    
    // 1. Open Spreadsheet and select Sheet1
    var ss = SpreadsheetApp.openById(SPREADSHEET_ID);
    var sheet = ss.getSheetByName("Sheet1");
    
    // Create headers if the sheet is empty
    if (sheet.getLastRow() === 0) {
      sheet.appendRow([
        "Application ID", "Timestamp", "Course Selected", "Student Name", "Parents Name", 
        "Date of Birth", "Place of Birth", "Nationality", "Religion", "Caste", "Sex", "Mother Tongue",
        "Present Address", "Permanent Address", "Aadhaar Number", "Phone Number", "Mobile Number", "Email",
        "Last Attended Institution", "Subjects Studied",
        "Sem 1 Total", "Sem 1 Secured", "Sem 1 Pct",
        "Sem 2 Total", "Sem 2 Secured", "Sem 2 Pct",
        "Sem 3 Total", "Sem 3 Secured", "Sem 3 Pct",
        "Sem 4 Total", "Sem 4 Secured", "Sem 4 Pct",
        "Sem 5 Total", "Sem 5 Secured", "Sem 5 Pct",
        "Sem 6 Total", "Sem 6 Secured", "Sem 6 Pct",
        "Grand Total Marks", "Grand Secured Marks", "Grand Percentage",
        "Category Claimed", "Parents Occupation", "Parents Annual Income",
        "Photo URL", "Marks Cards URL", "Character Certificate URL", "SSLC PUC Certificate URL",
        "Income Certificate URL", "Caste Certificate URL", "Transfer Certificate URL", "Aadhaar Card URL",
        "SBI Collect Ref No", "Payment Date", "Payment Receipt URL", "Status"
      ]);
    }
    
    // Generate a unique Application ID (e.g. JSS-PG-2026-XXXX)
    var timestamp = new Date();
    var uniqueId = "JSS-PG-" + timestamp.getFullYear() + "-" + Math.floor(1000 + Math.random() * 9000);

    // 2. Create or get a folder for the student under the main upload folder
    var mainFolder = DriveApp.getFolderById(DRIVE_FOLDER_ID);
    var studentName = data.name ? data.name.trim() : "Unknown Student";
    var folderName = studentName + "_" + uniqueId;
    var studentFolder;
    var folders = mainFolder.getFoldersByName(folderName);
    if (folders.hasNext()) {
      studentFolder = folders.next();
    } else {
      studentFolder = mainFolder.createFolder(folderName);
      // Set folder to be viewable by anyone with link so college admin can access it
      studentFolder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    }
    
    var fileUrls = {};
    
    var filesToUpload = {
      "photo": data.files.photo,
      "marksCards": data.files.marksCards,
      "characterCert": data.files.characterCert,
      "sslcPucCard": data.files.sslcPucCard,
      "incomeCert": data.files.incomeCert,
      "casteCert": data.files.casteCert,
      "transferCert": data.files.transferCert,
      "aadhaarCard": data.files.aadhaarCard,
      "paymentReceipt": data.files.paymentReceipt
    };
    
    for (var key in filesToUpload) {
      var fileData = filesToUpload[key];
      if (fileData && fileData.base64 && fileData.fileName) {
        fileUrls[key] = saveBase64File(studentFolder, fileData.base64, fileData.fileName, fileData.mimeType);
      } else {
        fileUrls[key] = "Not Uploaded";
      }
    }
    
    // 3. Append Data Row to the Sheet
    sheet.appendRow([
      uniqueId,
      timestamp,
      data.course,
      data.name,
      data.parentsName,
      data.dob,
      data.placeOfBirth,
      data.nationality,
      data.religion,
      data.caste,
      data.sex,
      data.motherTongue,
      data.presentAddress,
      data.permanentAddress,
      data.aadhaarNo,
      data.phoneNo,
      data.mobileNo,
      data.email,
      data.lastInstitution,
      data.subjectsStudied.join(", "),
      
      // Sem 1
      data.marks.sem1.total, data.marks.sem1.secured, data.marks.sem1.percentage,
      // Sem 2
      data.marks.sem2.total, data.marks.sem2.secured, data.marks.sem2.percentage,
      // Sem 3
      data.marks.sem3.total, data.marks.sem3.secured, data.marks.sem3.percentage,
      // Sem 4
      data.marks.sem4.total, data.marks.sem4.secured, data.marks.sem4.percentage,
      // Sem 5
      data.marks.sem5.total, data.marks.sem5.secured, data.marks.sem5.percentage,
      // Sem 6
      data.marks.sem6.total, data.marks.sem6.secured, data.marks.sem6.percentage,
      
      // Grand Totals
      data.marks.grand.total, data.marks.grand.secured, data.marks.grand.percentage,
      
      data.category,
      data.parentOccupation,
      data.parentAnnualIncome,
      
      // File URLs
      fileUrls["photo"],
      fileUrls["marksCards"],
      fileUrls["characterCert"],
      fileUrls["sslcPucCard"],
      fileUrls["incomeCert"],
      fileUrls["casteCert"],
      fileUrls["transferCert"],
      fileUrls["aadhaarCard"],
      
      // Payment details
      data.payment.refNo,
      data.payment.date,
      fileUrls["paymentReceipt"],
      
      "Pending" // Default application status
    ]);
    
    return ContentService.createTextOutput(JSON.stringify({
      "status": "success",
      "applicationId": uniqueId,
      "message": "Application submitted successfully!"
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      "status": "error",
      "message": error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Saves a base64 encoded file into the target Google Drive folder.
 */
function saveBase64File(folder, base64String, fileName, mimeType) {
  try {
    var decoded = Utilities.base64Decode(base64String);
    var blob = Utilities.newBlob(decoded, mimeType || "application/octet-stream", fileName);
    var file = folder.createFile(blob);
    
    // Set file to be viewable by anyone with link so college admin can access it
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    
    return file.getUrl();
  } catch (e) {
    return "Error Uploading: " + e.toString();
  }
}
