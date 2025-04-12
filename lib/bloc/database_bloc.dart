// lib/bloc/database_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_encryption_manager/services/database_service.dart';
import 'database_event.dart';
import 'database_state.dart';

class DatabaseBloc extends Bloc<DatabaseEvent, DatabaseState> {
  final DatabaseService _databaseService;
  String? _selectedFilePath;

  DatabaseBloc(this._databaseService) : super(DatabaseInitial()) {
    on<PickDatabaseFile>(_onPickDatabaseFile);
    on<CheckEncryptionStatus>(_onCheckEncryptionStatus);
    on<EncryptDatabase>(_onEncryptDatabase);
    on<DecryptDatabase>(_onDecryptDatabase);
    on<LoadDatabaseInfo>(_onLoadDatabaseInfo);
  }

  Future<void> _onPickDatabaseFile(
    PickDatabaseFile event,
    Emitter<DatabaseState> emit,
  ) async {
    emit(DatabaseLoading());

    try {
      final filePath = await _databaseService.pickDatabaseFile();
      if (filePath != null) {
        _selectedFilePath = filePath;
        emit(DatabaseFileSelected(filePath));
      } else {
        emit(DatabaseInitial());
      }
    } catch (e) {
      emit(DatabaseError("Failed to pick file: ${e.toString()}"));
    }
  }

  Future<void> _onCheckEncryptionStatus(
    CheckEncryptionStatus event,
    Emitter<DatabaseState> emit,
  ) async {
    if (_selectedFilePath == null) {
      emit(DatabaseError("No database file selected"));
      return;
    }

    emit(DatabaseLoading());

    try {
      final isEncrypted = await _databaseService.isEncrypted(
        _selectedFilePath!,
      );
      emit(EncryptionStatusChecked(isEncrypted, _selectedFilePath!));
    } catch (e) {
      emit(DatabaseError("Failed to check encryption status: ${e.toString()}"));
    }
  }

  Future<void> _onEncryptDatabase(
    EncryptDatabase event,
    Emitter<DatabaseState> emit,
  ) async {
    if (_selectedFilePath == null) {
      emit(DatabaseError("No database file selected"));
      return;
    }

    emit(DatabaseLoading());

    try {
      await _databaseService.encryptDatabase(
        _selectedFilePath!,
        event.password,
      );
      emit(DatabaseEncrypted(_selectedFilePath!));

      // After encryption, update the status and info
      add(CheckEncryptionStatus());
      add(LoadDatabaseInfo());
    } catch (e) {
      emit(DatabaseError("Failed to encrypt database: ${e.toString()}"));
    }
  }

  Future<void> _onDecryptDatabase(
    DecryptDatabase event,
    Emitter<DatabaseState> emit,
  ) async {
    if (_selectedFilePath == null) {
      emit(DatabaseError("No database file selected"));
      return;
    }

    emit(DatabaseLoading());

    try {
      await _databaseService.decryptDatabase(
        _selectedFilePath!,
        event.password,
      );
      emit(DatabaseDecrypted(_selectedFilePath!));

      // After decryption, update the status and info
      add(CheckEncryptionStatus());
      add(LoadDatabaseInfo());
    } catch (e) {
      emit(DatabaseError("Failed to decrypt database: ${e.toString()}"));
    }
  }

  Future<void> _onLoadDatabaseInfo(
    LoadDatabaseInfo event,
    Emitter<DatabaseState> emit,
  ) async {
    if (_selectedFilePath == null) {
      emit(DatabaseError("No database file selected"));
      return;
    }

    emit(DatabaseLoading());

    try {
      final info = await _databaseService.getDatabaseInfo(_selectedFilePath!);
      final keys = await _databaseService.getDatabaseKeys(_selectedFilePath!);
      emit(DatabaseInfoLoaded(keys, info, _selectedFilePath!));
    } catch (e) {
      emit(DatabaseError("Failed to load database info: ${e.toString()}"));
    }
  }
}
