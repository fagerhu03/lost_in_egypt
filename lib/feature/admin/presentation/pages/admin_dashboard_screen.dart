import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/admin_guide_cubit.dart';
import 'admin_guide_approval_screen.dart';
import 'admin_language_requests_screen.dart';
import 'admin_reports_screen.dart';
import '../../domain/usecases/admin_usecases.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.verified_user, size: 32),
            title: const Text('Guide Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            leading: const Icon(Icons.language, size: 32),
            title: const Text('Language Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            leading: const Icon(Icons.report, size: 32),
            title: const Text('Reported Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: const Text('Manage reported users and community posts.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AdminReportsScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }
}
