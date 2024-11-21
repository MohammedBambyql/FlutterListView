import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';

void main() {
  runApp(EmployeeApp());
}

class EmployeeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: EmployeeHomePage(),
    );
  }
}

class Employee {
  Uint8List? image;
  String name;
  String email;

  Employee({required this.image, required this.name, required this.email});
}

class EmployeeHomePage extends StatefulWidget {
  @override
  _EmployeeHomePageState createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  final List<Employee> employees = [];
  final List<Employee> filteredEmployees = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredEmployees.addAll(employees);
    searchController.addListener(_filterEmployees);
  }

  void _filterEmployees() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredEmployees.clear();
        filteredEmployees.addAll(employees);
      } else {
        filteredEmployees.clear();
        filteredEmployees.addAll(employees.where((employee) {
          return employee.name.toLowerCase().contains(query);
        }));
      }
    });
  }

  Future<void> _navigateToFormPage({Employee? employee, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeFormPage(
          employee: employee,
        ),
      ),
    );

    if (result != null && result is Employee) {
      setState(() {
        if (index == null) {
          employees.add(result);
        } else {
          employees[index] = result;
        }
        _filterEmployees();
      });
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                employees.removeAt(index);
                _filterEmployees();
              });
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Manager'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _navigateToFormPage(),
                  child: Text('Add Employee'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEmployees.length,
              itemBuilder: (context, index) {
                final employee = filteredEmployees[index];
                return Container(
                  color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                  child: ListTile(
                    leading: employee.image != null
                        ? Image.memory(employee.image!, width: 50, height: 50)
                        : null,
                    title: Text(employee.name),
                    subtitle: Text(employee.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _navigateToFormPage(
                            employee: employee,
                            index: index,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _confirmDelete(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeFormPage extends StatefulWidget {
  final Employee? employee;

  EmployeeFormPage({this.employee});

  @override
  _EmployeeFormPageState createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  Uint8List? imageBytes;
  String name = '';
  String email = '';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      imageBytes = widget.employee!.image;
      name = widget.employee!.name;
      email = widget.employee!.email;
    }
  }

  Future<void> _pickImage() async {
    final completer = Completer<Uint8List>();
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      final file = input.files!.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        completer.complete(reader.result as Uint8List);
      });
    });

    final imageBytesResult = await completer.future;
    setState(() {
      imageBytes = imageBytesResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (imageBytes != null)
                Image.memory(imageBytes!, width: 100, height: 100),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
                onChanged: (value) => name = value,
              ),
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email cannot be empty';
                  }
                  return null;
                },
                onChanged: (value) => email = value,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && imageBytes != null) {
                    Navigator.pop(
                      context,
                      Employee(image: imageBytes, name: name, email: email),
                    );
                  }
                },
                child: Text(widget.employee == null ? 'Add' : 'Update'),
              ),
              if (imageBytes == null)
                Text('Image is required', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
