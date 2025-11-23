import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'edit_profile_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  static const routeName = '/provider-profile';

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  bool _loading = true;
  bool _uploadingPhoto = false;

  String? _photoUrl;
  String? _name;
  String? _email;
  String? _phone;
  String? _city;
  String? _bio;
  double? _rating;
  int? _totalJobs;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      _email = user.email;

      final doc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      setState(() {
        _photoUrl = data['photoUrl'] as String?;
        _name = (data['displayName'] ?? data['name'] ?? _email ?? '') as String;
        _phone = (data['phone'] ?? '') as String;
        _city = (data['city'] ?? '') as String;
        _bio = (data['bio'] ?? '') as String;
        _rating = (data['rating'] ?? 0).toDouble();
        _totalJobs = (data['totalJobs'] ?? 0) as int;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e')),
      );
    }
  }

  Future<void> _changePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$uid.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('providers').doc(uid).set({
        'photoUrl': url,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'photoUrl': url,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _photoUrl = url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto atualizada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _openEditProfile() async {
    final result =
        await Navigator.of(context).pushNamed(EditProfileScreen.routeName);

    if (result == true) {
      await _loadProfile();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal.withOpacity(0.05),
            Colors.white,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Cabeçalho com avatar =====
            Row(
              children: [
                GestureDetector(
                  onTap: _uploadingPhoto ? null : _changePhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.teal.shade50,
                        backgroundImage:
                            _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                        child: _photoUrl == null
                            ? const Icon(Icons.person, size: 38)
                            : null,
                      ),
                      if (_uploadingPhoto)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name ?? (_email ?? 'Prestador'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((_phone ?? '').isNotEmpty)
                        Text(
                          _phone!,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      if ((_city ?? '').isNotEmpty)
                        Text(
                          _city!,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ===== Cards de estatística =====
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Avaliação',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                (_rating ?? 0).toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star,
                                  size: 18, color: Colors.amber),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Atendimentos',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            (_totalJobs ?? 0).toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ===== Sobre =====
            const Text('Sobre', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              (_bio ?? '').isEmpty
                  ? 'Aqui você poderá configurar mais detalhes do seu perfil, '
                      'como cidade de atendimento, descrição profissional e '
                      'outras informações para os clientes.'
                  : _bio!,
              style: TextStyle(
                color: Colors.grey.shade800,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 18),

            // ===== Botões =====
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openEditProfile,
                icon: const Icon(Icons.edit, color: Colors.teal),
                label: const Text(
                  'Editar perfil',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sair da conta',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
