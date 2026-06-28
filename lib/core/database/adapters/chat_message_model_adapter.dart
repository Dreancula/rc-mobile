import 'package:hive/hive.dart';
import '../../../features/home/domain/models/chat_message_model.dart';

class ChatMessageModelAdapter extends TypeAdapter<ChatMessageModel> {
  @override
  final int typeId = 6;

  @override
  ChatMessageModel read(BinaryReader reader) {
    return ChatMessageModel.fromMap(reader.readMap().cast<String, dynamic>());
  }

  @override
  void write(BinaryWriter writer, ChatMessageModel obj) {
    writer.writeMap(obj.toMap());
  }
}
