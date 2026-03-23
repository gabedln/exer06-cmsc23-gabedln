import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Template of flutter_contacts retrieved from https://pub.dev/packages/flutter_contacts/example

void main() => runApp(
  MaterialApp(
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: const ContactListPage(),
  ),
);

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});
  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  List<Contact>? _contacts;
  StreamSubscription? _sub;
  bool _denied = false; // bool to check if permission is granted

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    // function to initialize permissions
    final s = await FlutterContacts.permissions.request(
      PermissionType.readWrite,
    );
    if (s != PermissionStatus.granted && s != PermissionStatus.limited) {
      // if access is denied, sets bool to true
      return setState(() => _denied = true);
    }
    _sub = FlutterContacts.onContactChange.listen((changes) {
      for (final c in changes) {
        print('Contact ${c.type.name}: ${c.contactId}'); // ignore: avoid_print
      }
      _load();
    });
    _load();
  }

  Future<void> _load() async {
    // future function (async)
    final contacts = await FlutterContacts.getAll(
      // function that loads all contacts
      properties: {ContactProperty.photoThumbnail},
    );
    setState(
      () => _contacts = contacts,
    ); // sets state that _contacts = retrieved contacts
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Color.fromARGB(255, 195, 220, 240),
    appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 115, 161, 231),
      title: const Text(
        '📞 Exercise 06: Android Features',
        style: TextStyle(
          color: const Color.fromARGB(255, 255, 255, 255),
          fontWeight: .bold,
        ),
      ),
    ),
    body: _denied
        ? const Center(
            child: Text('Contact permission not granted'),
          ) // IF _denied, then shows that contact permission was not granted
        : _contacts ==
              null // if not denied, but contacts == null
        ? const Center(
            child: CircularProgressIndicator(),
          ) // adds circularProgressindicator
        : ListView.builder(
            // else, if not denied and contacts not empty, creats listView
            itemCount: _contacts!.length,
            itemBuilder: (_, i) {
              final c =
                  _contacts![i]; // builds contacts view, iterates through contact list
              return ListTile(
                leading: const Icon(Icons.person_2_rounded, size: 40),
                title: Text(
                  c.displayName ??
                      '(No name)', // if doesn't have a name shows no name
                  style: TextStyle(fontWeight: .bold, fontSize: 18),
                ),
                onTap: () =>
                    _open(ContactPage(id: c.id!)), // on tap opens contact page
              );
            },
          ),
    floatingActionButton: FloatingActionButton(
      child: const Icon(
        Icons.contacts,
      ), // floating action button to add contact
      onPressed: () => _open(const EditContactPage()),
    ),
  );
}

class ContactPage extends StatelessWidget {
  final String id;
  const ContactPage({super.key, required this.id});

  Future<Contact?> _load() => FlutterContacts.get(
    id,
    properties: {
      ContactProperty.name,
      ContactProperty.phone,
      ContactProperty.email,
    },
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Contact?>(
      future: _load(),
      builder: (context, snap) {
        final c = snap.data;
        String info = "";

        if (c!.name?.first != null && (c.name!.last?.isNotEmpty ?? false)) {
          info += "📖 First name: ${c.name!.first}\n"; // checks for validation
        }

        if (c.name?.last != null && (c.name!.last?.isNotEmpty ?? false)) {
          info += "📖 Last name: ${c.name!.last}\n";
        }
        if (c.phones.isNotEmpty) {
          info += "📲 Phone number: ${c.phones.first.number}\n";
        }

        if (c.emails.isNotEmpty) {
          info += "📧 Email address: ${c.emails.first.address}\n";
        }
        return Scaffold(
          backgroundColor: Color.fromARGB(255, 195, 220, 240),
          appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 115, 161, 231),
            title: const Text(
              '📞 View Contact Details',
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontWeight: .bold,
              ),
            ),
          ),
          body: SafeArea(
            // puts the summary from AddEntry screen and puts it in the body of this screen
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: .start,
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.all(30),
                    child: Flexible(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 133, 182, 247),
                          border: Border.all(color: Colors.black, width: 1.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 30),

                        child: Column(
                          mainAxisAlignment: .start,
                          children: [
                            const Text(
                              "📄 Contact Details:",
                              style: TextStyle(
                                fontSize: 26,
                                color: Color.fromARGB(255, 10, 54, 104),
                                fontWeight: .bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              info,
                              style: TextStyle(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                fontSize: 20,
                                fontStyle: .italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      FlutterContacts.delete(id);
                      _load();
                      Navigator.pop(context);
                    },
                    child: Text("Delete Contact"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class EditContactPage extends StatefulWidget {
  final Contact? contact;
  const EditContactPage({super.key, this.contact});
  @override
  State<EditContactPage> createState() => _EditContactPageState();
}

class _EditContactPageState extends State<EditContactPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _imageFile; // stores picked image

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 195, 220, 240),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 115, 161, 231),
        title: const Text(
          '📞 Add A Contact',
          style: TextStyle(
            color: const Color.fromARGB(255, 255, 255, 255),
            fontWeight: .bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            child: Column(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : null,
                    child: _imageFile == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // pick image buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo),
                      label: const Text("Gallery"),
                      onPressed: () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );

                        setState(() {
                          _imageFile = image == null ? null : File(image.path);
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                      onPressed: () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                        );

                        setState(() {
                          _imageFile = image == null ? null : File(image.path);
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                TextFormField(
                  controller:
                      _firstNameController, // assigns textField controller
                  validator: (value) {
                    // error if textfield is empty
                    if (value == null || value.isEmpty) {
                      return "Enter your first name!";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 133, 182, 247),
                    hintText: "Enter your first name",
                    labelText: "First name",
                  ),
                ),
                const SizedBox(height: 15), // sizedbox used for spacing
                // text field for nickname
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 133, 182, 247),
                    hintText: "Enter your last name",
                    labelText: "Last name",
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter your phone number!";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 133, 182, 247),
                    hintText: "Enter your phone number",
                    labelText: "Phone",
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 133, 182, 247),
                    hintText: "Enter your e-mail",
                    labelText: "E-mail",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Add Contact'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final name = Name(
                        first: _firstNameController.text,
                        last: _lastNameController.text,
                      );

                      final phones = [Phone(number: _phoneController.text)];
                      List<Email> emails = [];

                      if (_emailController.text.trim() == "") {
                        emails = [];
                      } else {
                        emails = [Email(address: _emailController.text)];
                      }

                      FlutterContacts.create(
                        Contact(name: name, phones: phones, emails: emails),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        // confirmation
                        SnackBar(
                          content: Text("Contact successfully added!"),
                          duration: Duration(seconds: 1, milliseconds: 100),
                        ),
                      );
                      if (mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
