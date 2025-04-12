abstract class DatabaseState {}

class DatabaseInitial extends DatabaseState {}

class DatabaseLoading extends DatabaseState {}

class DatabaseFileSelected extends DatabaseState {
  final String filePath;

  DatabaseFileSelected(this.filePath);
}

class EncryptionStatusChecked extends DatabaseState {
  final bool isEncrypted;
  final String filePath;

  EncryptionStatusChecked(this.isEncrypted, this.filePath);
}

class DatabaseEncrypted extends DatabaseState {
  final String filePath;

  DatabaseEncrypted(this.filePath);
}

class DatabaseDecrypted extends DatabaseState {
  final String filePath;

  DatabaseDecrypted(this.filePath);
}

class DatabaseInfoLoaded extends DatabaseState {
  final List<String> keys;
  final Map<String, dynamic> info;
  final String filePath;

  DatabaseInfoLoaded(this.keys, this.info, this.filePath);
}

class DatabaseError extends DatabaseState {
  final String message;

  DatabaseError(this.message);
}
