import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Text Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Colors.white.withOpacity(0.4), // Light white selection color
        ),
      ),
      home: ImageTextEditor(),
    );
  }
}

class ImageTextEditor extends StatefulWidget {
  @override
  _ImageTextEditorState createState() => _ImageTextEditorState();
}

class _ImageTextEditorState extends State<ImageTextEditor> {
  Uint8List? _selectedImageBytes;

  Offset _textPosition = Offset(50, 50);
  String _editableText = "Enter Text";
  bool _isEditing = false;
  double _textBoxWidth = 150;
  double _textBoxHeight = 50;

  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(); // Initialize FocusNode for detecting focus changes
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Clean up FocusNode when the widget is disposed
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedImageBytes = result.files.single.bytes!;
      });
    }
  }

  // This function is used to handle clicks outside the text box to save the text
  void _onTapOutside() {
    if (_isEditing) {
      setState(() {
        _isEditing = false;
      });
      FocusScope.of(context).unfocus(); // Dismiss the keyboard if it's open
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Text Editor'),
      ),
      body: GestureDetector(
        onTap: _onTapOutside, // Handle tap outside to close the edit mode
        child: _selectedImageBytes == null
            ? Center(
                child: ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Select Image'),
                ),
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: _textPosition.dx,
                    top: _textPosition.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _textPosition += details.delta;
                        });
                      },
                      onTap: () {
                        setState(() {
                          _isEditing = !_isEditing; // Toggle edit mode
                        });
                      },
                      child: Container(
                        width: _textBoxWidth,
                        height: _textBoxHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2), // White border
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _isEditing
                                  ? TextField(
                                      focusNode: _focusNode,
                                      autofocus: true,
                                      controller: TextEditingController(
                                          text: _editableText),
                                      onSubmitted: (value) {
                                        setState(() {
                                          _editableText = value;
                                          _isEditing = false;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                      ),
                                      style: TextStyle(
                                        fontSize: _textBoxHeight / 2,
                                        color: Colors.white,
                                      ),
                                      cursorColor: Colors.white, // White cursor
                                    )
                                  : Center(
                                      child: Text(
                                        _editableText,
                                        style: TextStyle(
                                          fontSize: _textBoxHeight / 2,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    _textBoxWidth += details.delta.dx;
                                    _textBoxHeight += details.delta.dy;

                                    if (_textBoxHeight < 20) {
                                      _textBoxHeight = 20; // Prevent collapsing too small
                                    }
                                    if (_textBoxWidth < 50) {
                                      _textBoxWidth = 50; // Minimum width
                                    }
                                  });
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
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
