import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const CallingApp());
}

class CallingApp extends StatelessWidget {
  const CallingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calling App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      ),
      home: const UserSelectionPage(),
    );
  }
}

// =============================================================
// USER MODEL
// =============================================================

class AppUser {
  final String id;
  final String name;

  const AppUser({
    required this.id,
    required this.name,
  });
}

const AppUser user1 = AppUser(
  id: 'user_001',
  name: 'User 1',
);

const AppUser user2 = AppUser(
  id: 'user_002',
  name: 'User 2',
);

// =============================================================
// USER SELECTION
// =============================================================

class UserSelectionPage extends StatefulWidget {
  const UserSelectionPage({super.key});

  @override
  State<UserSelectionPage> createState() =>
      _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    checkSavedUser();
  }

  Future<void> checkSavedUser() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUserID =
        prefs.getString('selected_user_id');

    if (!mounted) return;

    if (savedUserID == user1.id) {
      openHome(user1);
    } else if (savedUserID == user2.id) {
      openHome(user2);
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> selectUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'selected_user_id',
      user.id,
    );

    if (!mounted) return;

    openHome(user);
  }

  void openHome(AppUser user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomePage(
          currentUser: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_alt_rounded,
              size: 80,
              color: Color(0xFF6750A4),
            ),

            const SizedBox(height: 20),

            const Text(
              'Select your user',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Har mobile par different user select karein.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 35),

            userButton(user1),

            const SizedBox(height: 15),

            userButton(user2),
          ],
        ),
      ),
    );
  }

  Widget userButton(AppUser user) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () => selectUser(user),
        icon: const Icon(Icons.person),
        label: Text(
          user.name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// HOME PAGE
// =============================================================

class HomePage extends StatefulWidget {
  final AppUser currentUser;

  const HomePage({
    super.key,
    required this.currentUser,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int appID = 1876473876;

  final String appSign =
      'c5ce62449ba439e5d5fbc9ec5fdfdaaaf503393bd6bcb2fed2533fa47023505d';

  bool isReady = false;
  bool isLoading = true;

  AppUser get currentUser => widget.currentUser;

  AppUser get targetUser {
    return currentUser.id == user1.id ? user2 : user1;
  }

  @override
  void initState() {
    super.initState();
    initializeZego();
  }

  Future<void> initializeZego() async {
    try {
      final service =
          ZegoUIKitPrebuiltCallInvitationService();

      await service.init(
        appID: appID,
        appSign: appSign,
        userID: currentUser.id,
        userName: currentUser.name,
        plugins: [
          ZegoUIKitSignalingPlugin(),
        ],
      );

      if (!mounted) return;

      setState(() {
        isReady = true;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isReady = false;
        isLoading = false;
      });

      showMessage(
        'ZEGOCLOUD initialization failed:\n$e',
      );
    }
  }

  // ===========================================================
  // AUDIO CALL
  // ===========================================================

  Future<void> makeAudioCall() async {
    if (!isReady) {
      showMessage('Calling service ready nahi hai.');
      return;
    }

    try {
      final result =
          await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [
          ZegoCallUser(
            targetUser.id,
            targetUser.name,
          ),
        ],
        isVideoCall: false,
        timeoutSeconds: 60,
      );

      if (!result && mounted) {
        showMessage(
          '${targetUser.name} ko call send nahi ho saki.',
        );
      }
    } catch (e) {
      showMessage('Audio call error:\n$e');
    }
  }

  // ===========================================================
  // VIDEO CALL
  // ===========================================================

  Future<void> makeVideoCall() async {
    if (!isReady) {
      showMessage('Calling service ready nahi hai.');
      return;
    }

    try {
      final result =
          await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [
          ZegoCallUser(
            targetUser.id,
            targetUser.name,
          ),
        ],
        isVideoCall: true,
        timeoutSeconds: 60,
      );

      if (!result && mounted) {
        showMessage(
          '${targetUser.name} ko video call send nahi ho saki.',
        );
      }
    } catch (e) {
      showMessage('Video call error:\n$e');
    }
  }

  // ===========================================================
  // CHAT
  // ===========================================================

  void openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          currentUser: currentUser,
          targetUser: targetUser,
        ),
      ),
    );
  }

  // ===========================================================
  // SWITCH USER
  // ===========================================================

  Future<void> switchUser() async {
    try {
      await ZegoUIKitPrebuiltCallInvitationService().uninit();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('selected_user_id');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const UserSelectionPage(),
      ),
      (route) => false,
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    ZegoUIKitPrebuiltCallInvitationService().uninit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Calling App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Switch User',
            onPressed: switchUser,
            icon: const Icon(
              Icons.switch_account,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              const SizedBox(height: 20),

              // CURRENT USER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6750A4),
                      Color(0xFF8B6CCF),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(28),
                ),

                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: Color(0xFF6750A4),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      currentUser.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      currentUser.id,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        isLoading
                            ? 'Connecting...'
                            : isReady
                                ? 'Online'
                                : 'Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Contacts',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 14),

              // CONTACT CARD
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.05),
                      blurRadius: 15,
                      offset:
                          const Offset(0, 5),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              Color(0xFFE9E1FF),
                          child: Icon(
                            Icons.person,
                            color:
                                Color(0xFF6750A4),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                targetUser.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                targetUser.id,
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                'Available',
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // CALL BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed: isReady
                                ? makeAudioCall
                                : null,
                            icon:
                                const Icon(Icons.call),
                            label:
                                const Text('Audio Call'),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.green,
                              foregroundColor:
                                  Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  15,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed: isReady
                                ? makeVideoCall
                                : null,
                            icon: const Icon(
                              Icons.videocam,
                            ),
                            label:
                                const Text('Video Call'),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF6750A4),
                              foregroundColor:
                                  Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // MESSAGE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: openChat,
                        icon: const Icon(
                          Icons.message_rounded,
                        ),
                        label: const Text(
                          'Message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF6750A4),
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Text(
                isLoading
                    ? 'Connecting to calling service...'
                    : isReady
                        ? '${currentUser.name} is ready'
                        : 'Calling service failed',
                style: TextStyle(
                  color: isLoading
                      ? Colors.orange
                      : isReady
                          ? Colors.green
                          : Colors.red,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// CHAT PAGE
// =============================================================

class ChatPage extends StatefulWidget {
  final AppUser currentUser;
  final AppUser targetUser;

  const ChatPage({
    super.key,
    required this.currentUser,
    required this.targetUser,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  bool sending = false;

  // Same conversation ID for both users.
  String get conversationID {
    final ids = [
      widget.currentUser.id,
      widget.targetUser.id,
    ]..sort();

    return '${ids[0]}_${ids[1]}';
  }

  CollectionReference<Map<String, dynamic>>
      get messagesCollection {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(conversationID)
        .collection('messages');
  }

  // ===========================================================
  // SEND TEXT
  // ===========================================================

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || sending) {
      return;
    }

    setState(() {
      sending = true;
    });

    try {
      await messagesCollection.add({
        'senderId': widget.currentUser.id,
        'senderName': widget.currentUser.name,
        'receiverId': widget.targetUser.id,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Message send nahi hua:\n$e',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        sending = false;
      });
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.targetUser.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.targetUser.id,
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // =====================================================
          // MESSAGES
          // =====================================================

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesCollection
                  .orderBy(
                    'timestamp',
                    descending: false,
                  )
                  .snapshots(),

              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Chat error:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages =
                    snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.\nMessage bhejein.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,

                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final data =
                        messages[index].data();

                    final senderId =
                        data['senderId'] ?? '';

                    final text =
                        data['text'] ?? '';

                    final isMe =
                        senderId ==
                            widget.currentUser.id;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,

                      child: Container(
                        constraints:
                            BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context)
                                      .size
                                      .width *
                                  0.78,
                        ),

                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),

                        padding:
                            const EdgeInsets.symmetric(
                         
