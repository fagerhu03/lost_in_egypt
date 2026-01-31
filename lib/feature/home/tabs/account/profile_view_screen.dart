import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/data/models/user.dart';

class ProfileViewScreen extends StatefulWidget {
  final String? uid; // optional: view other user's profile if provided
  const ProfileViewScreen({Key? key, this.uid}) : super(key: key);

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;
  UserModel? _user;
  bool _isLoading = true;
  int _postCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uidToLoad = widget.uid ?? _currentUid;
    if (uidToLoad == null) return;

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uidToLoad)
          .get();
      if (userDoc.exists) {
        _user = UserModel.fromMap(userDoc.data()!, userDoc.id);
      }

      // Attempt to count posts (best-effort). Field name used: 'userId' or 'authorId' -> check both.
      final query1 = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: uidToLoad)
          .get();
      if (query1.docs.isNotEmpty) {
        _postCount = query1.size;
      } else {
        final query2 = await FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: uidToLoad)
            .get();
        _postCount = query2.size;
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF714611)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC79A00)),
            )
          : _user == null
          ? const Center(child: Text('User not found'))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xFF4A3B2A),
                        backgroundImage: _user!.profileImageUrl.isNotEmpty
                            ? NetworkImage(_user!.profileImageUrl)
                                  as ImageProvider
                            : null,
                        child: _user!.profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_user!.firstName} ${_user!.lastName}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Marcellus',
                          color: Color(0xFF714611),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _user!.nationality.isNotEmpty ? _user!.nationality : '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBadge('Email', _user!.emailVerified),
                          const SizedBox(width: 12),
                          _buildBadge('Phone', _user!.phoneVerified),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStat('Posts', _postCount),
                          const SizedBox(width: 24),
                          _buildStat('Role', 0, label: _user!.role),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                if (_user!.bio.isNotEmpty) ...[
                  const Text(
                    'About',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF714611),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _user!.bio,
                    style: const TextStyle(color: Color(0xFF5A3E18)),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_user!.interests.isNotEmpty) ...[
                  const Text(
                    'Interests',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF714611),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _user!.interests
                        .map((i) => Chip(label: Text(i)))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_user!.instagramHandle.isNotEmpty ||
                    _user!.twitterHandle.isNotEmpty) ...[
                  const Text(
                    'Social',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF714611),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_user!.instagramHandle.isNotEmpty)
                    _buildSocialRow('Instagram', _user!.instagramHandle),
                  if (_user!.twitterHandle.isNotEmpty)
                    _buildSocialRow('Twitter', _user!.twitterHandle),
                  const SizedBox(height: 20),
                ],

                const Text(
                  'Contact',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF714611),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _user!.email,
                  style: const TextStyle(color: Color(0xFF5A3E18)),
                ),
                const SizedBox(height: 6),
                if (_user!.phoneNumber.isNotEmpty)
                  Text(
                    _user!.phoneNumber,
                    style: const TextStyle(color: Color(0xFF5A3E18)),
                  ),

                const SizedBox(height: 30),
                if (widget.uid == null || widget.uid == _currentUid) ...[
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/edit_profile_enhanced'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC79A00),
                    ),
                    child: const Text('Edit profile'),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildBadge(String label, bool good) {
    return Row(
      children: [
        Icon(
          good ? Icons.check_circle : Icons.radio_button_unchecked,
          color: good ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: good ? Colors.green : Colors.grey)),
      ],
    );
  }

  Widget _buildStat(String name, int value, {String? label}) {
    return Column(
      children: [
        Text(
          label ?? value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF714611),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSocialRow(String service, String handle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$service: ',
            style: const TextStyle(
              color: Color(0xFF714611),
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              handle,
              style: const TextStyle(color: Color(0xFF5A3E18)),
            ),
          ),
        ],
      ),
    );
  }
}
