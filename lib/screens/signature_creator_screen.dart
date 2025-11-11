import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:signature/signature.dart';

class SignatureCreatorScreen extends StatefulWidget {
  final Function(String name, Uint8List signatureBytes) onSignatureSaved;

  const SignatureCreatorScreen({
    super.key,
    required this.onSignatureSaved,
  });

  @override
  State<SignatureCreatorScreen> createState() => _SignatureCreatorScreenState();
}

class _SignatureCreatorScreenState extends State<SignatureCreatorScreen> {
  SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: CupertinoColors.black,
    exportBackgroundColor: CupertinoColors.systemBackground.withOpacity(0.0),
  );
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = CupertinoColors.black;
  double _selectedThickness = 3.0;

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a name for your signature');
      return;
    }

    if (_controller.isEmpty) {
      _showErrorDialog('Please draw your signature');
      return;
    }

    final signatureBytes = await _controller.toPngBytes();
    if (signatureBytes != null) {
      widget.onSignatureSaved(_nameController.text.trim(), signatureBytes);
      Navigator.pop(context);
    } else {
      _showErrorDialog('Failed to save signature');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFFF8F9FA),
        border: null,
        middle: Text(
          'Create Signature',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NAME',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _nameController,
                      placeholder: 'Enter signature name',
                      placeholderStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.black.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.all(12),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.black,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.systemGrey4.withOpacity(1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'COLOR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildColorButton(CupertinoColors.black),
                                _buildColorButton(CupertinoColors.systemBlue),
                                _buildColorButton(CupertinoColors.systemRed),
                                _buildColorButton(CupertinoColors.systemGreen),
                                _buildColorButton(CupertinoColors.systemPurple),
                                _buildColorButton(CupertinoColors.systemYellow),
                                _buildColorButton(CupertinoColors.systemOrange),
                                _buildColorButton(CupertinoColors.systemTeal),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'THICKNESS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CupertinoSlider(
                            value: _selectedThickness,
                            min: 1.0,
                            max: 10.0,
                            onChanged: (value) {
                              setState(() {
                                _selectedThickness = value;
                                _controller = SignatureController(
                                  penStrokeWidth: value,
                                  penColor: _selectedColor,
                                  exportBackgroundColor: CupertinoColors
                                      .systemBackground
                                      .withOpacity(0.0),
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.systemGrey4,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Signature(
                      controller: _controller,
                      backgroundColor:
                          CupertinoColors.systemBackground.withOpacity(0.0),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        onPressed: () {
                          _controller.clear();
                        },
                        color: CupertinoColors.systemGrey,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CupertinoButton(
                        onPressed: _saveSignature,
                        color: const Color.fromARGB(255, 255, 0, 0),
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _controller = SignatureController(
            penStrokeWidth: _selectedThickness,
            penColor: color,
            exportBackgroundColor:
                CupertinoColors.systemBackground.withOpacity(0.0),
          );
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color
                ? CupertinoColors.systemGrey4
                : CupertinoColors.systemGrey4.withOpacity(0),
            width: _selectedColor == color ? 2 : 0,
          ),
        ),
        child: _selectedColor == color
            ? Icon(
                CupertinoIcons.checkmark,
                color: CupertinoColors.white,
                size: 18,
              )
            : null,
      ),
    );
  }
}
