import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/utils/server.dart';
import 'package:flutter_application_2/utils/shared_helper.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirestoreService firestoreService = FirestoreService();
  final List<List<List<TextData>>> _undoStack = [];
  final List<List<List<TextData>>> _redoStack = [];

  Image? _selectedImage;
  XFile? _pickedFile;

  final CollectionReference textCollection =
      FirebaseFirestore.instance.collection('texts');

  // List<String> _documentIds = [];
  // int _counter = 1;

  List<TextData> _texts = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = Image.file(File(pickedFile.path));
        _pickedFile = pickedFile;
      });
    }
  }

  void _resetApp() {
    setState(() {
      _texts = [];
      _selectedImage = null;
    });
    _updateUndoRedoStack();
  }

  void _updateUndoRedoStack() {
    _undoStack.add(List.generate(_texts.length, (index) => List.from(_texts)));
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      final previousStates = _undoStack.removeLast();
      _redoStack.add(
          List.generate(previousStates.length, (index) => List.from(_texts)));
      setState(() {
        _texts =
            previousStates.isNotEmpty ? List.from(previousStates.last) : [];
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final nextStates = _redoStack.removeLast();
      _undoStack
          .add(List.generate(nextStates.length, (index) => List.from(_texts)));
      setState(() {
        _texts = nextStates.isNotEmpty ? List.from(nextStates.last) : [];
      });
    }
  }

  void _updateUndoRedoStackWithTextData(List<TextData> texts) {
    _undoStack.add(List.generate(texts.length, (index) => List.from(_texts)));
    _redoStack.clear();
    setState(() {
      _texts = List.from(texts);
    });
  }

  void _addText() {
    setState(() {
      _texts.add(
        TextData(
          position: const Offset(100, 100),
          text: 'New text',
          fontSize: 24.0,
          color: Colors.white,
          textAlign: TextAlign.center,
          fontWeight: FontWeight.normal,
          fontFamily: 'Roboto',
          alignmentSelections: [true, false, false],
          lineHeight: 1.0,
        ),
      );
      _updateUndoRedoStack();
    });
  }

  void _showRemoveDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Text'),
          content: const Text('Are you sure you want to remove this text?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  _texts.removeAt(index);
                  _updateUndoRedoStack();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TextEditDialog(
          initialFontSize: _texts[index].fontSize,
          initialColor: _texts[index].color,
          initialText: _texts[index].text,
          initialTextAlign: _texts[index].textAlign,
          initialFontWeight: _texts[index].fontWeight,
          initialFontFamily: _texts[index].fontFamily,
          initialAlignmentSelections: _texts[index].alignmentSelections,
          initialLineHeight: _texts[index].lineHeight,
          onSubmitted: (
            String newText,
            double newFontSize,
            Color newColor,
            TextAlign newTextAlign,
            FontWeight newFontWeight,
            double newLineHeight,
            String newFontFamily,
          ) {
            final updatedTextData = TextData(
              position: _texts[index].position,
              text: newText,
              fontSize: newFontSize,
              color: newColor,
              textAlign: newTextAlign,
              fontWeight: newFontWeight,
              lineHeight: newLineHeight,
              fontFamily: newFontFamily,
              alignmentSelections: _texts[index].alignmentSelections,
            );

            final List<TextData> updatedTexts = List.from(_texts);
            updatedTexts[index] = updatedTextData;

            setState(() {
              _texts = updatedTexts;
            });
            _updateUndoRedoStackWithTextData(updatedTexts);
          },
        );
      },
    );
  }

  void onPanUpdate(DragUpdateDetails details, int index) {
    double newX = _texts[index].position.dx + details.delta.dx;
    double newY = _texts[index].position.dy + details.delta.dy;
    setState(() {
      _texts[index].position = Offset(newX, newY);
    });
  }

  Future<String?> _uploadImage(File imageFile, String documentId) async {
    try {
      final Reference storageReference =
          FirebaseStorage.instance.ref().child('images/$documentId.jpg');
      final UploadTask uploadTask = storageReference.putFile(imageFile);
      await uploadTask.whenComplete(() => null);
      return await storageReference.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateFirestore() async {
    int documentNumber = await SharedPreferencesHelper.getCounter();
    String documentId = '$documentNumber';
    // Upload the image and get its download URL
    String? imageUrl;
    if (_pickedFile != null) {
      imageUrl = await _uploadImage(File(_pickedFile!.path), documentId);
    }
    // Save text data along with image URL to Firestore
    firestoreService.addTextData(documentId, _texts, imageUrl);
    await SharedPreferencesHelper.incrementCounter();
  }

  void _fetchDataFromFirebaseAndClearSharedPreferences1() async {
    try {
      print('delete');
      // Clear all data from the "texts" collection in Firebase
      await firestoreService.clearTextsCollection();
      // Clear all images from the "images" collection in storage
      await firestoreService.clearFirebaseStorage();
      // Clear SharedPreferences
      await SharedPreferencesHelper.clearCounter();
      // Delete images from storage
      List<String> documentIds = await firestoreService.getAllDocumentIds();
      for (String documentId in documentIds) {
        String? imageUrl = await firestoreService.getImageUrl(documentId);
        if (imageUrl != null) {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        }
      }
      // Update the state with an empty list
      setState(() {
        _texts = [];
        _selectedImage = null;
      });
    } catch (e) {
      print('Error deleting data and images: $e');
      // Handle the error as needed
    }
  }

  void _fetchDataFromFirebaseAndClearSharedPreferences(
      String documentId) async {
    print('next');
    firestoreService.getTextData(documentId).listen((data) {
      setState(() {
        _texts = data;
      });
    });
    // Fetch image URL for the selected document ID
    firestoreService.getImageUrl(documentId).then((imageUrl) {
      if (imageUrl != null) {
        setState(() {
          _selectedImage = Image.network(imageUrl, fit: BoxFit.cover);
        });
      } else {
        setState(() {
          _selectedImage = null;
        });
      }
    });
  }

  Future<void> clearTextsCollection() async {
    QuerySnapshot querySnapshot = await textCollection.get();
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      await textCollection.doc(doc.id).delete();
    }
  }

  @override
  void initState() {
    super.initState();
    _updateUndoRedoStack();
    _updateUndoRedoStackWithTextData(_texts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('My App'),
        backgroundColor: Colors.grey[200],
        elevation: 10,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () {
              _pickImage(); // Function to pick an image
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateFirestore,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redo,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addText,
          ),
          IconButton(
            icon: const Icon(Icons.replay_circle_filled_rounded),
            onPressed: () {
              // Reset the app to its initial state
              _resetApp();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Fetch data from Firebase and clear SharedPreferences
              _fetchDataFromFirebaseAndClearSharedPreferences1();
            },
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: _selectedImage != null
              ? DecorationImage(
                  image: _selectedImage!.image,
                  fit: BoxFit.cover,
                )
              : const DecorationImage(
                  image: AssetImage('images/pic.jpg'),
                  fit: BoxFit.cover,
                ),
        ),
        child: Stack(
          children: _texts.map((textData) {
            return Positioned(
              left: textData.position.dx,
              top: textData.position.dy,
              child: GestureDetector(
                onDoubleTap: () => _showRemoveDialog(_texts.indexOf(textData)),
                onTap: () => _showEditDialog(_texts.indexOf(textData)),
                onPanUpdate: (details) =>
                    onPanUpdate(details, _texts.indexOf(textData)),
                child: SizedBox(
                  width: 300,
                  child: Center(
                    child: Stack(
                      children: [
                        Text(
                          textData.text,
                          style: TextStyle(
                            fontSize: textData.fontSize,
                            color: textData.color,
                            fontWeight: textData.fontWeight,
                            fontFamily: textData.fontFamily,
                            height: textData.lineHeight,
                          ),
                          textAlign: textData.textAlign,
                        ),
                      ],
                    ),
                  ),
                ),
                // Add other properties as needed
              ),
            );
          }).toList(),
        ),
      ),
      drawer: Drawer(
        width: 250,
        backgroundColor: Colors.white,
        elevation: 10,
        shadowColor: Colors.black,
        child: FutureBuilder<List<String>>(
          future: firestoreService.getAllDocumentIds(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(
                // strokeWidth: 20,
                color: Colors.black,
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              List<String> sortedDocumentIds = snapshot.data!;
              sortedDocumentIds.sort(
                (a, b) => int.parse(a).compareTo(
                  int.parse(b),
                ),
              ); // Parse and sort document IDs as integers
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      color: Colors.red[100],
                    ),
                    child: const Text(
                      'Documents',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Charm',
                        fontSize: 24,
                      ),
                    ),
                  ),
                  for (int i = 0; i < sortedDocumentIds.length; i++)
                    InkWell(
                      hoverColor: Colors.red,
                      onTap: () {
                        _fetchDataFromFirebaseAndClearSharedPreferences(
                            sortedDocumentIds[i]);
                        // Fetch texts for the selected document ID
                        setState(() {
                          _texts = []; // Clear existing texts
                        });

                        firestoreService
                            .getTextData(sortedDocumentIds[i])
                            .listen((data) {
                          setState(() {
                            _texts = data;
                          });
                        });

                        Navigator.pop(context); // Close the drawer
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(
                                  0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          hoverColor: Colors.red,
                          tileColor: Colors.white,
                          title: Center(
                            child: Text(
                              'document: ${sortedDocumentIds[i]}',
                              style: const TextStyle(
                                fontFamily: 'Lora',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class TextData {
  Offset position;
  String text;
  double fontSize;
  Color color;
  TextAlign textAlign;
  FontWeight fontWeight;
  String fontFamily;
  List<bool> alignmentSelections;
  double lineHeight;
  String? imageUrl;

  TextData({
    required this.position,
    required this.text,
    required this.fontSize,
    required this.color,
    required this.textAlign,
    required this.fontWeight,
    required this.fontFamily,
    required this.alignmentSelections,
    required this.lineHeight,
    this.imageUrl,
  });

  factory TextData.fromJson(Map<String, dynamic> json) {
    return TextData(
      position: Offset(json['dx'], json['dy']),
      text: json['text'],
      fontSize: json['fontSize'],
      color: Color(json['color']),
      textAlign: TextAlign.values[json['textAlign']],
      fontWeight: FontWeight.values[json['fontWeight']],
      fontFamily: json['fontFamily'],
      alignmentSelections: List<bool>.from(json['alignmentSelections']),
      lineHeight: json['lineHeight'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dx': position.dx,
      'dy': position.dy,
      'text': text,
      'fontSize': fontSize,
      'color': color.value,
      'textAlign': textAlign.index,
      'fontWeight': fontWeight.index,
      'fontFamily': fontFamily,
      'alignmentSelections': alignmentSelections,
      'lineHeight': lineHeight,
      'imageUrl': imageUrl,
    };
  }
}

class TextEditDialog extends StatefulWidget {
  final double initialFontSize;
  final Color initialColor;
  final String initialText;
  final TextAlign initialTextAlign;
  final FontWeight initialFontWeight;
  final String initialFontFamily;
  final double initialLineHeight;
  final List<bool> initialAlignmentSelections;
  final Function(
    String,
    double,
    Color,
    TextAlign,
    FontWeight,
    double,
    String,
  ) onSubmitted;

  const TextEditDialog({
    Key? key,
    required this.initialFontSize,
    required this.initialColor,
    required this.initialText,
    required this.initialTextAlign,
    required this.initialFontWeight,
    required this.initialFontFamily,
    required this.initialAlignmentSelections,
    required this.initialLineHeight,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<TextEditDialog> {
  late double fontSize;
  late Color color;
  late String text;
  late TextAlign textAlign;
  late FontWeight fontWeight;
  late String fontFamily;
  late List<bool> alignmentSelections;
  late TextEditingController textController;

  List<double> fontSizes = [12, 14, 16, 18, 20, 24, 28, 32, 36, 40];

  late double _lineHeight;
  List<double> lineHeightOptions = [1.0, 1.5, 2.0, 2.5, 3.0];

  // Add more font families as needed
  List<String> fontFamilies = ['Roboto', 'Lora', 'Charm'];

  // Add font weights if needed
  List<FontWeight> fontWeights = [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ];
  String _selectedTextAlign = 'Left'; // Default to left alignment

  Map<String, TextAlign> textAlignOptions = {
    'L': TextAlign.left,
    'C': TextAlign.center,
    'R': TextAlign.right,
  };

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: color,
              onColorChanged: (Color newColor) {
                // Update the color locally within this dialog
                color = newColor;
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                // When the 'Got it' button is pressed, update the color in the TextEditDialog state.
                setState(() {
                  color = color; // Update the color in the main dialog's state
                });
                Navigator.of(context).pop(); // Close the color picker dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fontSize = widget.initialFontSize;
    color = widget.initialColor;
    text = widget.initialText;
    textAlign = widget.initialTextAlign;
    fontWeight = widget.initialFontWeight;
    fontFamily = widget.initialFontFamily;
    alignmentSelections = List.from(widget.initialAlignmentSelections);
    textController = TextEditingController(text: text);
    _lineHeight = widget.initialLineHeight;
    textAlign = widget.initialTextAlign;
    _selectedTextAlign = textAlignOptions.entries
        .firstWhere((entry) => entry.value == textAlign,
            orElse: () => const MapEntry('Left', TextAlign.left))
        .key;
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(left: 10, right: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextField(
                  maxLines: 3,
                  controller: textController,
                  decoration: const InputDecoration(
                    focusedBorder: InputBorder.none,
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    text = value;
                  },
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              //------------------------------------------------------------------------------//
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //--------------------------------------------------------------------------------//
                  Container(
                    width: 130,
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: fontFamily, // Use the state variable
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        setState(() {
                          fontFamily = newValue!; // Update the state variable
                        });
                      },
                      items: fontFamilies
                          .map<DropdownMenuItem<String>>((String family) {
                        return DropdownMenuItem<String>(
                          value: family,
                          child: Text(family),
                        );
                      }).toList(),
                    ),
                  ),
                  //------------------------------------------------------------------------------//
                  Container(
                    width: 130,
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: DropdownButton<FontWeight>(
                      isExpanded: true,
                      value: fontWeight,
                      underline: const SizedBox(),
                      onChanged: (FontWeight? newValue) {
                        setState(() {
                          fontWeight = newValue!;
                        });
                      },
                      items: fontWeights.map<DropdownMenuItem<FontWeight>>(
                          (FontWeight weight) {
                        return DropdownMenuItem<FontWeight>(
                          value: weight,
                          child: Text(
                            weight.toString().split('.').last,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              //-------------------------------------------------------------------------------------//
              const SizedBox(
                height: 15,
              ),
              Container(
                height: 70,
                padding: const EdgeInsets.only(left: 10, right: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //--------------------------------------------------------------------------//
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 55,
                          height: 30,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: DropdownButton<double>(
                            isExpanded: true,
                            value: fontSize,
                            iconSize: 15,
                            underline: const SizedBox(),
                            onChanged: (double? newValue) {
                              setState(() {
                                fontSize = newValue!;
                              });
                            },
                            items: fontSizes
                                .map<DropdownMenuItem<double>>((double size) {
                              return DropdownMenuItem<double>(
                                value: size,
                                child: Text(
                                  size.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Text(
                          'Font Size',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    //----------------------------------------------------------------------------------------------//
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ElevatedButton(
                            onPressed: _openColorPicker,
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(color)),
                            child: Text(
                              '',
                              style: TextStyle(
                                  fontSize: 1,
                                  color: useWhiteForeground(color)
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          ),
                        ),
                        const Text(
                          'Color',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    //---------------------------------------------------------------------------------//
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 55,
                            height: 30,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: DropdownButton<double>(
                              iconSize: 15,
                              isExpanded: true,
                              value: _lineHeight,
                              underline: const SizedBox(),
                              onChanged: (double? newValue) {
                                setState(() {
                                  _lineHeight = newValue!;
                                });
                              },
                              items: lineHeightOptions
                                  .map<DropdownMenuItem<double>>(
                                      (double value) {
                                return DropdownMenuItem<double>(
                                  value: value,
                                  child: Text(
                                    value.toString(),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                            )),
                        const Text(
                          'Line Height',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    //------------------------------------------------------------------------------//
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 55,
                            height: 30,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedTextAlign,
                              iconSize: 15,
                              isExpanded: true,
                              underline: const SizedBox(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedTextAlign = newValue!;
                                  textAlign =
                                      textAlignOptions[_selectedTextAlign]!;
                                });
                              },
                              items: textAlignOptions.keys
                                  .map<DropdownMenuItem<String>>((String key) {
                                return DropdownMenuItem<String>(
                                  value: key,
                                  child: Text(
                                    key,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                            )),
                        const Text(
                          'Alignment',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Done'),
          onPressed: () {
            widget.onSubmitted(
              text,
              fontSize,
              color,
              textAlign,
              fontWeight,
              _lineHeight,
              fontFamily,
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
