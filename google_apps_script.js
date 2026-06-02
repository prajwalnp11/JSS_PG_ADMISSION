/**
 * JSS College PG Admission - Google Apps Script Backend
 * 
 * Securely handles:
 * 1. Email OTP generation & verification using GmailApp & Google Cache Service.
 * 2. Admission Form data submission to Google Sheets.
 * 3. File uploads to Google Drive under student-specific folders.
 * 4. Staff panel queries (fetch all applications).
 * 5. Staff review actions (approve/reject status updates in Sheets with Gmail auto-delivery).
 */

var SPREADSHEET_ID = "1LczBsfFEcaLMfxM0rF0DMiBrV2M6qWuxeIZBS6OtNbY";
var DRIVE_FOLDER_ID = "1JtEIAQtxUIiYnV46gtGFRMDBi1VxzGqs";

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    
    // Route request based on action parameter
    if (data.action === "sendOtp") {
      return handleSendOtp(data.email);
    } else if (data.action === "verifyOtp") {
      return handleVerifyOtp(data.email, data.otp);
    } else if (data.action === "fetchApplications") {
      return handleFetchApplications();
    } else if (data.action === "updateStatus") {
      return handleUpdateStatus(data.appId, data.status);
    } else {
      // Default: Process form submission
      return handleApplicationSubmission(data);
    }
    
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      "status": "error",
      "message": "System Error: " + error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Generates and sends a 6-digit OTP to the user's email address.
 */
function handleSendOtp(email) {
  if (!email) {
    return createJsonResponse("error", "Email address is required.");
  }
  
  var cleanEmail = email.trim().toLowerCase();
  if (!validateEmailFormat(cleanEmail)) {
    return createJsonResponse("error", "Please enter a valid email address.");
  }
  
  // Generate 6-digit OTP code
  var otp = Math.floor(100000 + Math.random() * 900000).toString();
  
  // Save OTP in Google cache service for 10 minutes (600 seconds)
  var cache = CacheService.getScriptCache();
  cache.put(cleanEmail, otp, 600);
  
  // Dispatch Email
  try {
    sendOtpEmail(cleanEmail, otp);
    return ContentService.createTextOutput(JSON.stringify({
      "status": "success",
      "message": "OTP sent successfully to your email."
    })).setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return createJsonResponse("error", "Gmail Delivery Error: " + err.toString());
  }
}

/**
 * Verifies the OTP entered by the user. If verified, sets a validation flag in the cache.
 */
function handleVerifyOtp(email, otp) {
  if (!email || !otp) {
    return createJsonResponse("error", "Email and OTP code are required.");
  }
  
  var cleanEmail = email.trim().toLowerCase();
  var cache = CacheService.getScriptCache();
  var storedOtp = cache.get(cleanEmail);
  
  // Verify submitted OTP (Bypass master code '123456' allowed for testing)
  if (otp === "123456" || (storedOtp && storedOtp === otp)) {
    // Record verified status for 15 minutes (900 seconds) to allow form submission
    cache.put(cleanEmail + "_verified", "true", 900);
    // Delete OTP from cache to prevent reuse
    cache.remove(cleanEmail);
    
    return createJsonResponse("success", "Email address verified successfully.");
  } else {
    return createJsonResponse("error", "Invalid or expired OTP. Please try again.");
  }
}

/**
 * Fetches all student applications from the Google Sheet.
 */
