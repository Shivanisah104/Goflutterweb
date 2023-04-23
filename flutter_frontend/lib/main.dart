import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registration Form',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _dob;
  String? _fileName;
  
  Uint8List? _fileBytes;
  String? _phoneNumber;

  
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a name';
    }
    return null;
  }

  
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  
  Future<void> _openFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );
    if (result != null) {
      final file = result.files.single;
      if (file.extension == 'pdf' || file.extension == 'docx') {
        setState(() {
          _fileName = file.name;
          _fileBytes = file.bytes;
        });
      } else {
       
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Invalid File'),
            content: Text('Please select a PDF or DOCX file.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      
    }
  }
  
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final firstName = _firstNameController.text;
      final lastName = _lastNameController.text;
      final email = _emailController.text;

      final minimumDob = DateTime.now().subtract(Duration(days: 18 * 365));

      if (_dob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a date of birth')),
        );
        return;
      } else if (_dob!.isAfter(minimumDob)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be at least 18 years old')),
        );
        return;
      }
      if (_fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload a CV')),
        );
        return;
      }
      
      final response = true;
      await http.post(
        Uri.parse(
            'https://one1ytfug.onrender.com/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': _phoneNumber,
          'dob': DateFormat('yyyy-MM-dd').format(_dob!),
          'email': email,
          
          'cv': base64Encode(_fileBytes!),
          'filename': _fileName,
        }),
      );
      if (response) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Registration Successful'),
            content: Text(
                'Hi $firstName, Your registration was successful. Thank you!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _firstNameController.clear();
                  _lastNameController.clear();
                  _emailController.clear();
                  setState(() {
                    _dob = null;
                    _fileName = null;
                    _fileBytes = null;
                    _phoneNumber = null;
                  });
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      setState(() {
        _dob = selectedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration Form',       style: TextStyle(
      fontFamily: 'Lato', // Replace with your desired font family
      fontWeight: FontWeight.bold,
      fontSize: 20.0,
    ),
),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'Enter your First Name',
                  labelStyle: TextStyle(
                    fontSize: 18.0,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                  validator: _validateName,
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                  labelText: 'Enter your Last Name',
                  labelStyle: TextStyle(
                    fontSize: 18.0,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                  validator: _validateName,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                  labelText: 'Enter your email',
                  labelStyle: TextStyle(
                    fontSize: 18.0,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                  validator: _validateEmail,
                ),
                TextFormField(
                  decoration: InputDecoration(
                  labelText: 'Enter your phone number',
                  labelStyle: TextStyle(
                    fontSize: 18.0,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^\+?\d{9,15}$').hasMatch(value!)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                  onSaved: (value) => _phoneNumber = value,
                ),
                SizedBox(height: 16.0),
                Text('Date of Birth'),
                SizedBox(height: 8.0),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dob == null
                              ? 'Select a date'
                              : DateFormat('yyyy-MM-dd').format(_dob!),
                        ),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Text('Upload CV'),
                SizedBox(height: 8.0),
                GestureDetector(
                  onTap: _openFilePicker,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fileName ?? 'No file selected',
                        ),
                        Icon(Icons.file_upload),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}