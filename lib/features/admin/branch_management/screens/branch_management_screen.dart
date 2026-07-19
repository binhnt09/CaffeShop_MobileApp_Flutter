import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/bloc/auth_bloc.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  List<MockBranch> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final list = await ApiService.instance.getBranches();
      if (mounted) {
        setState(() {
          _branches = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _branches = MockData.branches;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showBranchFormDialog([MockBranch? branchToEdit]) async {
    final nameController = TextEditingController(text: branchToEdit?.name ?? '');
    final addressController = TextEditingController(text: branchToEdit?.address ?? '');
    final latController = TextEditingController(text: branchToEdit?.latitude.toString() ?? '10.776');
    final lngController = TextEditingController(text: branchToEdit?.longitude.toString() ?? '106.698');
    bool isOpen = branchToEdit?.isOpen ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                branchToEdit == null ? 'Thêm Chi Nhánh Mới' : 'Sửa Chi Nhánh',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Tên chi nhánh', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Địa chỉ', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: latController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Vĩ độ (Latitude)', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lngController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Kinh độ (Longitude)', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trạng thái mở cửa:', style: TextStyle(color: Colors.white70)),
                        Switch(
                          value: isOpen,
                          activeColor: AppColors.accent,
                          onChanged: (val) {
                            setDialogState(() => isOpen = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('HỦY', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final address = addressController.text.trim();
                    final lat = double.tryParse(latController.text) ?? 10.776;
                    final lng = double.tryParse(lngController.text) ?? 106.698;

                    if (name.isEmpty || address.isEmpty) return;

                    final token = AuthBloc.currentUser?.token;
                    final newBranch = MockBranch(
                      id: branchToEdit?.id ?? '0',
                      name: name,
                      address: address,
                      latitude: lat,
                      longitude: lng,
                      openTime: '07:00',
                      closeTime: '22:00',
                      isOpen: isOpen,
                      distanceKm: 0.0,
                    );

                    setState(() => _isLoading = true);
                    Navigator.pop(context);

                    bool success = false;
                    if (token != null) {
                      if (branchToEdit == null) {
                        success = await ApiService.instance.createBranch(newBranch, token);
                      } else {
                        success = await ApiService.instance.updateBranch(newBranch, token);
                      }
                    }

                    if (success) {
                      await _loadBranches();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lưu thông tin chi nhánh thành công!'), backgroundColor: AppColors.success),
                        );
                      }
                    } else {
                      setState(() {
                        if (branchToEdit == null) {
                          _branches.add(newBranch);
                        } else {
                          final idx = _branches.indexWhere((b) => b.id == branchToEdit.id);
                          if (idx >= 0) _branches[idx] = newBranch;
                        }
                        _isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: const Text('LƯU'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBranch(String id) async {
    final token = AuthBloc.currentUser?.token;
    setState(() => _isLoading = true);

    bool success = false;
    if (token != null) {
      success = await ApiService.instance.deleteBranch(id, token);
    }

    if (success) {
      await _loadBranches();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa chi nhánh thành công!'), backgroundColor: AppColors.success),
        );
      }
    } else {
      setState(() {
        _branches.removeWhere((b) => b.id == id);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Chi Nhánh', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _branches.isEmpty
              ? const Center(child: Text('Không có chi nhánh nào', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (branch.isOpen ? AppColors.success : AppColors.error).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.storefront,
                              color: branch.isOpen ? AppColors.success : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  branch.address,
                                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.accent, size: 20),
                            onPressed: () => _showBranchFormDialog(branch),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                            onPressed: () => _deleteBranch(branch.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        onPressed: () => _showBranchFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
