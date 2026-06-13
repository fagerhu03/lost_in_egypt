import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/admin_guide_cubit.dart';
import 'admin_guide_approval_screen.dart';
import 'admin_language_requests_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_events_screen.dart';
import '../../domain/usecases/admin_usecases.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          ListTile(
            leading: Icon(Icons.verified_user, size: 32.r),
            title: Text('Guide Applications', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            subtitle: const Text('Review and approve or reject guide applications.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => AdminGuideCubit(
                    getPendingGuidesUseCase: GetIt.I<GetPendingGuidesUseCase>(),
                    approveGuideUseCase: GetIt.I<ApproveGuideUseCase>(),
                    rejectGuideUseCase: GetIt.I<RejectGuideUseCase>(),
                  ),
                  child: const AdminGuideApprovalScreen(),
                ),
              ));
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.language, size: 32.r),
            title: Text('Language Requests', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            subtitle: const Text('Review language verification requests from guides.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AdminLanguageRequestsScreen(),
              ));
            },
          ),
          const Divider(),
          // Placeholder for other admin tools
          ListTile(
            leading: Icon(Icons.report, size: 32.r),
            title: Text('Reported Content', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            subtitle: const Text('Manage reported users and community posts.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AdminReportsScreen(),
              ));
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.event, size: 32.r),
            title: Text('Manage Events', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            subtitle: const Text('Create, edit, and delete events for the app.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AdminEventsScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }
}
