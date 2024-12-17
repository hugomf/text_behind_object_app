import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tflite/tflite.dart';
import 'dart:io'; // Import for working with files

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text Behind Application',
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
  Uint8List? _segmentationResult;
  Offset _textPosition = Offset(50, 50);
  String _text = "Enter Text";
  bool _isEditing = false;
  double _textBoxWidth = 150;
  double _textBoxHeight = 50;
  late FocusNode _focusNode;
  late TextEditingController _textController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textController = TextEditingController(text: _text);
    loadModel();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: 'assets/tflite/deeplabv3_257_mv_gpu.tflite',
        labels: 'assets/tflite/deeplabv3_257_mv_gpu.txt',
      );
    } catch (e) {
      print("Failed to load model: $e");
    }
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
      await predictImage(_imageBytes!);
    }
  }

Future<void> predictImage(Uint8List imageBytes) async {
  setState(() {
    _busy = true;
  });

  try {
    // Write the image bytes to a temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/temp_image.png');
    await tempFile.writeAsBytes(imageBytes);

    // Use the file path for Tflite prediction
    var recognitions = await Tflite.runSegmentationOnImage(
      path: tempFile.path, // Pass the file path
      imageMean: 0.0,
      imageStd: 255.0,
      outputType: "png",
      asynch: true,
    );

    setState(() {
      _segmentationResult = recognitions;
    });
  } catch (e) {
    print("Error during prediction: $e");
  } finally {
    setState(() {
      _busy = false;
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
      _isEditing = false; // Automatically close edit mode after updating text
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
          border: _isEditing
              ? Border.all(color: Colors.white, width: 2) // Only show border when editing
              : null, // No border when not editing
        ),
        child: Stack(
          children: [
            _isEditing
                ? _buildEditableTextField()
                : _buildTextDisplay(),
            if (_isEditing) _buildResizeHandle(), // Show resize handle only in edit mode
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
                  if (_segmentationResult != null)
                    Positioned.fill(
                      child: Image.memory(
                        _segmentationResult!,
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