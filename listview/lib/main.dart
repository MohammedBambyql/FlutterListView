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

  Future<void> _pickImage(Function(Uint8List?) onImagePicked) async {
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

    final imageBytes = await completer.future;
    onImagePicked(imageBytes);
  }

  Future<void> _showAddEmployeeForm([int? index]) async {
    Uint8List? imageBytes = index != null ? employees[index].image : null;
    String name = index != null ? employees[index].name : '';
    String email = index != null ? employees[index].email : '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(index == null ? 'Add Employee' : 'Edit Employee'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageBytes != null)
                    Image.memory(imageBytes!, width: 100, height: 100),
                  ElevatedButton(
                    onPressed: () async {
                      await _pickImage((pickedImage) {
                        setDialogState(() {
                          imageBytes = pickedImage;
                        });
                      });
                    },
                    child: Text('Pick Image'),
                  ),
                  TextField(
                    onChanged: (value) => name = value,
                    controller: TextEditingController(text: name),
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    onChanged: (value) => email = value,
                    controller: TextEditingController(text: email),
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (name.isNotEmpty &&
                        email.isNotEmpty &&
                        imageBytes != null) {
                      setState(() {
                        if (index == null) {
                          employees.add(Employee(
                              image: imageBytes, name: name, email: email));
                        } else {
                          employees[index] = Employee(
                              image: imageBytes, name: name, email: email);
                        }
                        _filterEmployees(); // تحديث قائمة البحث
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(index == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Manager'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                  onPressed: () => _showAddEmployeeForm(),
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
                return ListTile(
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
                        onPressed: () => _showAddEmployeeForm(index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            employees.removeAt(index);
                            _filterEmployees(); // تحديث القائمة بعد الحذف
                          });
                        },
                      ),
                    ],
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
