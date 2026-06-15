import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/admin_guide_cubit.dart';
import '../bloc/admin_guide_state.dart';
import 'admin_guide_details_screen.dart';

class AdminGuideApprovalScreen extends StatefulWidget {
  const AdminGuideApprovalScreen({super.key});

  @override
  State<AdminGuideApprovalScreen> createState() => _AdminGuideApprovalScreenState();
}

class _AdminGuideApprovalScreenState extends State<AdminGuideApprovalScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminGuideCubit>().fetchPendingGuides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Guide Applications')),
      body: BlocConsumer<AdminGuideCubit, AdminGuideState>(
        listener: (context, state) {
          if (state is AdminGuideError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AdminGuideActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.actionMessage)));
          }
        },
        builder: (context, state) {
          if (state is AdminGuideLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AdminGuideLoaded) {
            final guides = state.pendingGuides;
            if (guides.isEmpty) {
              return const Center(child: Text('No pending applications.'));
            }
            return ListView.builder(
              itemCount: guides.length,
              itemBuilder: (context, index) {
                final guide = guides[index];
                return Card(
                  margin: EdgeInsets.all(8.r),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF714611),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('${guide.firstName} ${guide.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${guide.email}\nMOTA: ${guide.motaLicenseNumber}'),
                    isThreeLine: true,
                    trailing: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(guide.id).get(),
                      builder: (context, snap) {
                        final screening = (snap.data?.data() as Map<String, dynamic>?)?['aiScreeningResult'] as Map<String, dynamic>?;
                        final flagged = screening?['flagged'] == true;
                        final risk = screening?['risk'] as String? ?? 'low';
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (flagged)
                              Container(
                                margin: EdgeInsetsDirectional.only(end: 6.w),
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: risk == 'high' ? Colors.red.shade600 : Colors.orange.shade600,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  risk == 'high' ? '⚠ High Risk' : '⚠ Review',
                                  style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700),
                                ),
                              ),
                            const Icon(Icons.chevron_right),
                          ],
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminGuideDetailsScreen(
                            applicant: guide,
                            onApprove: (acceptedGuide) {
                              if (acceptedGuide.emailVerified) {
                                context.read<AdminGuideCubit>().approveGuide(acceptedGuide.id);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cannot approve: Guide has not verified their email.')),
                                );
                              }
                            },
                            onReject: (rejectedGuide) {
                              final reasonController = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Reject Application'),
                                    content: TextField(
                                      controller: reasonController,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter reason for rejection...',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 3,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () {
                                          if (reasonController.text.trim().isNotEmpty) {
                                            Navigator.pop(dialogContext);
                                            context.read<AdminGuideCubit>().rejectGuide(rejectedGuide.id, reasonController.text.trim());
                                          }
                                        },
                                        child: const Text('Confirm Reject', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
