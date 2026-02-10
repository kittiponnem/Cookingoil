import 'package:flutter/material.dart';
import '../../../models/config_models.dart';
import '../../../services/config_service.dart';

/// Admin screen for managing UCO (Used Cooking Oil) grades
class AdminUCOGradesPage extends StatefulWidget {
  const AdminUCOGradesPage({super.key});

  @override
  State<AdminUCOGradesPage> createState() => _AdminUCOGradesPageState();
}

class _AdminUCOGradesPageState extends State<AdminUCOGradesPage> {
  final ConfigService _configService = ConfigService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ConfigUCOGrade> _grades = [];
  List<ConfigUCOGrade> _filteredGrades = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGrades();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterGrades();
    });
  }

  void _filterGrades() {
    if (_searchQuery.isEmpty) {
      _filteredGrades = List.from(_grades);
    } else {
      _filteredGrades = _grades.where((grade) {
        return grade.gradeName.toLowerCase().contains(_searchQuery) ||
            grade.gradeCode.toLowerCase().contains(_searchQuery) ||
            grade.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final grades = await _configService.getUCOGrades(forceRefresh: true);
      setState(() {
        _grades = grades;
        _filterGrades();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load grades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddEditDialog({ConfigUCOGrade? grade}) async {
    final isEdit = grade != null;
    final nameController = TextEditingController(text: grade?.gradeName ?? '');
    final codeController = TextEditingController(text: grade?.gradeCode ?? '');
    final descController = TextEditingController(text: grade?.description ?? '');
    final minQualityController = TextEditingController(
      text: grade?.minQualityScore.toString() ?? '0',
    );
    final maxQualityController = TextEditingController(
      text: grade?.maxQualityScore.toString() ?? '100',
    );
    bool isActive = grade?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit UCO Grade' : 'Add UCO Grade'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Grade Name *',
                      hintText: 'e.g., Grade A',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter grade name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Grade Code *',
                      hintText: 'e.g., GRADE_A',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter grade code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: minQualityController,
                          decoration: const InputDecoration(
                            labelText: 'Min Quality Score *',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final num = int.tryParse(value);
                            if (num == null || num < 0 || num > 100) {
                              return '0-100';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: maxQualityController,
                          decoration: const InputDecoration(
                            labelText: 'Max Quality Score *',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final num = int.tryParse(value);
                            if (num == null || num < 0 || num > 100) {
                              return '0-100';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Grade is available for selection'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() => isActive = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final newGrade = ConfigUCOGrade(
                      id: grade?.id ?? '',
                      gradeName: nameController.text.trim(),
                      gradeCode: codeController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? ''
                          : descController.text.trim(),
                      minQualityScore: double.parse(minQualityController.text),
                      maxQualityScore: double.parse(maxQualityController.text),
                      isActive: isActive,
                      createdAt: grade?.createdAt ?? DateTime.now(),
                    );

                    if (isEdit) {
                      await _configService.updateUCOGrade(newGrade);
                    } else {
                      await _configService.addUCOGrade(newGrade);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Grade updated successfully'
                                : 'Grade added successfully',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadGrades();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save grade: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGrade(ConfigUCOGrade grade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Grade'),
        content: Text(
          'Are you sure you want to delete "${grade.gradeName}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _configService.deleteUCOGrade(grade.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grade deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadGrades();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete grade: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UCO Grades Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGrades,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search grades...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Grades list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredGrades.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.grade_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No grades found'
                                  : 'No grades match your search',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Tap + to add your first grade'
                                  : 'Try a different search term',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredGrades.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final grade = _filteredGrades[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: grade.isActive
                                    ? Colors.green
                                    : Colors.grey,
                                child: Text(
                                  grade.gradeCode.substring(0, 1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                grade.gradeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Code: ${grade.gradeCode}'),
                                  if (grade.description.isNotEmpty)
                                    Text(
                                      grade.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  Text(
                                    'Quality: ${grade.minQualityScore}-${grade.maxQualityScore}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(
                                      grade.isActive ? 'Active' : 'Inactive',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: grade.isActive
                                        ? Colors.green[100]
                                        : Colors.grey[300],
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete',
                                                style:
                                                    TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showAddEditDialog(grade: grade);
                                      } else if (value == 'delete') {
                                        _deleteGrade(grade);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Grade'),
      ),
    );
  }
}
