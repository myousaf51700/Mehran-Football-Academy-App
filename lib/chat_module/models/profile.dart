import 'package:hive/hive.dart';

part 'profile.g.dart';

@HiveType(typeId: 1)
class Profile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String full_name;

  @HiveField(2)
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.full_name,
    required this.createdAt,
  });

  Profile.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        full_name = map['full_name'],
        createdAt = DateTime.parse(map['created_at']);
}