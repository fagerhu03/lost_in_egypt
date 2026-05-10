import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../data/models/report_model.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/error_handler.dart';

// Imports for Deep Linking context
import '../../../home/tabs/community/presentation/post_detail_screen.dart';
import '../../../home/tabs/community/domain/entities/community_post.dart';
import '../../../home/tabs/community/data/model/community_post_model.dart';
import '../../../tours/presentation/pages/tour_detail_screen.dart';
import '../../../tours/domain/entities/tour_entity.dart';
import '../../../tours/data/models/tour_model.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';
import '../../../auth/data/models/user.dart';
import '../../../tours/presentation/bloc/guide_tours_cubit.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> with SingleTickerProviderStateMixin {
  late final ReportsRepository _repository;
  late final TabController _tabController;

  List<ReportModel> _allReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = GetIt.I<ReportsRepository>();
    _tabController = TabController(length: 4, vsync: this);
    _fetchReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _repository.getReports(status: 'pending');
      setState(() {
        _allReports = reports;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleGenericError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _dismissReport(ReportModel report) async {
    try {
      await _repository.updateReportStatus(report.id, 'dismissed');
      _fetchReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report dismissed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleGenericError(e))),
        );
      }
    }
  }

  void _deleteContent(ReportModel report) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Flagged Content?'),
        content: const Text('This will permanently delete the post, comment, or tour. The associated user will not be notified by default.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _repository.deleteReportedContent(report);
                await _repository.updateReportStatus(report.id, 'resolved');
                _fetchReports();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Content deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ErrorHandler.handleGenericError(e))),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _banUser(String userId, ReportModel report) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': 'banned',
        'isDisabled': true,
      });
      await _repository.updateReportStatus(report.id, 'resolved');
      _fetchReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User banned successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleGenericError(e))));
      }
    }
  }

  void _showReportDetails(ReportModel report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report Details: ${report.reportedItemType.name.toUpperCase()}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Report Context:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Reason: ${report.reason}'),
                Text('Description: ${report.description?.isEmpty ?? true ? 'None' : report.description!}'),
                const Divider(height: 24),
                const Text('Reported Content Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                FutureBuilder<DocumentSnapshot>(
                  future: _fetchReportedContentDoc(report),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                      return const Text('Content not found. It may have been deleted.', style: TextStyle(color: Colors.red));
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContentSnippet(report, data),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Go to Content'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _navigateToContent(report, snapshot.data!);
                          },
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 24),
                // Reporter meta
                Text('Reporter ID: ${report.reporterId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text('Target ID: ${report.reportedItemId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (report.reportedItemOwnerId != null)
                  Text('Owner ID: ${report.reportedItemOwnerId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (report.reportedItemType == ReportType.user || report.reportedItemType == ReportType.guide)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _banUser(report.reportedItemId, report);
              },
              child: const Text('Disable/Ban User'),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _deleteContent(report);
              },
              child: const Text('Delete Content'),
            ),
        ],
      ),
    );
  }

  Future<DocumentSnapshot> _fetchReportedContentDoc(ReportModel report) async {
    final db = FirebaseFirestore.instance;
    switch (report.reportedItemType) {
      case ReportType.post:
        return db.collection('community_posts').doc(report.reportedItemId).get();
      case ReportType.tour:
        return db.collection('tours').doc(report.reportedItemId).get();
      case ReportType.user:
      case ReportType.guide:
        return db.collection('users').doc(report.reportedItemId).get();
      case ReportType.comment:
        final parts = report.reportedItemId.split('_');
        if (parts.length >= 2) {
          final postId = parts[0];
          final commentId = parts.sublist(1).join('_');
          return db.collection('community_posts').doc(postId).collection('comments').doc(commentId).get();
        }
        throw Exception('Invalid comment ID format');
    }
  }

  Widget _buildContentSnippet(ReportModel report, Map<String, dynamic> data) {
    switch (report.reportedItemType) {
      case ReportType.post:
        return Text('"${data['content']}"\n\n- ${data['userName']}', style: const TextStyle(fontStyle: FontStyle.italic));
      case ReportType.tour:
        return Text('Tour: ${data['title']}\nLocation: ${data['meetingLocationName']}', style: const TextStyle(fontWeight: FontWeight.w500));
      case ReportType.user:
      case ReportType.guide:
        return Row(
          children: [
            CircleAvatar(
              child: data['profileImageUrl']?.isNotEmpty == true
                  ? ClipOval(child: CachedNetworkImage(imageUrl: data['profileImageUrl'], width: 40, height: 40, fit: BoxFit.cover, errorWidget: (_, _, _) => const Icon(Icons.person)))
                  : const Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('${data['firstName']} ${data['lastName']}\nRole: ${data['role']}')),
          ],
        );
      case ReportType.comment:
        return Text('"${data['text']}"\n\n- ${data['userName']}', style: const TextStyle(fontStyle: FontStyle.italic));
    }
  }

  void _navigateToContent(ReportModel report, DocumentSnapshot snapshot) {
    switch (report.reportedItemType) {
      case ReportType.post:
        final post = CommunityPostModel.fromSnapshot(snapshot);
        Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
        break;
      case ReportType.tour:
        final tour = TourModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        Navigator.push(context, MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)));
        break;
      case ReportType.user:
      case ReportType.guide:
        final u = UserModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        if (u.isVerifiedGuide) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(create: (_) => GuideToursCubit(getGuideToursUseCase: GetIt.I()), child: UniversalProfileScreen(user: u)),
            ),
          );
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: u)));
        }
        break;
      case ReportType.comment:
        final parts = report.reportedItemId.split('_');
        if (parts.length >= 2) {
          final postId = parts[0];
          final commentId = parts.sublist(1).join('_');
          FirebaseFirestore.instance.collection('community_posts').doc(postId).get().then((postDoc) {
             if (postDoc.exists && mounted) {
               final post = CommunityPostModel.fromSnapshot(postDoc);
               Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post, highlightCommentId: commentId)));
             }
          });
        }
        break;
    }
  }

  Widget _buildList(ReportType type1, [ReportType? type2]) {
    final filtered = _allReports.where((r) => r.reportedItemType == type1 || (type2 != null && r.reportedItemType == type2)).toList();

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (filtered.isEmpty) return const Center(child: Text('No pending reports in this category.'));

    return RefreshIndicator(
      onRefresh: _fetchReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final report = filtered[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColorForType(report.reportedItemType).withOpacity(0.2),
                child: Icon(_getIconForType(report.reportedItemType), color: _getColorForType(report.reportedItemType)),
              ),
              title: Text(report.reason, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${report.reportedItemType.name.toUpperCase()} • ${DateFormat('MMM d, h:mm a').format(report.timestamp)}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'view') _showReportDetails(report);
                  if (val == 'dismiss') _dismissReport(report);
                  if (val == 'delete') _deleteContent(report);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                  const PopupMenuItem(value: 'dismiss', child: Text('Dismiss Report')),
                  if (report.reportedItemType != ReportType.user && report.reportedItemType != ReportType.guide)
                    const PopupMenuItem(value: 'delete', child: Text('Delete Content', style: TextStyle(color: Colors.red))),
                ],
              ),
              onTap: () => _showReportDetails(report),
            ),
          );
        },
      ),
    );
  }

  Color _getColorForType(ReportType type) {
    switch (type) {
      case ReportType.user:
      case ReportType.guide:
        return Colors.blue;
      case ReportType.tour:
        return Colors.green;
      case ReportType.post:
      case ReportType.comment:
        return Colors.orange;
    }
  }

  IconData _getIconForType(ReportType type) {
    switch (type) {
      case ReportType.user:
      case ReportType.guide:
        return Icons.person_off;
      case ReportType.tour:
        return Icons.tour;
      case ReportType.post:
        return Icons.article;
      case ReportType.comment:
        return Icons.comment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Content'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Posts & Comments'),
            Tab(text: 'Users & Guides'),
            Tab(text: 'Tours'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _allReports.isEmpty
                  ? const Center(child: Text('No pending reports.'))
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _allReports.length,
                        itemBuilder: (context, index) {
                          final report = _allReports[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorForType(report.reportedItemType).withOpacity(0.2),
                                child: Icon(_getIconForType(report.reportedItemType), color: _getColorForType(report.reportedItemType)),
                              ),
                              title: Text(report.reason, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${report.reportedItemType.name.toUpperCase()} • ${DateFormat('MMM d, h:mm a').format(report.timestamp)}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'view') _showReportDetails(report);
                                  if (val == 'dismiss') _dismissReport(report);
                                  if (val == 'delete') _deleteContent(report);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                                  const PopupMenuItem(value: 'dismiss', child: Text('Dismiss Report')),
                                  if (report.reportedItemType != ReportType.user && report.reportedItemType != ReportType.guide)
                                    const PopupMenuItem(value: 'delete', child: Text('Delete Content', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                              onTap: () => _showReportDetails(report),
                            ),
                          );
                        },
                      ),
                    ),
          // Posts & Comments
          _buildList(ReportType.post, ReportType.comment),
          // Users
          _buildList(ReportType.user, ReportType.guide),
          // Tours
          _buildList(ReportType.tour),
        ],
      ),
    );
  }
}
