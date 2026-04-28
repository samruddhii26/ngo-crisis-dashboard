import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NGOApp());
}

class NGOApp extends StatelessWidget {
  const NGOApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
    );
  }
}

// ─────────────────────────────────────────────
// DASHBOARD SCREEN
// ─────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Resource Allocation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Data-Driven Volunteer Coordination',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Volunteers',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VolunteersScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Banner
          _StatsBanner(),
          // Report List
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No community reports yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                        Text('Tap "Add Report" to get started.',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _ReportCard(data: data, docId: doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Report'),
        onPressed: () => _showAddReportDialog(context),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATS BANNER
// ─────────────────────────────────────────────
class _StatsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        int total = 0, urgent = 0, matched = 0;
        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            if ((d['urgencyScore'] ?? '') == 'HIGH') urgent++;
            if ((d['status'] ?? '') == 'VOLUNTEER MATCHED') matched++;
          }
        }
        return Container(
          color: Colors.teal.shade700,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              _StatChip('Total Reports', '$total', Icons.list_alt),
              const SizedBox(width: 8),
              _StatChip('Urgent', '$urgent', Icons.priority_high, color: Colors.orange.shade300),
              const SizedBox(width: 8),
              _StatChip('Matched', '$matched', Icons.handshake_outlined, color: Colors.green.shade300),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? color;
  const _StatChip(this.label, this.value, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white, size: 20),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color ?? Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REPORT CARD
// ─────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _ReportCard({required this.data, required this.docId});

  Color get _urgencyColor {
    switch (data['urgencyScore']) {
      case 'HIGH': return Colors.red.shade100;
      case 'MEDIUM': return Colors.orange.shade100;
      case 'LOW': return Colors.green.shade100;
      default: return Colors.grey.shade100;
    }
  }

  Color get _urgencyBadgeColor {
    switch (data['urgencyScore']) {
      case 'HIGH': return Colors.red;
      case 'MEDIUM': return Colors.orange;
      case 'LOW': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: _urgencyColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_categoryIcon(data['category']), color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['description'] ?? 'No Description',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _urgencyBadgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['urgencyScore'] ?? '...',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(data['location'] ?? 'Unknown Location',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Spacer(),
                const Icon(Icons.category, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(data['category'] ?? 'General',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(data['status'] ?? 'PENDING',
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                const Spacer(),
                if (data['status'] != 'VOLUNTEER MATCHED')
                  TextButton.icon(
                    icon: const Icon(Icons.handshake, size: 16),
                    label: const Text('Match Volunteer', style: TextStyle(fontSize: 12)),
                    onPressed: () => _matchVolunteer(context, docId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'Food': return Icons.fastfood;
      case 'Medical': return Icons.medical_services;
      case 'Shelter': return Icons.house;
      case 'Education': return Icons.school;
      case 'Clothing': return Icons.checkroom;
      default: return Icons.help_outline;
    }
  }

  Future<void> _matchVolunteer(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(docId).update({
        'status': 'VOLUNTEER MATCHED',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Volunteer matched successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────
// ADD REPORT DIALOG
// ─────────────────────────────────────────────
void _showAddReportDialog(BuildContext context) {
  final descController = TextEditingController();
  final locationController = TextEditingController();
  String selectedCategory = 'Food';
  String selectedUrgency = 'MEDIUM';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Submit Community Need Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Data-driven coordination for social impact',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Describe the need *',
                  hintText: 'e.g. Food supply needed at Community Center',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 12),

              // Location
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location *',
                  hintText: 'e.g. Baya Karve Hostel, Pune',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: ['Food', 'Medical', 'Shelter', 'Education', 'Clothing', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 12),

              // Urgency
              const Text('Urgency Level:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: ['LOW', 'MEDIUM', 'HIGH'].map((level) {
                  final colors = {'LOW': Colors.green, 'MEDIUM': Colors.orange, 'HIGH': Colors.red};
                  final selected = selectedUrgency == level;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedUrgency = level),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? colors[level] : colors[level]!.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors[level]!),
                        ),
                        child: Center(
                          child: Text(level,
                              style: TextStyle(
                                  color: selected ? Colors.white : colors[level],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Report', style: TextStyle(fontSize: 16)),
                  onPressed: () async {
                    if (descController.text.trim().isEmpty ||
                        locationController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill description and location.'),
                            backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await _submitReport(
                      context: context,
                      description: descController.text.trim(),
                      location: locationController.text.trim(),
                      category: selectedCategory,
                      urgency: selectedUrgency,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}

Future<void> _submitReport({
  required BuildContext context,
  required String description,
  required String location,
  required String category,
  required String urgency,
}) async {
  try {
    await FirebaseFirestore.instance.collection('reports').add({
      'description': description,
      'location': location,
      'category': category,
      'urgencyScore': urgency,
      'status': 'PENDING',
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Report submitted! Matching volunteers...'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// ─────────────────────────────────────────────
// VOLUNTEERS SCREEN
// ─────────────────────────────────────────────
class VolunteersScreen extends StatelessWidget {
  const VolunteersScreen({super.key});

  final List<Map<String, String>> volunteers = const [
    {'name': 'Priya Sharma', 'skill': 'Medical Aid', 'area': 'Pune Central'},
    {'name': 'Rahul Desai', 'skill': 'Food Distribution', 'area': 'Kothrud'},
    {'name': 'Ananya Joshi', 'skill': 'Education Support', 'area': 'Baner'},
    {'name': 'Vikram Kulkarni', 'skill': 'Shelter Coordination', 'area': 'Hadapsar'},
    {'name': 'Sneha Patil', 'skill': 'Clothing Drive', 'area': 'Warje'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Volunteers'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: volunteers.length,
        itemBuilder: (context, index) {
          final v = volunteers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Text(v['name']![0],
                    style: TextStyle(color: Colors.teal.shade800,
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(v['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Skill: ${v['skill']}'),
              trailing: Chip(
                label: Text(v['area']!, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.teal.shade50,
              ),
            ),
          );
        },
      ),
    );
  }
}