import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/leave_request/providers/leave_request_provider.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/general_text_field.dart';
import 'package:provider/provider.dart';

// add leave request screen
class AddLeaveRequest {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      builder: (context) => const AddLeaveRequestWidget(),
    );
  }
}

class AddLeaveRequestWidget extends StatefulWidget {
  const AddLeaveRequestWidget({super.key});

  @override
  State<AddLeaveRequestWidget> createState() => AddLeaveRequestWidgetState();
}

class AddLeaveRequestWidgetState extends State<AddLeaveRequestWidget> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _startDate = DateTime.now();
  late DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_formKey.currentState!.validate()) {
      final provider =
          Provider.of<LeaveRequestProvider>(context, listen: false);
      await provider.requestLeave(
        context: context,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text,
      );
      //
      provider.getLeaveRequest();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
      child: SingleChildScrollView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Leave Request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              // Start and End Date in a row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: DateContainerWidget(
                            label: 'Start Date', date: _startDate)),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: DateContainerWidget(
                          label: 'End Date', date: _endDate),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              // Reason
              GeneralTextField(
                textInputType: TextInputType.text,
                textInputAction: TextInputAction.done,
                controller: _reasonController,
                labelText: 'Reason for Leave',
                maxLines: 4,
                validate: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8.h),

              // Submit Button
              GeneralElevatedButton(
                onPressed: _submitLeaveRequest,
                title: 'Submit Leave Request',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DateContainerWidget extends StatelessWidget {
  const DateContainerWidget({
    super.key,
    required this.label,
    required this.date,
  });

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
              Text(date.toString().split(' ')[0]),
            ],
          ),
          const Icon(Icons.calendar_today, size: 20),
        ],
      ),
    );
  }
}
