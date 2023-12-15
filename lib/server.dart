import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/home.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference textCollection =
      FirebaseFirestore.instance.collection('texts');

  Future<void> addTextData(List<TextData> textDataList) async {
    DocumentReference docRef = await textCollection.add({
      'texts': textDataList.map((textData) => textData.toJson()).toList(),
    });

    // Print the document ID for reference
    print('Document ID: ${docRef.id}');
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
}
