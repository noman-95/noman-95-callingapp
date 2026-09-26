import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_zim/zego_zim.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CallingApp());
}

// =============================================================
// APP
// =============================================================

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
// USERS
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

    final savedUserID = prefs.getString('selected_user_id');

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
  // ===========================================================
  // ZEGO CONFIG
  // ===========================================================

  final int appID = 1876473876;

  final String appSign =
      'c5ce62449ba439e5d5fbc9ec5fdfdaaaf503393bd6bcb2fed2533fa47023505d';

  // ===========================================================
  // STATE
  // ===========================================================

  bool isReady = false;
  bool isLoading = true;
  bool zimReady = false;

  ZIM? zim;

  AppUser get currentUser => widget.currentUser;

  AppUser get targetUser {
    return currentUser.id == user1.id ? user2 : user1;
  }

  // ===========================================================
  // INIT
  // ===========================================================

  @override
  void initState() {
    super.initState();
    initializeServices();
  }

  Future<void> initializeServices() async {
    await initializeZegoCall();
    await initializeZimChat();
  }

  // ===========================================================
  // ZEGO CALL
  // ===========================================================

  Future<void> initializeZegoCall() async {
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

      debugPrint(
        'ZEGO CALL READY: ${currentUser.id}',
      );
    } catch (e) {
      debugPrint(
        'ZEGO CALL ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isReady = false;
        isLoading = false;
      });

      showMessage(
        'Calling service error:\n$e',
      );
    }
  }

  // ===========================================================
  // ZIM CHAT
  // ===========================================================

  Future<void> initializeZimChat() async {
    try {
      final config = ZIMAppConfig(
        appID: appID,
        appSign: appSign,
      );

      ZIM.create(config);

      zim = ZIM.getInstance();

      if (zim == null) {
        throw Exception(
          'ZIM instance create nahi hui.',
        );
      }

      ZIMEventHandler.onPeerMessageReceived =
          (
        ZIM receivedZim,
        List<ZIMMessage> messageList,
        ZIMMessageReceivedInfo info,
        String fromUserID,
      ) {
        debugPrint(
          'MESSAGE RECEIVED FROM: $fromUserID',
        );

        for (final message in messageList) {
          if (message is ZIMTextMessage) {
            debugPrint(
              'TEXT MESSAGE: ${message.message}',
            );
          }
        }
      };

      final loginConfig = ZIMLoginConfig();

      loginConfig.userName = currentUser.name;
      loginConfig.token = '';
      loginConfig.isOfflineLogin = false;

      await zim!.login(
        currentUser.id,
        loginConfig,
      );

      if (!mounted) return;

      setState(() {
        zimReady = true;
      });

      debugPrint(
        'ZIM CHAT READY: ${currentUser.id}',
      );
    } catch (e) {
      debugPrint(
        'ZIM CHAT ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        zimReady = false;
      });

      showMessage(
        'Chat service error:\n$e',
      );
    }
  }

  // ===========================================================
  // AUDIO CALL
  // ===========================================================

  Future<void> makeAudioCall() async {
    if (!isReady) {
      showMessage(
        'Calling service abhi ready nahi hai.',
      );
      return;
    }

    try {
      debugPrint(
        'AUDIO CALL: ${currentUser.id} -> ${targetUser.id}',
      );

      final result =
          await ZegoUIKitPrebuiltCallInvitationService()
              .send(
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
          '${targetUser.name} ko audio call send nahi ho saki.',
        );
      }
    } catch (e) {
      debugPrint(
        'AUDIO CALL ERROR: $e',
      );

      if (mounted) {
        showMessage(
          'Audio call error:\n$e',
        );
      }
    }
  }

  // ===========================================================
  // VIDEO CALL
  // ===========================================================

  Future<void> makeVideoCall() async {
    if (!isReady) {
      showMessage(
        'Calling service abhi ready nahi hai.',
      );
      return;
    }

    try {
      debugPrint(
        'VIDEO CALL: ${currentUser.id} -> ${targetUser.id}',
      );

      final result =
          await ZegoUIKitPrebuiltCallInvitationService()
              .send(
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
      debugPrint(
        'VIDEO CALL ERROR: $e',
      );

      if (mounted) {
        showMessage(
          'Video call error:\n$e',
        );
      }
    }
  }

  // ===========================================================
  // CHAT OPEN
  // ===========================================================

  void openChat() {
    if (!zimReady || zim == null) {
      showMessage(
        'Chat service abhi ready nahi hai.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          zim: zim!,
          currentUser: currentUser,
          targetUser: targetUser,
        ),
      ),
    );
  }

  // ===========================================================
  // STATUS CHIP
  // ===========================================================

  Widget statusChip(
    String title,
    bool ready,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: ready
            ? Colors.green.withOpacity(0.20)
            : Colors.orange.withOpacity(0.20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: ready
                ? Colors.greenAccent
                : Colors.orangeAccent,
          ),
          const SizedBox(width: 5),
          Text(
            '$title ${ready ? 'Ready' : 'Connecting'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // MESSAGE
  // ===========================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ===========================================================
  // SWITCH USER
  // ===========================================================

  Future<void> switchUser() async {
    try {
      await ZegoUIKitPrebuiltCallInvitationService()
          .uninit();
    } catch (_) {}

    try {
      await zim?.logout();
    } catch (_) {}

    ZIMEventHandler.onPeerMessageReceived = null;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      'selected_user_id',
    );

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const UserSelectionPage(),
      ),
      (route) => false,
    );
  }

  // ===========================================================
  // DISPOSE
  // ===========================================================

  @override
  void dispose() {
    try {
      ZegoUIKitPrebuiltCallInvitationService()
          .uninit();
    } catch (_) {}

    try {
      zim?.logout();
    } catch (_) {}

    ZIMEventHandler.onPeerMessageReceived = null;

    super.dispose();
  }

  // ===========================================================
  // HOME UI
  // ===========================================================

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
            tooltip: 'Chat',
            onPressed: zimReady ? openChat : null,
            icon: const Icon(
              Icons.chat_rounded,
            ),
          ),
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

              // =================================================
              // CURRENT USER CARD
              // =================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6750A4),
                      Color(0xFF8B6CCF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
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
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        statusChip(
                          'Call',
                          isReady,
                        ),
                        const SizedBox(width: 8),
                        statusChip(
                          'Chat',
                          zimReady,
                        ),
                      ],
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

              // =================================================
              // TARGET USER
              // =================================================

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
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
                            color: Color(0xFF6750A4),
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                targetUser.id,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 9,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Available',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // CALL BUTTONS
                    // =================================================

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                isReady
                                    ? makeAudioCall
                                    : null,
                            icon: const Icon(
                              Icons.call,
                            ),
                            label: const Text(
                              'Audio Call',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.green,
                              foregroundColor:
                                  Colors.white,
                              disabledBackgroundColor:
                                  Colors.grey.shade300,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
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

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                isReady
                                    ? makeVideoCall
                                    : null,
                            icon: const Icon(
                              Icons.videocam,
                            ),
                            label: const Text(
                              'Video Call',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF6750A4,
                              ),
                              foregroundColor:
                                  Colors.white,
                              disabledBackgroundColor:
                                  Colors.grey.shade300,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
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

                    // =================================================
                    // CHAT BUTTON
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            zimReady
                                ? openChat
                                : null,
                        icon: const Icon(
                          Icons.message_rounded,
                        ),
                        label: const Text(
                          'Text Message',
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(
                            0xFF6750A4,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 13,
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
              ),

              const Spacer(),

              Text(
                isLoading
                    ? 'Connecting to calling service...'
                    : isReady
                        ? '${currentUser.name} is ready for calls'
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
// CHAT MESSAGE MODEL
// =============================================================

class ChatItem {
  final String text;
  final bool isMine;

  ChatItem({
    required this.text,
    required this.isMine,
  });
}

// =============================================================
// CHAT PAGE
// =============================================================

class ChatPage extends StatefulWidget {
  final ZIM zim;
  final AppUser currentUser;
  final AppUser targetUser;

  const ChatPage({
    super.key,
    required this.zim,
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

  final List<ChatItem> messages = [];

  bool sending = false;

  @override
  void initState() {
    super.initState();

    ZIMEventHandler.onPeerMessageReceived =
        (
      ZIM zim,
      List<ZIMMessage> messageList,
      ZIMMessageReceivedInfo info,
      String fromUserID,
    ) {
      if (fromUserID != widget.targetUser.id) {
        return;
      }

      for (final message in messageList) {
        if (message is ZIMTextMessage) {
          if (!mounted) return;

          setState(() {
            messages.add(
              ChatItem(
                text: message.message,
                isMine: false,
              ),
            );
          });

          scrollToBottom();
        }
      }
    };
  }

  // ===========================================================
  // SEND MESSAGE
  // ===========================================================

  Future<void> sendTextMessage() async {
    final text =
        messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    if (sending) {
      return;
    }

    setState(() {
      sending = true;
    });

    try {
      final message = ZIMTextMessage(
        message: text,
      );

      final config =
          ZIMMessageSendConfig();

      config.priority =
          ZIMMessagePriority.low;

      await widget.zim.sendMessage(
        message,
        widget.targetUser.id,
        ZIMConversationType.peer,
        config,
      );

      if (!mounted) return;

      setState(() {
        messages.add(
          ChatItem(
            text: text,
            isMine: true,
          ),
        );
      });

      messageController.clear();

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Message send error:\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  // ===========================================================
  // SCROLL
  // ===========================================================

  void scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController
            .position
            .maxScrollExtent,
        duration:
            const Duration(
          milliseconds: 250,
        ),
        curve: Curves.easeOut,
      );
    });
  }

  // ===========================================================
  // DISPOSE
  // ===========================================================

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  // ===========================================================
  // CHAT UI
  // ===========================================================

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
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 65,
                          color:
                              Colors.grey.shade400,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Message bhejna shuru karein.',
                          style: TextStyle(
                            color:
                                Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller:
                        scrollController,
                    padding:
                        const EdgeInsets.all(16),
                    itemCount:
                        messages.length,
                    itemBuilder:
                        (context, index) {
                      final item =
                          messages[index];

                      return Align(
                        alignment:
                            item.isMine
                                ? Alignment
                                    .centerRight
                                : Alignment
                                    .centerLeft,
                        child: Container(
                          constraints:
                              BoxConstraints(
                            maxWidth:
                                MediaQuery.of(
                                      context,
                                    )
                                    .size
                                    .width *
                                0.78,
                          ),
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 10,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 15,
                            vertical: 11,
                          ),
                          decoration:
                              BoxDecoration(
                            color: item.isMine
                                ? const Color(
                                    0xFF6750A4,
                                  )
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .black
                                    .withOpacity(
                                  0.05,
                                ),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Text(
                            item.text,
                            style: TextStyle(
                              color: item.isMine
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // =====================================================
          // MESSAGE INPUT
          // =====================================================

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          messageController,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) {
                        sendTextMessage();
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'Type a message...',
                        filled: true,
                        fillColor:
                            Colors.white,
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            25,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        const Color(
                      0xFF6750A4,
                    ),
                    child: IconButton(
                      onPressed:
                          sending
                              ? null
                              : sendTextMessage,
                      icon: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color:
                                  Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

