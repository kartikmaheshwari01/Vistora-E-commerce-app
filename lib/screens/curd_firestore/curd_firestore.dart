import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_flutter/model/usermodel.dart';
import 'package:fire_flutter/screens/update_screen.dart';
import 'package:fire_flutter/signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Curd extends StatefulWidget {
  const Curd({super.key});

  @override
  State<Curd> createState() => _CurdState();
}

class _CurdState extends State<Curd> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<List<UserModal>> getRealTimeUserData() {
    return firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return UserModal.fromJson(data);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "All Users",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Sign_Up()),
          );
        },
        backgroundColor: Colors.green.shade600,
        icon: Icon(Icons.person_add_alt_1, color: Colors.white),
        label: Text(
          "Add User",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 24, top: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Center(
              child: Text(
                "Manage your users below",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<UserModal>>(
              stream: getRealTimeUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: Lottie.asset(
                        'assets/animations/Sandy Loading.json',
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (snapshot.hasData) {
                  List<UserModal> users = snapshot.data!;

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.green.shade200,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "No users found",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.08),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.green.shade50,
                                child: Text(
                                  (users[index].username ?? 'U')[0]
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),

                              SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      users[index].username ?? 'No Name',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 14,
                                          color: Colors.green.shade400,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            users[index].email ?? 'No Email',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.cake_outlined,
                                          size: 14,
                                          color: Colors.green.shade400,
                                        ),
                                        SizedBox(width: 4),
                                        // Text(
                                        //   "Age: ${users[index].age ?? 'N/A'}",
                                        //   style: TextStyle(
                                        //     fontSize: 13,
                                        //     color: Colors.grey.shade600,
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 8),

                              Column(
                                children: [
                                  // Edit button — green
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UpdateScreen(
                                            updateUser: users[index],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 8),

                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            title: Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Delete User",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: Text(
                                              "Are you sure you want to delete \"${users[index].username}\"? This action cannot be undone.",
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  dialogContext,
                                                ),
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red.shade600,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  Navigator.pop(dialogContext);
                                                  await firestore
                                                      .collection("Users")
                                                      .doc(users[index].id)
                                                      .delete();
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        backgroundColor:
                                                            Colors.red.shade600,
                                                        content: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              "User deleted successfully",
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Text("Delete"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.red.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Center(child: Text("No users found."));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
