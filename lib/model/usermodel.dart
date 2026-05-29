class UserModal {
  final String  id;
  final String  username;
  final String  email;
  final String  age;
  final String  phone;
  final String  address;
  final String  city;
  final String? profilePic;  // ← Cloudinary URL, null if not set

  const UserModal({
    required this.id,
    required this.username,
    required this.email,
    required this.age,
    this.phone      = '',
    this.address    = '',
    this.city       = '',
    this.profilePic,
  });

  // ── Firestore → Model ──────────────────────────────────────────────────────
  factory UserModal.fromJson(Map<String, dynamic> json) => UserModal(
        id:         json['id']         ?? '',
        username:   json['username']   ?? '',
        email:      json['email']      ?? '',
        age:        json['age']        ?? '',
        phone:      json['phone']      ?? '',
        address:    json['address']    ?? '',
        city:       json['city']       ?? '',
        profilePic: json['profilePic'] as String?,  // ← reads from Firestore
      );

  // ── Model → Firestore ──────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id':         id,
        'username':   username,
        'email':      email,
        'age':        age,
        'phone':      phone,
        'address':    address,
        'city':       city,
        if (profilePic != null) 'profilePic': profilePic,
      };

  // ── Returns a copy with updated fields ────────────────────────────────────
  UserModal copyWith({
    String?  username,
    String?  email,
    String?  phone,
    String?  address,
    String?  city,
    String?  profilePic,
  }) =>
      UserModal(
        id:         id,
        username:   username   ?? this.username,
        email:      email      ?? this.email,
        age:        age,
        phone:      phone      ?? this.phone,
        address:    address    ?? this.address,
        city:       city       ?? this.city,
        profilePic: profilePic ?? this.profilePic,
      );
}