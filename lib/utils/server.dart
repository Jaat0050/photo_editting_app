import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_2/home/home.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference textCollection =
      FirebaseFirestore.instance.collection('texts');

  Future<void> addTextData(
    String documentId,
    List<TextData> textDataList,
    String? imageUrl,
  ) async {
    await textCollection.doc(documentId).set({
      'texts': textDataList.map((textData) => textData.toJson()).toList(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    });

    // Print the document ID for reference
    print('id= ${documentId}');

    // await SharedPreferencesHelper.incrementCounter();
  }

  Stream<List<TextData>> getTextData(String documentId) {
    return textCollection.doc(documentId).snapshots().map(
      (snapshot) {
        if (snapshot.data() != null) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          return (data['texts'] as List<dynamic>)
              .map((item) => TextData.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          // Handle the case when the document does not exist
          return [];
        }
      },
    );
  }

  Stream<List<String>> getDocumentIdsStream() {
    return _firestore
        .collection('texts') // Correct collection name
        .snapshots()
        .map((snapshot) {
      List<String> documentIds = [];
      for (var doc in snapshot.docs) {
        documentIds.add(doc.id);
      }
      return documentIds;
    });
  }

  Future<List<String>> getAllDocumentIds() async {
    QuerySnapshot querySnapshot = await textCollection.get();
    List<String> documentIds = querySnapshot.docs.map((doc) => doc.id).toList();
    return documentIds;
  }

  Future<void> clearTextsCollection() async {
    QuerySnapshot querySnapshot = await textCollection.get();
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      await textCollection.doc(doc.id).delete();
    }
  }

  Future<void> clearFirebaseStorage() async {
    Reference storageReference = FirebaseStorage.instance.ref('images');
    try {
      ListResult result = await storageReference.listAll();
      for (Reference reference in result.items) {
        await reference.delete();
      }
    } catch (e) {
      print('Error clearing Firebase Storage: $e');
      // Handle the error as needed
    }
  }

  Future<String?> getImageUrl(String documentId) async {
    try {
      DocumentSnapshot snapshot = await textCollection.doc(documentId).get();

      if (snapshot.exists) {
        return snapshot['imageUrl'] as String?;
      } else {
        print('Document does not exist');
        return null;
      }
    } catch (e) {
      print('Error getting image URL: $e');
      return null;
    }
  }
}
