// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/database_bloc.dart';
import 'bloc/database_event.dart';
import 'bloc/database_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Isar Database Encryption Manager'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<DatabaseBloc, DatabaseState>(
          listener: (context, state) {
            if (state is DatabaseError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is DatabaseEncrypted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Database encrypted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is DatabaseDecrypted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Database decrypted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is DatabaseFileSelected) {
              context.read<DatabaseBloc>().add(LoadDatabaseInfo());
              context.read<DatabaseBloc>().add(CheckEncryptionStatus());
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File selection section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Database',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<DatabaseBloc>().add(
                              PickDatabaseFile(),
                            );
                          },
                          icon: const Icon(Icons.file_open),
                          label: const Text('Select Isar Database File'),
                        ),
                        if (state is DatabaseFileSelected ||
                            state is EncryptionStatusChecked ||
                            state is DatabaseInfoLoaded ||
                            state is DatabaseEncrypted ||
                            state is DatabaseDecrypted)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Selected file: ${(state as dynamic).filePath}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Encryption status section
                if (state is DatabaseFileSelected ||
                    state is EncryptionStatusChecked ||
                    state is DatabaseInfoLoaded ||
                    state is DatabaseEncrypted ||
                    state is DatabaseDecrypted)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Encryption Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<DatabaseBloc>().add(
                                    CheckEncryptionStatus(),
                                  );
                                },
                                icon: const Icon(Icons.security),
                                label: const Text('Check Encryption Status'),
                              ),
                              const SizedBox(width: 16),
                              if (state is EncryptionStatusChecked)
                                Row(
                                  children: [
                                    Icon(
                                      state.isEncrypted
                                          ? Icons.lock
                                          : Icons.lock_open,
                                      color:
                                          state.isEncrypted
                                              ? Colors.red
                                              : Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      state.isEncrypted
                                          ? 'Database is encrypted'
                                          : 'Database is not encrypted',
                                      style: TextStyle(
                                        color:
                                            state.isEncrypted
                                                ? Colors.red
                                                : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Password and encryption/decryption section
                if (state is DatabaseFileSelected ||
                    state is EncryptionStatusChecked ||
                    state is DatabaseInfoLoaded ||
                    state is DatabaseEncrypted ||
                    state is DatabaseDecrypted)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Encryption/Decryption',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_passwordController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a password',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }
                                  context.read<DatabaseBloc>().add(
                                    EncryptDatabase(_passwordController.text),
                                  );
                                },
                                icon: const Icon(Icons.enhanced_encryption),
                                label: const Text('Encrypt Database'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_passwordController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a password',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }
                                  context.read<DatabaseBloc>().add(
                                    DecryptDatabase(_passwordController.text),
                                  );
                                },
                                icon: const Icon(Icons.no_encryption),
                                label: const Text('Decrypt Database'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Database info section
                if (state is DatabaseInfoLoaded)
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Database Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('File Name: ${state.info['fileName']}'),
                            Text(
                              'Size: ${(state.info['size'] / 1024).toStringAsFixed(2)} KB',
                            ),
                            Text(
                              'Last Modified: ${state.info['lastModified']}',
                            ),
                            const Divider(),
                            const Text(
                              'Database Keys',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: state.keys.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: const Icon(Icons.key),
                                    title: Text(state.keys[index]),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (state is DatabaseLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
