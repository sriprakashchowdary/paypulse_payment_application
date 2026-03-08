import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/premium_widgets.dart';

class SplitBillsScreen extends ConsumerStatefulWidget {
  const SplitBillsScreen({super.key});

  @override
  ConsumerState<SplitBillsScreen> createState() => _SplitBillsScreenState();
}

class _SplitBillsScreenState extends ConsumerState<SplitBillsScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  // Custom Numpad state
  String _amountStr = '0';
  bool _splitEqually = true;

  // Mock friends data
  final List<Map<String, dynamic>> _friends = [
    {
      'id': '1',
      'name': 'Aditi Rao',
      'avatar': 'A',
      'selected': true,
      'amount': 0.0
    },
    {
      'id': '2',
      'name': 'Rahul K',
      'avatar': 'R',
      'selected': true,
      'amount': 0.0
    },
    {
      'id': '3',
      'name': 'Karan Singh',
      'avatar': 'K',
      'selected': false,
      'amount': 0.0
    },
    {
      'id': '4',
      'name': 'Priya Das',
      'avatar': 'P',
      'selected': false,
      'amount': 0.0
    },
    {
      'id': '5',
      'name': 'Vikram',
      'avatar': 'V',
      'selected': false,
      'amount': 0.0
    },
  ];

  int get _selectedCount =>
      _friends.where((f) => f['selected'] as bool).length + 1; // +1 for "Me"
  double get _totalAmount => double.tryParse(_amountStr) ?? 0.0;
  bool _isSuccess = false;

  void _onNumpadTap(String val) {
    HapticFeedback.lightImpact();
    setState(() {
      if (val == '<') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (val == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += val;
        }
      } else {
        if (_amountStr == '0') {
          _amountStr = val;
        } else if (_amountStr.split('.').length > 1 &&
            _amountStr.split('.')[1].length >= 2) {
          return;
        } else {
          _amountStr += val;
        }
      }
      _amountCtrl.text = _amountStr;
      _recalculateSplits();
    });
  }

  void _recalculateSplits() {
    if (!_splitEqually || _selectedCount == 0) return;
    final total = _totalAmount;
    final share = total / _selectedCount;
    for (var f in _friends) {
      if (f['selected'] as bool) {
        f['amount'] = share;
      } else {
        f['amount'] = 0.0;
      }
    }
  }

  void _toggleFriend(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _friends[index]['selected'] = !(_friends[index]['selected'] as bool);
      _recalculateSplits();
    });
  }

  Future<void> _handleSendRequest() async {
    if (_totalAmount <= 0) {
      PremiumSnackbar.show(context, 'Please enter a valid amount',
          isError: true);
      HapticFeedback.heavyImpact();
      return;
    }

    if (_selectedCount <= 1) {
      PremiumSnackbar.show(context, 'Select at least one friend to split with',
          isError: true);
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final uid = ref.read(authControllerProvider.notifier).currentUid;
      if (uid == null) throw Exception('Not logged in');

      final db = ref.read(firestoreProvider);
      final perPersonShare = _totalAmount / _selectedCount;
      final note = _noteCtrl.text.trim();

      // Build participant list
      final participants = <Map<String, dynamic>>[];
      for (final friend in _friends) {
        if (friend['selected'] as bool) {
          participants.add({
            'name': friend['name'],
            'amount': _splitEqually ? perPersonShare : friend['amount'],
            'status': 'pending',
          });
        }
      }

      // Save split request to Firestore
      await db.collection('split_requests').add({
        'senderId': uid,
        'totalAmount': _totalAmount,
        'perPersonShare': perPersonShare,
        'note': note.isNotEmpty ? note : null,
        'participants': participants,
        'splitEqually': _splitEqually,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        setState(() => _isSuccess = true);
        HapticFeedback.heavyImpact();

        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) context.go('/home');
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        PremiumSnackbar.show(
          context,
          'Failed to send split request: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isSuccess) return _buildSuccessState(isDark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      // Amount Display
                      _buildAmountDisplay(isDark),
                      const SizedBox(height: 24),

                      // Description input
                      _buildDescriptionInput(isDark),
                      const SizedBox(height: 32),

                      // People Selection
                      _buildPeopleSelection(isDark),
                    ],
                  ),
                ),
              ),

              // Custom Numpad
              _buildNumpad(isDark)
                  .animate()
                  .slideY(begin: 0.5, curve: Curves.easeOutCubic),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white : AppColors.textPrimary,
              size: 28,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Split Bill',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay(bool isDark) {
    return Column(
      children: [
        Text(
          'Total Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '₹',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _amountStr,
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                color: _amountStr == '0'
                    ? (isDark ? Colors.white24 : AppColors.textMuted)
                    : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 50.ms);
  }

  Widget _buildDescriptionInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: TextField(
        controller: _noteCtrl,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'What\'s this for? (e.g., Dinner, Movie)',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : AppColors.textMuted,
          ),
          icon: Icon(Icons.receipt_long_rounded,
              color: isDark ? Colors.white38 : AppColors.textMuted, size: 20),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildPeopleSelection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Split With',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  'Split Equally',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _splitEqually,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _splitEqually = val;
                      _recalculateSplits();
                    });
                  },
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),

        // Horizontal list of friends
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _friends.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final friend = _friends[index];
              final isSelected = friend['selected'] as bool;

              return GestureDetector(
                onTap: () => _toggleFriend(index),
                child: Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? AppColors.primaryGradient
                                  : LinearGradient(colors: [
                                      (isDark
                                          ? Colors.white24
                                          : AppColors.border),
                                      (isDark
                                          ? Colors.white24
                                          : AppColors.border)
                                    ]),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                friend['avatar'],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white54
                                          : AppColors.textSecondary),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: isDark
                                          ? AppColors.bgDark
                                          : AppColors.bgLight,
                                      width: 2),
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 10),
                              ),
                            )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        friend['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? Colors.white : AppColors.textPrimary)
                              : (isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Breakdown List
        if (_selectedCount > 1 && _totalAmount > 0) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border),
              boxShadow: isDark ? [] : Shadows.card,
            ),
            child: Column(
              children: [
                _buildBreakdownItem(
                    'You', _totalAmount / _selectedCount, isDark),
                const Divider(height: 24),
                ..._friends.where((f) => f['selected'] as bool).map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildBreakdownItem(f['name'], f['amount'], isDark),
                  );
                }),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
        ]
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildBreakdownItem(String name, double amount, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : AppColors.bgLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person,
                  size: 14,
                  color: isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNumpad(bool isDark) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '<'],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row in keys) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: row.map((key) {
                return _NumpadButton(
                  label: key,
                  isDark: isDark,
                  onTap: () => _onNumpadTap(key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 16),
          // Send Request Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _handleSendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Send Request',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.send_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 80),
              ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            ),
            const SizedBox(height: 32),
            Text(
              'Requests Sent!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
            const SizedBox(height: 16),
            Text(
              'Notifications sent to ${_selectedCount - 1} friends\nfor ₹${_totalAmount.toStringAsFixed(2)} total.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _NumpadButton({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isAction = label == '<' || label == '.';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 60,
        alignment: Alignment.center,
        child: label == '<'
            ? Icon(
                Icons.backspace_outlined,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                size: 24,
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: isAction ? FontWeight.w500 : FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
      ),
    );
  }
}
