import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminProductsScreen extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;

  AdminProductsScreen({super.key});

  Future<void> deleteProduct(String docId, String publicId) async {
    // delete firestore
    await _firestore.collection('products').doc(docId).delete();

    // NOTE: Cloudinary delete should be done via backend in real apps
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Products")),
      body: StreamBuilder(
        stream: _firestore.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: Image.network(
                    data['img'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(data['name']),
                  subtitle: Text(data['price']),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await deleteProduct(
                        data.id,
                        data['publicId'],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