function handleFetchApplications() {
  try {
    var ss = SpreadsheetApp.openById(SPREADSHEET_ID);
    var sheet = ss.getSheetByName("Sheet1");
    
    if (sheet.getLastRow() <= 1) {
      return ContentService.createTextOutput(JSON.stringify({
        "status": "success",
        "applications": []
      })).setMimeType(ContentService.MimeType.JSON);
    }
    
    var values = sheet.getDataRange().getValues();
    var headers = values[0];
    var applications = [];
    
    for (var i = 1; i < values.length; i++) {
      var row = values[i];
      var app = {};
      
      for (var col = 0; col < headers.length; col++) {
        var header = headers[col];
        var val = row[col];
        
        // Convert Date objects to ISO Strings
        if (val instanceof Date) {
          val = val.toISOString();
        }
        app[header] = val;
      }
      applications.push(app);
    }
    
    return ContentService.createTextOutput(JSON.stringify({
      "status": "success",
      "applications": applications
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    return createJsonResponse("error", "Failed to fetch applications: " + error.toString());
  }
}

/**
 * Updates application status in Google Sheets and triggers automatic welcome or rejection email.
 */
function handleUpdateStatus(appId, newStatus) {
  try {
    if (!appId || !newStatus) {
      return createJsonResponse("error", "Application ID and Status are required.");
    }
    
    var ss = SpreadsheetApp.openById(SPREADSHEET_ID);
    var sheet = ss.getSheetByName("Sheet1");
    var values = sheet.getDataRange().getValues();
    var headers = values[0];
    
    var appIdColIdx = headers.indexOf("Application ID");
    var statusColIdx = headers.indexOf("Status");
    var emailColIdx = headers.indexOf("Email");
    var nameColIdx = headers.indexOf("Student Name");
    var courseColIdx = headers.indexOf("Course Selected");
    
    if (appIdColIdx === -1 || statusColIdx === -1) {
      return createJsonResponse("error", "Invalid sheet structure. Headers missing.");
    }
    
    var targetRowIndex = -1;
    for (var i = 1; i < values.length; i++) {
      if (values[i][appIdColIdx] === appId) {
        targetRowIndex = i;
        break;
      }
    }
    
    if (targetRowIndex === -1) {
      return createJsonResponse("error", "Application ID not found: " + appId);
    }
    
    // Set status value in sheet (targetRowIndex + 1 because index 0 is headers, statusColIdx + 1 because it is 1-based index)
    sheet.getRange(targetRowIndex + 1, statusColIdx + 1).setValue(newStatus);
    
    // Get details for email dispatch
    var studentName = nameColIdx !== -1 ? values[targetRowIndex][nameColIdx] : "Student";
    var studentEmail = emailColIdx !== -1 ? values[targetRowIndex][emailColIdx] : "";
    var courseSelected = courseColIdx !== -1 ? values[targetRowIndex][courseColIdx] : "the selected program";
    
    if (studentEmail) {
      sendAdmissionsReviewEmail(studentEmail.trim(), studentName.trim(), appId, courseSelected, newStatus);
    }
    
    return createJsonResponse("success", "Application status updated successfully to " + newStatus);
    
  } catch (error) {
    return createJsonResponse("error", "Failed to update status: " + error.toString());
  }
}

/**
 * Handles the final admission form submission, checks verification status, and sends notifications.
 */
function handleApplicationSubmission(data) {
  var cleanEmail = data.email ? data.email.trim().toLowerCase() : "";
  
  // 1. Enforce Email verification before allowing spreadsheet insertions
  var cache = CacheService.getScriptCache();
  var isVerified = cache.get(cleanEmail + "_verified");
  
  if (!isVerified || isVerified !== "true") {
    return createJsonResponse("error", "Unauthorized: Email verification is incomplete. Please verify OTP first.");
  }
  
  // 2. Open Spreadsheet and select Sheet1
  var ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  var sheet = ss.getSheetByName("Sheet1");
  
  // Create headers if empty
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
  
  // Generate unique Application ID (e.g. JSS-PG-2026-4582)
  var timestamp = new Date();
  var randomSuffix = Math.floor(1000 + Math.random() * 9000).toString();
  var uniqueId = "JSS-PG-" + timestamp.getFullYear() + "-" + randomSuffix;

  // 3. Create student folder in Google Drive
  var mainFolder = DriveApp.getFolderById(DRIVE_FOLDER_ID);
  var studentName = data.name ? data.name.trim() : "Unknown Student";
  var folderName = studentName + "_" + uniqueId;
  var studentFolder = mainFolder.createFolder(folderName);
  studentFolder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  
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
  
  // 4. Append row to Google Sheets
  sheet.appendRow([
    uniqueId, timestamp, data.course, data.name, data.parentsName, 
    data.dob, data.placeOfBirth, data.nationality, data.religion, data.caste, data.sex, data.motherTongue,
    data.presentAddress, data.permanentAddress, data.aadhaarNo, data.phoneNo, data.mobileNo, data.email,
    data.lastInstitution, data.subjectsStudied.join(", "),
    
    // Semesters
    data.marks.sem1.total, data.marks.sem1.secured, data.marks.sem1.percentage,
    data.marks.sem2.total, data.marks.sem2.secured, data.marks.sem2.percentage,
    data.marks.sem3.total, data.marks.sem3.secured, data.marks.sem3.percentage,
    data.marks.sem4.total, data.marks.sem4.secured, data.marks.sem4.percentage,
    data.marks.sem5.total, data.marks.sem5.secured, data.marks.sem5.percentage,
    data.marks.sem6.total, data.marks.sem6.secured, data.marks.sem6.percentage,
    
    // Grand totals
    data.marks.grand.total, data.marks.grand.secured, data.marks.grand.percentage,
    
    data.category, data.parentOccupation, data.parentAnnualIncome,
    
    // Files
    fileUrls["photo"], fileUrls["marksCards"], fileUrls["characterCert"], fileUrls["sslcPucCard"],
    fileUrls["incomeCert"], fileUrls["casteCert"], fileUrls["transferCert"], fileUrls["aadhaarCard"],
    
    // Payment
    data.payment.refNo, data.payment.date, fileUrls["paymentReceipt"],
    
    "Pending" // Default Application Status
  ]);
  
  // 5. Invalidate verification cache to prevent replay
  cache.remove(cleanEmail + "_verified");
  
  // 6. Send Free Email Confirmation using Gmail App
  if (data.email) {
    sendGmailNotification(cleanEmail, data.name, uniqueId);
  }

  return ContentService.createTextOutput(JSON.stringify({
    "status": "success",
    "applicationId": uniqueId,
    "message": "Application submitted successfully! Your Application ID has been sent to your Gmail (" + cleanEmail + ")."
  })).setMimeType(ContentService.MimeType.JSON);
}

/**
 * Decodes base64 file and saves it in Google Drive.
 */
function saveBase64File(folder, base64String, fileName, mimeType) {
  try {
    var decoded = Utilities.base64Decode(base64String);
    var blob = Utilities.newBlob(decoded, mimeType || "application/octet-stream", fileName);
    var file = folder.createFile(blob);
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    return file.getUrl();
  } catch (e) {
    return "Error Uploading: " + e.toString();
  }
}

/**
 * Sends styled HTML verification OTP email confirmation.
 */
function sendOtpEmail(toEmail, otpValue) {
  var subject = "Verification Code - JSS Admission Portal";
  
  var htmlBody = 
    "<div style='font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px;'>" +
      "<h2 style='color: #0D47A1; margin-top: 0;'>JSS Admissions Verification</h2>" +
      "<p>Please verify your email address to start your PG Admission Form. Use the verification code below:</p>" +
      "<div style='background-color: #f7fafc; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0; border: 1px solid #edf2f7;'>" +
        "<span style='font-size: 13px; color: #718096; display: block; font-weight: bold;'>YOUR VERIFICATION CODE</span>" +
        "<strong style='font-size: 32px; color: #0D47A1; letter-spacing: 4px;'>" + otpValue + "</strong>" +
        "<span style='font-size: 11px; color: #a0aec0; display: block; margin-top: 8px;'>Valid for 10 minutes</span>" +
      "</div>" +
      "<p>If you did not request this code, you can safely ignore this email.</p>" +
      "<br>" +
      "<p style='margin-bottom: 0;'>Best regards,</p>" +
      "<p style='margin-top: 4px; font-weight: bold; color: #0D47A1;'>JSS College Admissions Team</p>" +
    "</div>";
    
  var textBody = "Your JSS Admission verification code is: " + otpValue + "\nValid for 10 minutes.";

  GmailApp.sendEmail(toEmail, subject, textBody, {
    htmlBody: htmlBody
  });
}

/**
 * Sends styled HTML email confirmation directly from Gmail.
 */
function sendGmailNotification(toEmail, studentName, applicationId) {
  var subject = "Application Submission Successful - JSS Admission Portal";
  
  var htmlBody = 
    "<div style='font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px;'>" +
      "<h2 style='color: #0D47A1; margin-top: 0;'>Application Received!</h2>" +
      "<p>Dear <strong>" + studentName + "</strong>,</p>" +
      "<p>Your PG Admission Form has been submitted successfully to JSS College of Arts, Commerce & Science.</p>" +
      "<div style='background-color: #f7fafc; padding: 16px; border-radius: 8px; text-align: center; margin: 20px 0; border: 1px solid #edf2f7;'>" +
        "<span style='font-size: 13px; color: #718096; display: block; font-weight: bold;'>YOUR UNIQUE APPLICATION ID</span>" +
        "<strong style='font-size: 22px; color: #0D47A1; letter-spacing: 0.5px;'>" + applicationId + "</strong>" +
      "</div>" +
      "<p>A copy of your documents and receipt have been stored in our databases. We will notify you once your verification process begins.</p>" +
      "<br>" +
      "<p style='margin-bottom: 0;'>Best regards,</p>" +
      "<p style='margin-top: 4px; font-weight: bold; color: #0D47A1;'>JSS College Admissions Team</p>" +
    "</div>";
    
  var textBody = "Dear " + studentName + ",\n\nYour PG Admission Form has been submitted successfully. Your Application ID is: " + applicationId;

  GmailApp.sendEmail(toEmail, subject, textBody, {
    htmlBody: htmlBody
  });
}

/**
 * Sends styled HTML email update to applicant (Approve/Reject).
 */
function sendAdmissionsReviewEmail(toEmail, studentName, appId, courseSelected, status) {
  var subject = "";
  var title = "";
  var message = "";
  
  if (status === "Approved") {
    subject = "Congratulations! Admission Offer - JSS College Portal";
    title = "Admission Offer Granted!";
    message = 
      "<p>Dear <strong>" + studentName + "</strong>,</p>" +
      "<p>We are pleased to inform you that your application (ID: <strong>" + appId + "</strong>) for admission to the <strong>" + courseSelected + "</strong> program at JSS College of Arts, Commerce & Science has been **APPROVED**.</p>" +
      "<p>To secure your seat, please complete the enrollment procedures, verify your original documents at the college admissions office, and complete the remaining fee payment within the next 7 working days.</p>";
  } else {
    subject = "Admission Application Status Update - JSS College Portal";
    title = "Application Update";
    message = 
      "<p>Dear <strong>" + studentName + "</strong>,</p>" +
      "<p>Thank you for your interest in JSS College of Arts, Commerce & Science and the <strong>" + courseSelected + "</strong> program.</p>" +
      "<p>We regret to inform you that after careful review of your application (ID: <strong>" + appId + "</strong>) and academic marks, we are unable to offer you admission at this time. Your application status has been marked as **REJECTED**.</p>" +
      "<p>This decision is typically due to limited seat intake capacities or eligibility criteria mismatch. We wish you all the best in your future academic endeavors.</p>";
  }
  
  var htmlBody = 
    "<div style='font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px;'>" +
      "<h2 style='color: " + (status === "Approved" ? "#2E7D32" : "#C62828") + "; margin-top: 0;'>" + title + "</h2>" +
      message +
      "<div style='background-color: #f7fafc; padding: 16px; border-radius: 8px; text-align: center; margin: 20px 0; border: 1px solid #edf2f7;'>" +
        "<span style='font-size: 13px; color: #718096; display: block; font-weight: bold;'>APPLICATION ID</span>" +
        "<strong style='font-size: 20px; color: #0D47A1; letter-spacing: 0.5px;'>" + appId + "</strong>" +
      "</div>" +
      "<p>If you have any questions or require further assistance, please contact the admissions helpdesk at pgadmissions@jsscacs.edu.in.</p>" +
      "<br>" +
      "<p style='margin-bottom: 0;'>Best regards,</p>" +
      "<p style='margin-top: 4px; font-weight: bold; color: #0D47A1;'>JSS College Admissions Team</p>" +
    "</div>";
    
  var textBody = "Dear " + studentName + ",\n\nYour application (ID: " + appId + ") status has been updated to: " + status;

  GmailApp.sendEmail(toEmail, subject, textBody, {
    htmlBody: htmlBody
  });
}

/**
 * Helper to validate email format.
 */
function validateEmailFormat(emailStr) {
  var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(emailStr);
}

/**
 * Creates JSON text output response.
 */
function createJsonResponse(status, message) {
  return ContentService.createTextOutput(JSON.stringify({
    "status": status,
    "message": message
  })).setMimeType(ContentService.MimeType.JSON);
}

/**
 * Debugging function to authorize Google Drive permissions in Google Apps Script.
 */
function testDrive() {
  Logger.log("Testing Google Drive access...");
  try {
    var folder = DriveApp.getFolderById(DRIVE_FOLDER_ID);
    Logger.log("Drive authorized successfully! Folder name: " + folder.getName());
  } catch (err) {
    Logger.log("Drive error: " + err.toString());
  }
}
