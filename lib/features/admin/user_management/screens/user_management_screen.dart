import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final List<MockUser> _users = MockData.users;
  String _searchQuery = "";
  String _selectedRoleFilter = 'ALL';

  List<MockUser> _getFilteredUsers() {
    List<MockUser> list = _users;
    if (_selectedRoleFilter != 'ALL') {
      list = list.where((u) => u.role == _selectedRoleFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((u) =>
          u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.phone.contains(_searchQuery)).toList();
    }
    return list;
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.red.shade400;
      case 'MANAGER':
        return Colors.orange.shade400;
      case 'CASHIER':
        return Colors.blue.shade400;
      case 'BARISTA':
        return Colors.teal.shade400;
      default:
        return Colors.green.shade400;
    }
  }

  void _showUserDialog({MockUser? userToEdit}) {
    final nameController = TextEditingController(text: userToEdit?.fullName ?? '');
    final emailController = TextEditingController(text: userToEdit?.email ?? '');
    final phoneController = TextEditingController(text: userToEdit?.phone ?? '');
    String role = userToEdit?.role ?? 'CUSTOMER';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(userToEdit == null ? 'Thêm Tài Khoản Mới' : 'Sửa Tài Khoản', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Họ và tên'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Email đăng nhập'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Số điện thoại'),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Phân quyền tài khoản:', style: TextStyle(color: Colors.white30, fontSize: 11)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: role,
                          dropdownColor: AppColors.surface,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => role = val);
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN (Quản trị viên)')),
                            DropdownMenuItem(value: 'MANAGER', child: Text('MANAGER (Quản lý cửa hàng)')),
                            DropdownMenuItem(value: 'CASHIER', child: Text('CASHIER (Thu ngân quầy)')),
                            DropdownMenuItem(value: 'BARISTA', child: Text('BARISTA (Pha chế bếp)')),
                            DropdownMenuItem(value: 'CUSTOMER', child: Text('CUSTOMER (Khách hàng)')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('HỦY', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final phone = phoneController.text.trim();
                    if (name.isEmpty || email.isEmpty || phone.isEmpty) return;

                    setState(() {
                      if (userToEdit == null) {
                        _users.add(
                          MockUser(
                            id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                            fullName: name,
                            email: email,
                            phone: phone,
                            role: role,
                          ),
                        );
                      } else {
                        final idx = _users.indexWhere((u) => u.id == userToEdit.id);
                        if (idx >= 0) {
                          _users[idx] = MockUser(
                            id: userToEdit.id,
                            fullName: name,
                            email: email,
                            phone: phone,
                            role: role,
                            loyaltyPoints: userToEdit.loyaltyPoints,
                            memberTier: userToEdit.memberTier,
                            branchId: userToEdit.branchId,
                          );
                        }
                      }
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cập nhật tài khoản $name thành công!'), backgroundColor: AppColors.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.background),
                  child: Text(userToEdit == null ? 'THÊM MỚI' : 'CẬP NHẬT'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản hệ thống', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: Column(
        children: [
          // Filter & Search Panel
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo tên, email, sđt...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedRoleFilter,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRoleFilter = val);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('Tất cả vai trò')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    DropdownMenuItem(value: 'MANAGER', child: Text('MANAGER')),
                    DropdownMenuItem(value: 'CASHIER', child: Text('CASHIER')),
                    DropdownMenuItem(value: 'BARISTA', child: Text('BARISTA')),
                    DropdownMenuItem(value: 'CUSTOMER', child: Text('CUSTOMER')),
                  ],
                ),
              ],
            ),
          ),

          // User accounts list
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(child: Text('Không tìm thấy tài khoản nào', style: TextStyle(color: Colors.white.withOpacity(0.2))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final roleColor = _getRoleColor(user.role);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withOpacity(0.2),
                            child: Text(
                              user.fullName.substring(0, 1).toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.role,
                                  style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('✉ Email: ${user.email}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                              const SizedBox(height: 2),
                              Text('📞 SĐT: ${user.phone}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.white60, size: 18),
                                onPressed: () => _showUserDialog(userToEdit: user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _users.removeWhere((u) => u.id == user.id);
                                  });
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
