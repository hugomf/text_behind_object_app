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
  Uint8List? _imageBytes;
  Offset _textPosition = Offset(50, 50);
  String _text = "Enter Text";
  bool _isEditing = false;
  double _textBoxWidth = 150;
  double _textBoxHeight = 50;

  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
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

  void _closeEditMode() {
    if (_isEditing) {
      setState(() {
        _isEditing = false;
      });
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
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _textPosition += details.delta;
                        });
                      },
                      onTap: () {
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                      child: Container(
                        width: _textBoxWidth,
                        height: _textBoxHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _isEditing
                                  ? TextField(
                                      focusNode: _focusNode,
                                      autofocus: true,
                                      controller: TextEditingController(
                                          text: _text),
                                      onSubmitted: (newText) {
                                        setState(() {
                                          _text = newText;
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
                                      cursorColor: Colors.white,
                                    )
                                  : Center(
                                      child: Text(
                                        _text,
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

                                    _textBoxWidth = _textBoxWidth < 50
                                        ? 50
                                        : _textBoxWidth;
                                    _textBoxHeight = _textBoxHeight < 20
                                        ? 20
                                        : _textBoxHeight;
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
