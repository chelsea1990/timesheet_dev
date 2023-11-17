import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTimesheetDialog extends StatefulWidget {
  final String projectId;
  final Function onProjectUpdated;

  EditTimesheetDialog({required this.projectId, required this.onProjectUpdated});

  @override
  _EditTimesheetDialogState createState() => _EditTimesheetDialogState();
}

class _EditTimesheetDialogState extends State<EditTimesheetDialog> {
  TextEditingController projectNameController = TextEditingController();
  TextEditingController taskController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController dateFromController = TextEditingController();
  TextEditingController dateToController = TextEditingController();
  TextEditingController assignedToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProjectDetails();
  }

  void _fetchProjectDetails() async {
    try {
      DocumentSnapshot projectSnapshot =
      await FirebaseFirestore.instance.collection('timesheets').doc(widget.projectId).get();

      Map<String, dynamic>? data = projectSnapshot.data() as Map<String, dynamic>?;

      setState(() {
        projectNameController.text = data?['projectName'] ?? '';
        taskController.text = data?['task'] ?? '';
        statusController.text = data?['status'] ?? '';
        dateFromController.text = data?['dateFrom'] ?? '';
        dateToController.text = data?['dateTo'] ?? '';
        assignedToController.text = data?['assignedTo'] ?? '';
      });
    } catch (e) {
      print('Error fetching project details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Timesheet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: projectNameController,
              decoration: InputDecoration(labelText: 'Project Name'),
            ),
            TextFormField(
              controller: taskController,
              decoration: InputDecoration(labelText: 'Task'),
            ),
            TextFormField(
              controller: statusController,
              decoration: InputDecoration(labelText: 'Status'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: dateFromController,
                    decoration: InputDecoration(labelText: 'Date From'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: dateToController,
                    decoration: InputDecoration(labelText: 'Date To'),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: assignedToController,
              decoration: InputDecoration(labelText: 'Assigned To'),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            await _updateProject();
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _updateProject() async {
    try {
      await FirebaseFirestore.instance
          .collection('timesheets')
          .doc(widget.projectId)
          .update({
        'projectName': projectNameController.text,
        'task': taskController.text,
        'status': statusController.text,
        'dateFrom': dateFromController.text,
        'dateTo': dateToController.text,
        'assignedTo': assignedToController.text,
      });

      widget.onProjectUpdated();
    } catch (e) {
      print('Error updating project: $e');
    }
  }
}