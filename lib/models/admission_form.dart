
class SemesterMarks {
  double total;
  double secured;
  double percentage;

  SemesterMarks({
    this.total = 0.0,
    this.secured = 0.0,
    this.percentage = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'total': total,
        'secured': secured,
        'percentage': percentage,
      };
}

class AcademicMarks {
  SemesterMarks sem1;
  SemesterMarks sem2;
  SemesterMarks sem3;
  SemesterMarks sem4;
  SemesterMarks sem5;
  SemesterMarks sem6;
  SemesterMarks grand;

  AcademicMarks({
    SemesterMarks? sem1,
    SemesterMarks? sem2,
    SemesterMarks? sem3,
    SemesterMarks? sem4,
    SemesterMarks? sem5,
    SemesterMarks? sem6,
    SemesterMarks? grand,
  })  : sem1 = sem1 ?? SemesterMarks(),
        sem2 = sem2 ?? SemesterMarks(),
        sem3 = sem3 ?? SemesterMarks(),
        sem4 = sem4 ?? SemesterMarks(),
        sem5 = sem5 ?? SemesterMarks(),
        sem6 = sem6 ?? SemesterMarks(),
        grand = grand ?? SemesterMarks();

  Map<String, dynamic> toJson() => {
        'sem1': sem1.toJson(),
        'sem2': sem2.toJson(),
        'sem3': sem3.toJson(),
        'sem4': sem4.toJson(),
        'sem5': sem5.toJson(),
        'sem6': sem6.toJson(),
        'grand': grand.toJson(),
      };
}

class FormFile {
  String? base64;
  String? fileName;
  String? mimeType;

  FormFile({this.base64, this.fileName, this.mimeType});

  Map<String, dynamic> toJson() => {
        'base64': base64 ?? '',
        'fileName': fileName ?? '',
        'mimeType': mimeType ?? '',
      };

  bool get isUploaded => base64 != null && base64!.isNotEmpty;
}

class PaymentDetails {
  String refNo;
  String date;
  FormFile receipt;

  PaymentDetails({
    this.refNo = '',
    this.date = '',
    FormFile? receipt,
  }) : receipt = receipt ?? FormFile();

  Map<String, dynamic> toJson() => {
        'refNo': refNo,
        'date': date,
        // The receipt itself is uploaded as a base64 string in the files block in our Apps Script payload
      };
}

class AdmissionFormModel {
  String course;
  String name;
  String parentsName; // Father & Mother Name
  String dob;
  String placeOfBirth;
  String nationality;
  String religion;
  String caste;
  String sex;
  String motherTongue;
  String presentAddress;
  String permanentAddress;
  String aadhaarNo;
  String phoneNo;
  String mobileNo;
  String email;
  String lastInstitution;
  List<String> subjectsStudied;
  AcademicMarks marks;
  String category;
  String parentOccupation;
  String parentAnnualIncome;
  
  // Files map for simple looping and JSON payload organization
  Map<String, FormFile> files;
  
  PaymentDetails payment;

  AdmissionFormModel({
    this.course = 'MCA',
    this.name = '',
    this.parentsName = '',
    this.dob = '',
    this.placeOfBirth = '',
    this.nationality = 'Indian',
    this.religion = '',
    this.caste = '',
    this.sex = 'Male',
    this.motherTongue = '',
    this.presentAddress = '',
    this.permanentAddress = '',
    this.aadhaarNo = '',
    this.phoneNo = '',
    this.mobileNo = '',
    this.email = '',
    this.lastInstitution = '',
    List<String>? subjectsStudied,
    AcademicMarks? marks,
    this.category = 'GM',
    this.parentOccupation = '',
    this.parentAnnualIncome = '',
    Map<String, FormFile>? files,
    PaymentDetails? payment,
  })  : subjectsStudied = subjectsStudied ?? List.filled(6, ''),
        marks = marks ?? AcademicMarks(),
        files = files ?? {
          'photo': FormFile(),
          'marksCards': FormFile(),
          'characterCert': FormFile(),
          'sslcPucCard': FormFile(),
          'incomeCert': FormFile(),
          'casteCert': FormFile(),
          'transferCert': FormFile(),
          'aadhaarCard': FormFile(),
          'paymentReceipt': FormFile(),
        },
        payment = payment ?? PaymentDetails();

  Map<String, dynamic> toJson() => {
        'course': course,
        'name': name,
        'parentsName': parentsName,
        'dob': dob,
        'placeOfBirth': placeOfBirth,
        'nationality': nationality,
        'religion': religion,
        'caste': caste,
        'sex': sex,
        'motherTongue': motherTongue,
        'presentAddress': presentAddress,
        'permanentAddress': permanentAddress,
        'aadhaarNo': aadhaarNo,
        'phoneNo': phoneNo,
        'mobileNo': mobileNo,
        'email': email,
        'lastInstitution': lastInstitution,
        'subjectsStudied': subjectsStudied.where((s) => s.isNotEmpty).toList(),
        'marks': marks.toJson(),
        'category': category,
        'parentOccupation': parentOccupation,
        'parentAnnualIncome': parentAnnualIncome,
        'files': {
          'photo': files['photo']?.toJson(),
          'marksCards': files['marksCards']?.toJson(),
          'characterCert': files['characterCert']?.toJson(),
          'sslcPucCard': files['sslcPucCard']?.toJson(),
          'incomeCert': files['incomeCert']?.toJson(),
          'casteCert': files['casteCert']?.toJson(),
          'transferCert': files['transferCert']?.toJson(),
          'aadhaarCard': files['aadhaarCard']?.toJson(),
          'paymentReceipt': files['paymentReceipt']?.toJson(),
        },
        'payment': payment.toJson(),
      };
}
