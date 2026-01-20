import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mehran_football_academy/chat_module/models/message.dart';
import 'package:mehran_football_academy/chat_module/models/profile.dart';

class LocalStorage {
  static const String _messagesBox = 'messagesBox';
  static const String _profilesBox = 'profilesBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MessageAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProfileAdapter());
    }

    await Hive.openBox<Message>(_messagesBox);
    await Hive.openBox<Profile>(_profilesBox);
  }

  static Box<Message> get messagesBox => Hive.box<Message>(_messagesBox);
  static Box<Profile> get profilesBox => Hive.box<Profile>(_profilesBox);

  static Future<void> saveMessages(List<Message> messages) async {
    final box = messagesBox;
    await box.clear();
    for (var message in messages) {
      await box.put(message.id, message);
    }
  }

  static Future<void> addMessage(Message message) async {
    final box = messagesBox;
    await box.put(message.id, message);
  }

  static Future<void> saveProfiles(List<Profile> profiles) async {
    final box = profilesBox;
    await box.clear();
    for (var profile in profiles) {
      await box.put(profile.id, profile);
    }
  }

  static List<Message> getCachedMessages() {
    return messagesBox.values.toList();
  }

  static Profile? getCachedProfile(String profileId) {
    return profilesBox.get(profileId);
  }

  static List<Profile> getCachedProfiles() {
    return profilesBox.values.toList();
  }

  static Profile? getProfileById(String profileId) {
    return profilesBox.get(profileId);
  }
}