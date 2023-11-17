import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'timesheet_model.dart';
import 'edit_timesheet.dart'; // Import the edit dialog

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timesheet App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TimesheetPage(),
    );
  }
}

class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(id: doc.id, name: doc['name']);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class TimesheetPage extends StatefulWidget {
  @override
  _TimesheetPageState createState() => _TimesheetPageState();
}

class _TimesheetPageState extends State<TimesheetPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Timesheet> timesheets = [];
  List<Timesheet> displayedTimesheets = [];
  List<User> users = [];
  User? selectedUser;

  TextEditingController searchController = TextEditingController();

  void _editTimesheet(Timesheet timesheet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String updatedProjectName = timesheet.projectName; // Initialize with current value
        String updatedTask = timesheet.task; // Initialize with current value
        String updatedDateFrom = timesheet.dateFrom; // Initialize with current value
        String updatedDateTo = timesheet.dateTo; // Initialize with current value
        String updatedStatus = timesheet.status; // Initialize with current value
        String updatedAssignTo = timesheet.assignedTo; // Initialize with current value

        return AlertDialog(
          title: Text('Edit Timesheet'),
          content: SingleChildScrollView(
            child: Form(
              child: Column(
                children: [
                  TextFormField(
                    initialValue: timesheet.projectName,
                    decoration: InputDecoration(labelText: 'Project'),
                    onChanged: (value) {
                      updatedProjectName = value;
                    },
                  ),
                  TextFormField(
                    initialValue: timesheet.task,
                    decoration: InputDecoration(labelText: 'Task'),
                    onChanged: (value) {
                      updatedTask = value;
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: timesheet.dateFrom,
                          decoration: InputDecoration(labelText: 'Date From'),
                          onChanged: (value) {
                            updatedDateFrom = value;
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: timesheet.dateTo,
                          decoration: InputDecoration(labelText: 'Date To'),
                          onChanged: (value) {
                            updatedDateTo = value;
                          },
                        ),
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: updatedStatus,
                    onChanged: (value) {
                      setState(() {
                        updatedStatus = value!;
                      });
                    },
                    items: ['Open', 'In Progress', 'Closed'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  TextFormField(
                    initialValue: timesheet.assignedTo,
                    decoration: InputDecoration(labelText: 'Assign To'),
                    onChanged: (value) {
                      updatedAssignTo = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                // Perform update in Firestore
                await _updateTimesheet(
                  timesheet.id,
                  updatedProjectName,
                  updatedTask,
                  // Add other fields as needed
                );
                Navigator.of(context).pop(); // Close the dialog
                _fetchTimesheets(); // Refresh timesheets after updating
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTimesheet(
      String timesheetId,
      String updatedProjectName,
      String updatedTask,
      // Add other fields as needed
      ) async {
    try {
      await _firestore.collection('timesheets').doc(timesheetId).update({
        'projectName': updatedProjectName,
        'task': updatedTask,
        // Update other fields as needed
      });
    } catch (e) {
      print('Error updating timesheet: $e');
    }
  }

  void _deleteTimesheet(String timesheetId) async {
    try {
      await _firestore.collection('timesheets').doc(timesheetId).delete();
      _fetchTimesheets(); // Refresh timesheets after deleting
    } catch (e) {
      print('Error deleting timesheet: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTimesheets();
    _fetchUsers();
  }

  void _fetchTimesheets() async {
    try {
      QuerySnapshot querySnapshot =
      await _firestore.collection('timesheets').get();
      setState(() {
        timesheets = querySnapshot.docs
            .map((doc) => _timesheetFromDocument(doc))
            .toList();
        displayedTimesheets = List.from(timesheets);
      });
    } catch (e) {
      print('Error fetching timesheets: $e');
    }
  }

  Timesheet _timesheetFromDocument(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    return Timesheet(
      id: doc.id,
      projectName: data?['projectName'] ?? '',
      task: data?['task'] ?? '',
      dateFrom: data?['dateFrom'] ?? '',
      dateTo: data?['dateTo'] ?? '',
      status: data?['status'] ?? '',
      assignedTo: data?['assignedTo'] ?? '',
    );
  }

  Future<List<User>> _fetchUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      List<User> userList = querySnapshot.docs
          .map((doc) => User(
        id: doc.id,
        name: doc['name'],
      ))
          .toList();
      setState(() {
        users = userList;
      });
      return userList;
    } catch (e) {
      print('Error fetching users: $e');
      // Return an empty list or handle the error according to your needs
      return [];
    }
  }

  void _filterTimesheets(String query) {
    if (query.isEmpty) {
      setState(() {
        displayedTimesheets = List.from(timesheets);
      });
    } else {
      setState(() {
        displayedTimesheets = timesheets
            .where((timesheet) =>
        (timesheet.projectName != null &&
            timesheet.projectName!
                .toLowerCase()
                .contains(query.toLowerCase())) ||
            (timesheet.task != null &&
                timesheet.task!
                    .toLowerCase()
                    .contains(query.toLowerCase())) ||
            (timesheet.assignedTo != null &&
                timesheet.assignedTo!
                    .toLowerCase()
                    .contains(query.toLowerCase())) ||
            (timesheet.status != null &&
                timesheet.status!
                    .toLowerCase()
                    .contains(query.toLowerCase())))
            .toList();
      });
    }
  }

  void _showAddTimesheetDialog() async {
    List<User> users = await _fetchUsers();

    String projectName = '';
    String task = '';
    String dateFrom = '';
    String dateTo = '';
    String status = 'Open';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Timesheet'),
          content: SingleChildScrollView(
            child: Form(
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Project'),
                    onChanged: (value) {
                      projectName = value;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Task'),
                    onChanged: (value) {
                      task = value;
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: 'Date From'),
                          onChanged: (value) {
                            dateFrom = value;
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: 'Date To'),
                          onChanged: (value) {
                            dateTo = value;
                          },
                        ),
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: status,
                    onChanged: (value) {
                      setState(() {
                        status = value!;
                      });
                    },
                    items:
                    ['Open', 'In Progress', 'Closed'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  DropdownButton<User>(
                    value: selectedUser,
                    onChanged: (User? value) {
                      setState(() {
                        selectedUser = value;
                      });
                    },
                    items: users.map((User user) {
                      return DropdownMenuItem<User>(
                        value: user,
                        child: Text(user.name),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_validateForm()) {
                  await _addTimesheetToDatabase(
                    projectName,
                    task,
                    dateFrom,
                    dateTo,
                    status,
                    selectedUser?.name ?? '',
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  bool _validateForm() {
    // Implement your validation logic here
    // Return true if the form is valid, otherwise false
    return true;
  }

  Future<void> _addTimesheetToDatabase(
      String projectName,
      String task,
      String dateFrom,
      String dateTo,
      String status,
      String assignTo,
      ) async {
    try {
      await _firestore.collection('timesheets').add({
        'projectName': projectName,
        'task': task,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
        'status': status,
        'assignTo': assignTo,
      });
      _fetchTimesheets(); // Refresh timesheets after adding a new one
    } catch (e) {
      print('Error adding timesheet: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timesheet Entries'),
      ),
      body: Column(
        children: <Widget>[
          // Rectangular search box with buttons
          Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: _filterTimesheets,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Search Task',
                  ),
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _filterTimesheets(searchController.text);
                      },
                      child: Text('Search'),
                    ),
                    ElevatedButton(
                      onPressed: _showAddTimesheetDialog,
                      child: Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List of timesheets
          Expanded(
            child: ListView.builder(
              itemCount: displayedTimesheets.length,
              itemBuilder: (context, index) {
                Timesheet timesheet = displayedTimesheets[index];

                return ListTile(
                  title: Text('Project: ${timesheet.projectName ?? ''}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Task: ${timesheet.task ?? ''}'),
                      Text('Assigned To: ${timesheet.assignedTo ?? ''}'),
                      Text('From: ${timesheet.dateFrom ?? ''}'),
                      Text('To: ${timesheet.dateTo ?? ''}'),
                      Text('Status: ${timesheet.status ?? ''}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // Implement the edit functionality here
                          _editTimesheet(timesheet);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Implement the delete functionality here
                          _deleteTimesheet(timesheet.id);
                        },
                      ),
                    ],
                  ),
                  // Add onTap function to navigate to timesheet details page
                  onTap: () {
                    // Implement navigation to timesheet details page
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}