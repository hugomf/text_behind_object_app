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
          selectionColor: Colors.white.withOpacity(0.4),
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
  Uint8List? _imageBytes;
  Offset _textPosition = Offset(50, 50);
  String _text = "Enter Text";
  bool _isEditing = false;
  double _textBoxWidth = 150;
  double _textBoxHeight = 50;
  late FocusNode _focusNode;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textController = TextEditingController(text: _text);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result?.files.single.bytes != null) {
      setState(() {
        _imageBytes = result!.files.single.bytes!;
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _updateText(String newText) {
    setState(() {
      _text = newText;
      _isEditing = false;
    });
  }

  Widget _buildTextBox() {
    return GestureDetector(
      onPanUpdate: (details) => _updateTextPosition(details.delta),
      onTap: _toggleEditMode,
      child: Container(
        width: _textBoxWidth,
        height: _textBoxHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Stack(
          children: [
            _isEditing
                ? _buildEditableTextField()
                : _buildTextDisplay(),
            _buildResizeHandle(),
          ],
        ),
      ),
    );
  }

  void _updateTextPosition(Offset delta) {
    setState(() {
      _textPosition += delta;
    });
  }

  Widget _buildEditableTextField() {
    return Positioned.fill(
      child: TextField(
        focusNode: _focusNode,
        autofocus: true,
        controller: _textController,
        onSubmitted: _updateText,
        decoration: InputDecoration(border: InputBorder.none),
        style: TextStyle(fontSize: _textBoxHeight / 2, color: Colors.white),
        cursorColor: Colors.white,
      ),
    );
  }

  Widget _buildTextDisplay() {
    return Center(
      child: Text(
        _text,
        style: TextStyle(fontSize: _textBoxHeight / 2, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResizeHandle() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onPanUpdate: (details) => _resizeTextBox(details.delta),
        child: Container(width: 20, height: 20, color: Colors.blue),
      ),
    );
  }

  void _resizeTextBox(Offset delta) {
    setState(() {
      _textBoxWidth = (_textBoxWidth + delta.dx).clamp(50.0, double.infinity);
      _textBoxHeight = (_textBoxHeight + delta.dy).clamp(20.0, double.infinity);
    });
  }

  void _closeEditMode() {
    if (_isEditing) {
      _toggleEditMode();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Text Editor')),
      body: GestureDetector(
        onTap: _closeEditMode,
        child: _imageBytes == null
            ? Center(
                child: ElevatedButton(
                  onPressed: _selectImage,
                  child: Text('Select Image'),
                ),
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: _textPosition.dx,
                    top: _textPosition.dy,
                    child: _buildTextBox(),
                  ),
                ],
              ),
      ),
    );
  }
}
