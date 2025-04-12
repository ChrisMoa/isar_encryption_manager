abstract class DatabaseEvent {}

class PickDatabaseFile extends DatabaseEvent {}

class CheckEncryptionStatus extends DatabaseEvent {}

class EncryptDatabase extends DatabaseEvent {
  final String password;

  EncryptDatabase(this.password);
}

class DecryptDatabase extends DatabaseEvent {
  final String password;

  DecryptDatabase(this.password);
}

class LoadDatabaseInfo extends DatabaseEvent {}
