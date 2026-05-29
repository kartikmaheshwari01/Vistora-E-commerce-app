import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_flutter/model/usermodel.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class UpdateScreen extends StatefulWidget {
  final UserModal updateUser;
  const UpdateScreen({super.key, required this.updateUser});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool isLoading = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final RegExp emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  void assignControllerValue() {
    emailController.text = widget.updateUser.email ?? '';
    nameController.text = widget.updateUser.username ?? '';
  }

  @override
  void initState() {
    super.initState();
    assignControllerValue();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.08), // ✅ theme primary shadow
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.87)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.hintColor),
          prefixIcon: Icon(
            icon,
            color: theme.primaryColor,
            size: 22,
          ), // ✅ theme primary icon
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.primaryColor.withOpacity(0.7),
              width: 1.5,
            ), // ✅ theme primary focus border
          ),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ theme clean white-ish or dark bg
      appBar: AppBar(
        backgroundColor: theme.primaryColor, // ✅ theme primary appbar
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.appBarTheme.iconTheme?.color ?? Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          // ✅ theme primary curved header behind avatar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // ✅ Avatar with theme ring
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.cardColor,
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.5),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 52,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.primaryColor,
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: theme.appBarTheme.iconTheme?.color ?? Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // ✅ Username and email below avatar
                Text(
                  widget.updateUser.username ?? 'User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColorDark,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  widget.updateUser.email ?? '',
                  style: TextStyle(fontSize: 13, color: theme.hintColor),
                ),

                SizedBox(height: 28),

                // ✅ Form card
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.07),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Section label with theme primary left border
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Update Info",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColorDark,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      _buildTextField(
                        controller: nameController,
                        hint: "Username",
                        icon: Icons.account_circle_outlined,
                      ),

                      SizedBox(height: 16),

                      _buildTextField(
                        controller: emailController,
                        hint: "Email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      SizedBox(height: 16),

                      // ✅ Save button — full width theme primary
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.appBarTheme.iconTheme?.color ?? Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            setState(() => isLoading = true);
                            try {
                              UserModal updatemodel = UserModal(
                                id: widget.updateUser.id,
                                username: nameController.text.trim(),
                                email: emailController.text.trim(),
                                age: ageController.text.trim(),
                                phone: phoneController.text.trim(),
                                address: addressController.text.trim(),
                                city: cityController.text.trim(),
                              );

                              await firestore
                                  .collection("Users")
                                  .doc(widget.updateUser.id)
                                  .update(updatemodel.toJson());

                              setState(() => isLoading = false);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: theme.primaryColor,
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: theme.appBarTheme.iconTheme?.color ?? Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text("Profile updated successfully!"),
                                      ],
                                    ),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              setState(() => isLoading = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: theme.colorScheme.error,
                                    content: Text("Error: ${e.toString()}"),
                                  ),
                                );
                              }
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_outlined, color: theme.appBarTheme.iconTheme?.color ?? Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isLoading)
            Positioned.fill(
              child: Center(
                child: Lottie.asset(
                  "assets/animations/Sandy Loading.json",
                  width: 150,
                  height: 150,
                ),
              ),
            ),
        ],
      ),
    );
  }
}