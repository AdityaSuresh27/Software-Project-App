/// AvatarCustomizer - Interactive Avatar Customization Interface
/// 
/// Provides a clean, intuitive interface for users to customize their avatar with
/// options for body style, colors, features, and accessories.
/// 
/// Features:
/// - Real-time preview of avatar
/// - Body style selection
/// - Color picker for body colors
/// - Eyes and mouth style customization
/// - Glasses and bowtie accessories
/// - Randomize button for quick avatar generation
/// 
/// Returns the customized Avatar object when confirmed.

import 'package:flutter/material.dart';
import '../backend/models.dart';
import 'theme.dart';
import 'animated_avatar.dart';

class AvatarCustomizer extends StatefulWidget {
  final Avatar? initialAvatar;
  final Function(Avatar) onAvatarSelected;

  const AvatarCustomizer({
    super.key,
    this.initialAvatar,
    required this.onAvatarSelected,
  });

  @override
  State<AvatarCustomizer> createState() => _AvatarCustomizerState();
}

class _AvatarCustomizerState extends State<AvatarCustomizer> {
  late Avatar _currentAvatar;

  @override
  void initState() {
    super.initState();
    _currentAvatar = widget.initialAvatar ?? Avatar();
  }

  Color _hexToColor(String hexString) {
    hexString = hexString.replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF$hexString';
    }
    return Color(int.parse(hexString, radix: 16));
  }

  void _showColorPicker(String colorType) {
    final colors = colorType == 'eyes'
        ? const [
            '#000000', '#3366FF', '#FF0000', '#00AA00',
            '#FFB6C1', '#4B0082', '#FF69B4', '#00CED1',
          ]
        : const [
            '#FF6B9D', '#4ECDC4', '#45B7D1', '#FFA07A', '#98D8C8',
            '#F7DC6F', '#BB8FCE', '#85C1E2', '#FFD93D', '#A8E6CF',
            '#FFB6C1', '#DDA0DD', '#87CEEB', '#F0E68C', '#FF69B4',
            '#3366FF', '#00CED1', '#FF1493', '#32CD32', '#FFD700',
          ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select ${colorType == 'body' ? 'Body' : colorType == 'accent' ? 'Accent' : colorType == 'eyes' ? 'Eyes' : 'Mouth'} Color'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (colorType == 'body') {
                      _currentAvatar = _currentAvatar.copyWith(bodyColor: color);
                    } else if (colorType == 'accent') {
                      _currentAvatar = _currentAvatar.copyWith(accentColor: color);
                    } else if (colorType == 'eyes') {
                      _currentAvatar = _currentAvatar.copyWith(eyesColor: color);
                    }
                    widget.onAvatarSelected(_currentAvatar);
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _hexToColor(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black26,
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _randomizeAvatar() {
    setState(() {
      _currentAvatar = Avatar.random();
      widget.onAvatarSelected(_currentAvatar);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Avatar Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                AnimatedAvatar(
                  avatar: _currentAvatar,
                  size: 140,
                  autoAnimate: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    onPressed: _randomizeAvatar,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shuffle, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Randomize Avatar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Customization options
          _buildCustomizationSection(
            'Body Style',
            ['circle', 'square', 'rounded'],
            _currentAvatar.bodyStyle,
            (value) {
              setState(() {
                _currentAvatar = _currentAvatar.copyWith(bodyStyle: value);                widget.onAvatarSelected(_currentAvatar);                widget.onAvatarSelected(_currentAvatar);
              });
            },
          ),
          const SizedBox(height: 16),

          _buildColorSection('Body Color', 'body', _currentAvatar.bodyColor),
          const SizedBox(height: 16),

          _buildCustomizationSection(
            'Eyes',
            ['round', 'square', 'x_eyes'],
            _currentAvatar.eyesStyle,
            (value) {
              setState(() {
                _currentAvatar = _currentAvatar.copyWith(eyesStyle: value);
                widget.onAvatarSelected(_currentAvatar);
              });
            },
          ),
          const SizedBox(height: 16),

          _buildColorSection('Eyes Color', 'eyes', _currentAvatar.eyesColor),
          const SizedBox(height: 16),

          _buildCustomizationSection(
            'Mouth',
            ['smile', 'neutral', 'surprised', 'box'],
            _currentAvatar.mouthStyle,
            (value) {
              setState(() {
                _currentAvatar = _currentAvatar.copyWith(mouthStyle: value);
                widget.onAvatarSelected(_currentAvatar);
              });
            },
          ),
          const SizedBox(height: 16),

          _buildColorSection('Mouth Color', 'accent', _currentAvatar.accentColor),
          const SizedBox(height: 16),

          // Accessories
          _buildAccessoriesSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCustomizationSection(
    String title,
    List<String> options,
    String currentValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final isSelected = option == currentValue;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    option.replaceAll('_', ' ').toUpperCase(),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onChanged(option);
                  },
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                  selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection(String title, String colorType, String hexColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showColorPicker(colorType),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: _hexToColor(hexColor),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Center(
              child: Text(
                'Tap to Change Color',
                style: TextStyle(
                  color: _hexToColor(hexColor).computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accessories',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildAccessoryToggle(
          label: 'Glasses',
          value: _currentAvatar.hasGlasses,
          onChanged: (value) {
            setState(() {
              _currentAvatar = _currentAvatar.copyWith(hasGlasses: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAccessoryToggle({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
