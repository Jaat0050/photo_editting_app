import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/home/text_edit.dart';
import 'package:flutter_application_2/utils/server.dart';
import 'package:flutter_application_2/utils/shared_helper.dart';
import 'package:flutter_application_2/utils/text_model.dart';
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

  List<TextData> _texts = [];

  //------------------------------------pick image function------------------------------------------//
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

  //------------------------------------reset app--------------------------------------------------//
  void _resetApp() {
    setState(() {
      _texts = [];
      _selectedImage = null;
    });
    _updateUndoRedoStack();
  }

  //------------------------------------redo undo section------------------------------------------//
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
  //------------------------------------------------------------------------------------//

  //------------------------------------add new text------------------------------------------//
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

  //----------------------------------------text dragging---------------------------------------------//
  void onPanUpdate(DragUpdateDetails details, int index) {
    double newX = _texts[index].position.dx + details.delta.dx;
    double newY = _texts[index].position.dy + details.delta.dy;
    setState(() {
      _texts[index].position = Offset(newX, newY);
    });
  }

  //-------------------------------------------fire base----------------------------------------------------//
  Future<String?> _uploadImage(File imageFile, String documentId) async {
    try {
      final Reference storageReference =
          FirebaseStorage.instance.ref().child('images/$documentId.jpg');
      final UploadTask uploadTask = storageReference.putFile(imageFile);
      await uploadTask.whenComplete(() => null);
      return await storageReference.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      return null;
    }
  }

  //------------add to firebase---------//
  Future<void> _updateFirestore() async {
    int documentNumber = SharedPreferencesHelper.getCounter();
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

  //------------clear everything from firebase------------------//
  void _fetchDataFromFirebaseAndClearSharedPreferences1() async {
    try {
      if (kDebugMode) {
        print('delete');
      }
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
      if (kDebugMode) {
        print('Error deleting data and images: $e');
      }
    }
  }

  //------------fetch images from firebase------------//
  void _fetchDataFromFirebaseAndClearSharedPreferences(
      String documentId) async {
    if (kDebugMode) {
      print('next');
    }
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

  //------------clear firebase------------//
  Future<void> clearTextsCollection() async {
    QuerySnapshot querySnapshot = await textCollection.get();
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      await textCollection.doc(doc.id).delete();
    }
  }
  //----------------------------------------------------------------------------------------------------//

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
        backgroundColor: Colors.grey[200],
        elevation: 10,
        actions: [
          //------------------------add photo-------------------------//
          IconButton(
              icon: const Icon(Icons.add_photo_alternate),
              onPressed: () {
                _pickImage();
              }),
          //------------------------save in firebase-----------------//
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateFirestore,
          ),
          //------------------------undo----------------------------//
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
          ),
          //------------------------redo---------------------------//
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redo,
          ),
          //------------------------add text-----------------------//
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addText,
          ),
          //------------------------reset app-----------------------//
          IconButton(
            icon: const Icon(Icons.replay_circle_filled_rounded),
            onPressed: () {
              _resetApp();
            },
          ),
          //------------------------Clear everything-----------------------//
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
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
}
