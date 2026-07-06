import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';

class BranchSelectionScreen extends StatefulWidget {
  const BranchSelectionScreen({super.key});

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  MockBranch? _selectedBranch;
  final List<MockBranch> _branches = MockData.branches;

  @override
  void initState() {
    super.initState();
    // Default select first open branch if available
    final openBranch = _branches.firstWhere((b) => b.isOpen, orElse: () => _branches.first);
    _selectedBranch = openBranch;
  }

  void _confirmSelection() {
    if (_selectedBranch == null) return;
    if (!_selectedBranch!.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chi nhánh này hiện đã đóng cửa. Vui lòng chọn chi nhánh đang mở cửa!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Save selected branch context
    // In mock, we can just save it or navigate directly
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chọn chi nhánh: ${_selectedBranch!.name}'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/menu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Chi Nhánh Đặt Món', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false, // Force branch selection
      ),
      body: Column(
        children: [
          // Mock Map Area - Premium graphical design with custom canvas and markers
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1E1812), // Matte black/grey background for map
              child: Stack(
                children: [
                  // Map lines decoration
                  Positioned.fill(
                    child: CustomPaint(
                      painter: MapGridPainter(),
                    ),
                  ),
                  // Current user location
                  const Positioned(
                    top: 180,
                    left: 160,
                    child: UserLocationMarker(),
                  ),
                  // Branch markers
                  Positioned(
                    top: 90,
                    left: 120,
                    child: _buildBranchMarker(_branches[0]), // br_hbt
                  ),
                  Positioned(
                    top: 140,
                    left: 260,
                    child: _buildBranchMarker(_branches[1]), // br_ndc
                  ),
                  Positioned(
                    top: 250,
                    left: 80,
                    child: _buildBranchMarker(_branches[2]), // br_lqdon
                  ),
                  Positioned(
                    top: 280,
                    left: 230,
                    child: _buildBranchMarker(_branches[3]), // br_cmt8
                  ),
                  Positioned(
                    top: 70,
                    left: 310,
                    child: _buildBranchMarker(_branches[4]), // br_pnp
                  ),
                  // Map Hint Instruction
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.gps_fixed, size: 14, color: AppColors.accent),
                          SizedBox(width: 6),
                          Text(
                            'Quét vị trí GPS thành công',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Branch List & Selection Actions
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Các chi nhánh gần bạn nhất:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.accent,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _branches.length,
                      itemBuilder: (context, index) {
                        final branch = _branches[index];
                        final isSelected = _selectedBranch?.id == branch.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBranch = branch;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.05),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Left icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: (branch.isOpen ? AppColors.primary : Colors.grey.shade900).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: branch.isOpen ? AppColors.primary : Colors.grey.shade800,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.storefront,
                                    color: branch.isOpen ? AppColors.accent : Colors.grey,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Middle Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        branch.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isSelected ? AppColors.accent : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        branch.address,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 12, color: Colors.white.withOpacity(0.4)),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${branch.distanceKm} km',
                                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.access_time_filled, size: 12, color: Colors.white.withOpacity(0.4)),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${branch.openTime} - ${branch.closeTime}',
                                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Right Status Badge
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (branch.isOpen ? AppColors.success : AppColors.error).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        branch.isOpen ? 'Đang mở' : 'Đã đóng',
                                        style: TextStyle(
                                          color: branch.isOpen ? AppColors.success : AppColors.error,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(height: 8),
                                      const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
                                    ]
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  CoffeeButton(
                    label: 'ĐẶT MÓN TẠI CHI NHÁNH NÀY',
                    onTap: _selectedBranch != null ? _confirmSelection : null,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchMarker(MockBranch branch) {
    final isSelected = _selectedBranch?.id == branch.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBranch = branch;
        });
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent
                  : (branch.isOpen ? AppColors.primary : Colors.grey.shade800),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Icon(
              Icons.local_cafe,
              size: isSelected ? 18 : 14,
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              branch.name.replaceAll('CaffeShop ', ''),
              style: TextStyle(
                color: isSelected ? AppColors.accent : Colors.white,
                fontSize: 8,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// User current location marker widget
class UserLocationMarker extends StatefulWidget {
  const UserLocationMarker({super.key});

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse circle
            Container(
              width: 12 + (_controller.value * 28),
              height: 12 + (_controller.value * 28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.4 * (1 - _controller.value)),
              ),
            ),
            // User Location core dot
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade600,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom painter to draw mock abstract map roads and styling
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 2;

    // Draw horizontal grid lines
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    // Draw vertical grid lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Draw abstract main roads
    canvas.drawLine(Offset(50, 0), Offset(50, size.height), roadPaint);
    canvas.drawLine(Offset(200, 0), Offset(200, size.height), roadPaint);
    canvas.drawLine(Offset(0, 120), Offset(size.width, 120), roadPaint);
    canvas.drawLine(Offset(0, 240), Offset(size.width, 240), roadPaint);

    // Diagonal shortcut road
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
