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
// GLOBAL NAVIGATOR KEY
// =============================================================

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

// =============================================================
// ZEGO CONFIG
// =============================================================

const int zegoAppID = 1876473876;

const String zegoAppSign =
    'c5ce62449ba439e5d5fbc9ec5fdfdaaaf503393bd6bcb2fed2533fa47023505d';

// =============================================================
// APP
// =============================================================

class CallingApp extends StatelessWidget {
  const CallingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,

      debugShowCheckedModeBanner: false,

      title: 'Calling App',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
        ),

        scaffoldBackgroundColor:
            const Color(0xFFF8F7FC),
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
// USER SELECTION PAGE
// =============================================================

class UserSelectionPage extends StatefulWidget {
  const UserSelectionPage({super.key});

  @override
  State<UserSelectionPage> createState() =>
      _UserSelectionPageState();
}

class _UserSelectionPageState
    extends State<UserSelectionPage> {
  bool loading = true;

  @override
  void initState() {
    super.initState();

    checkSavedUser();
  }

  Future<void> checkSavedUser() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedUserID =
        prefs.getString('selected_user_id');

    if (!mounted) return;

    if (savedUserID == user1.id) {
      openHome(user1);
      return;
    }

    if (savedUserID == user2.id) {
      openHome(user2);
      return;
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> selectUser(AppUser user) async {
    final prefs =
        await SharedPreferences.getInstance();

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
          mainAxisAlignment:
              MainAxisAlignment.center,
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

        icon: const Icon(
          Icons.person,
        ),

        label: Text(
          user.name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF6750A4),

          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
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
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isReady = false;

  bool isLoading = true;

  bool zimReady = false;

  ZIM? zim;

  AppUser get currentUser =>
      widget.currentUser;

  AppUser get targetUser {
    if (currentUser.id == user1.id) {
      return user2;
    }

    return user1;
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
    try {
      // VERY IMPORTANT:
      // This allows incoming call UI to navigate
      // over the current Flutter screen.
      ZegoUIKitPrebuiltCallInvitationService()
          .setNavigatorKey(navigatorKey);

      await initializeZegoCall();

      await initializeZimChat();
    } catch (e) {
      debugPrint(
        'INITIALIZATION ERROR: $e',
      );
    }
  }

  // ===========================================================
  // ZEGO CALL INITIALIZATION
  // ===========================================================

  Future<void> initializeZegoCall() async {
    try {
      final service =
          ZegoUIKitPrebuiltCallInvitationService();

      await service.init(
        appID: zegoAppID,

        appSign: zegoAppSign,

        userID: currentUser.id,

        userName: currentUser.name,

        plugins: [
          ZegoUIKitSignalingPlugin(),
        ],

        invitationEvents:
            ZegoUIKitPrebuiltCallInvitationEvents(
          onIncomingCallReceived:
              (
            String callID,
            ZegoCallUser caller,
            ZegoCallInvitationType callType,
            List<ZegoCallUser> callees,
            String customData,
          ) {
            debugPrint(
              'INCOMING CALL RECEIVED',
            );

            debugPrint(
              'CALLER: ${caller.userID}',
            );

            debugPrint(
              'VIDEO: ${callType == ZegoCallInvitationType.videoCall}',
            );
          },

          onIncomingCallAcceptButtonPressed:
              () {
            debugPrint(
              'INCOMING CALL ACCEPTED',
            );
          },

          onIncomingCallDeclineButtonPressed:
              () {
            debugPrint(
              'INCOMING CALL REJECTED',
            );
          },

          onOutgoingCallAccepted:
              (
            String callID,
            ZegoCallUser callee,
          ) {
            debugPrint(
              'CALL ACCEPTED BY: ${callee.userID}',
            );
          },

          onOutgoingCallDeclined:
              (
            String callID,
            ZegoCallUser callee,
            String customData,
          ) {
            debugPrint(
              'CALL DECLINED BY: ${callee.userID}',
            );
          },

          onOutgoingCallTimeout:
              (
            String callID,
            List<ZegoCallUser> callees,
            bool isVideoCall,
          ) {
            debugPrint(
              'CALL TIMEOUT',
            );
          },
        ),
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
  // ZIM CHAT INITIALIZATION
  // ===========================================================

  Future<void> initializeZimChat() async {
    try {
      final config = ZIMAppConfig(
        appID: zegoAppID,
        appSign: zegoAppSign,
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
        ZIM zimInstance,
        List<ZIMMessage> messageList,
        ZIMMessageReceivedInfo info,
        String fromUserID,
      ) {
        debugPrint(
          'MESSAGE RECEIVED FROM: $fromUserID',
        );
      };

      final loginConfig =
          ZIMLoginConfig();

      loginConfig.userName =
          currentUser.name;

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
        'ZIM READY: ${currentUser.id}',
      );
    } catch (e) {
      debugPrint(
        'ZIM ERROR: $e',
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
        'AUDIO CALL: '
        '${currentUser.id} -> '
        '${targetUser.id}',
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

      debugPrint(
        'AUDIO SEND RESULT: $result',
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
        'VIDEO CALL: '
        '${currentUser.id} -> '
        '${targetUser.id}',
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

      debugPrint(
        'VIDEO SEND RESULT: $result',
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
  // CHAT
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

    try {
      ZIMEventHandler.onPeerMessageReceived =
          null;
    } catch (_) {}

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      'selected_user_id',
    );

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const UserSelectionPage(),
      ),
      (route) => false,
    );
  }

  // ===========================================================
  // MESSAGE
  // ===========================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: ready
            ? Colors.green.withOpacity(0.20)
            : Colors.orange.withOpacity(0.20),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        ready
            ? '$title Online'
            : '$title Connecting...',

        style: TextStyle(
          color: Colors.white,

          fontSize: 12,

          fontWeight:
              FontWeight.bold,
        ),
      ),
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

    try {
      ZIMEventHandler.onPeerMessageReceived =
          null;
    } catch (_) {}

    super.dispose();
  }

  // ===========================================================
  // UI
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.transparent,

        elevation: 0,

        title: const Text(
          'Calling App',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Chat',

            onPressed:
                zimReady
                    ? openChat
                    : null,

            icon: const Icon(
              Icons.chat_rounded,
            ),
          ),

          IconButton(
            tooltip: 'Switch User',

            onPressed:
                switchUser,

            icon: const Icon(
              Icons.switch_account,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),

              // =================================================
              // CURRENT USER
              // =================================================

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  25,
                ),

                decoration:
                    BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFF6750A4),
                      Color(0xFF8B6CCF),
                    ],
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),
                ),

                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,

                      backgroundColor:
                          Colors.white,

                      child: Icon(
                        Icons.person,

                        size: 48,

                        color:
                            Color(0xFF6750A4),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Text(
                      currentUser.name,

                      style:
                          const TextStyle(
                        color:
                            Colors.white,

                        fontSize: 22,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      currentUser.id,

                      style:
                          const TextStyle(
                        color:
                            Colors.white70,

                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        statusChip(
                          'Call',
                          isReady,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        statusChip(
                          'Chat',
                          zimReady,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  'Contacts',

                  style:
                      Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // TARGET USER
              // =================================================

              Container(
                padding:
                    const EdgeInsets.all(
                  16,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.05,
                      ),

                      blurRadius: 15,

                      offset:
                          const Offset(
                        0,
                        5,
                      ),
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
                              Color(
                            0xFFE9E1FF,
                          ),

                          child: Icon(
                            Icons.person,

                            color:
                                Color(
                              0xFF6750A4,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Expanded(
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                targetUser.name,

                                style:
                                    const TextStyle(
                                  fontSize:
                                      17,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                targetUser.id,

                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey.shade600,

                                  fontSize:
                                      13,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,

                                    size: 9,

                                    color:
                                        Colors.grey.shade500,
                                  ),

                                  const SizedBox(
                                    width: 5,
                                  ),

                                  Text(
                                    'Available',

                                    style:
                                        TextStyle(
                                      color:
                                          Colors.grey.shade600,

                                      fontSize:
                                          12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // =================================================
                    // CALL BUTTONS
                    // =================================================

                    Row(
                      children: [
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                isReady
                                    ? makeAudioCall
                                    : null,

                            icon:
                                const Icon(
                              Icons.call,
                            ),

                            label:
                                const Text(
                              'Audio Call',
                            ),

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  Colors.green,

                              foregroundColor:
                                  Colors.white,

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical:
                                    14,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                isReady
                                    ? makeVideoCall
                                    : null,

                            icon:
                                const Icon(
                              Icons.videocam,
                            ),

                            label:
                                const Text(
                              'Video Call',
                            ),

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF6750A4,
                              ),

                              foregroundColor:
                                  Colors.white,

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical:
                                    14,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =================================================
                    // CHAT BUTTON
                    // =================================================

                    SizedBox(
                      width:
                          double.infinity,

                      child:
                          OutlinedButton.icon(
                        onPressed:
                            zimReady
                                ? openChat
                                : null,

                        icon:
                            const Icon(
                          Icons.message,
                        ),

                        label:
                            const Text(
                          'Text Message',
                        ),

                        style:
                            OutlinedButton
                                .styleFrom(
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
                                BorderRadius
                                    .circular(
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
                    ? 'Connecting...'
                    : isReady
                        ? '${currentUser.name} is ready for calls'
                        : 'Calling service failed',

                style:
                    TextStyle(
                  color: isLoading
                      ? Colors.orange
                      : isReady
                          ? Colors.green
                          : Colors.red,

                  fontSize: 13,
                ),
              ),

              const SizedBox(
                height: 15,
              ),
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
  State<ChatPage> createState() =>
      _ChatPageState();
}

class _ChatPageState
    extends State<ChatPage> {
  final TextEditingController
      messageController =
      TextEditingController();

  final ScrollController
      scrollController =
      ScrollController();

  final List<ChatMessage> messages =
      [];

  @override
  void initState() {
    super.initState();

    ZIMEventHandler
        .onPeerMessageReceived =
        (
      ZIM zim,
      List<ZIMMessage> messageList,
      ZIMMessageReceivedInfo info,
      String fromUserID,
    ) {
      if (fromUserID !=
          widget.targetUser.id) {
        return;
      }

      for (final message
          in messageList) {
        if (message
            is ZIMTextMessage) {
          setState(() {
            messages.add(
              ChatMessage(
                text:
                    message.message,
                mine: false,
              ),
            );
          });

          scrollToBottom();
        }
      }
    };
  }

  // ===========================================================
  // SEND TEXT
  // ===========================================================

  Future<void> sendMessage() async {
    final text =
        messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    try {
      final message =
          ZIMTextMessage(
        message: text,
      );

      final config =
          ZIMMessageSendConfig();

      final result =
          await widget.zim.sendPeerMessage(
        message,
        widget.targetUser.id,
        config,
      );

      if (!mounted) return;

      setState(() {
        messages.add(
          ChatMessage(
            text: text,
            mine: true,
          ),
        );
      });

      messageController.clear();

      scrollToBottom();

      debugPrint(
        'MESSAGE SENT: ${result.message}',
      );
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
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!scrollController
          .hasClients) {
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
        curve:
            Curves.easeOut,
      );
    });
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
        title: Text(
          widget.targetUser.name,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(
                        color: Colors
                            .grey.shade600,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller:
                        scrollController,

                    padding:
                        const EdgeInsets.all(
                      16,
                    ),

                    itemCount:
                        messages.length,

                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final message =
                          messages[index];

                      return Align(
                        alignment:
                            message.mine
                                ? Alignment
                                    .centerRight
                                : Alignment
                                    .centerLeft,

                        child: Container(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 8,
                          ),

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),

                          decoration:
                              BoxDecoration(
                            color: message.mine
                                ? const Color(
                                    0xFF6750A4,
                                  )
                                : Colors.grey
                                    .shade200,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),

                          child: Text(
                            message.text,

                            style:
                                TextStyle(
                              color: message
                                      .mine
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                10,
              ),

              child: Row(
                children: [
                  Expanded(
                    child:
                        TextField(
                      controller:
                          messageController,

                      textInputAction:
                          TextInputAction
                              .send,

                      onSubmitted:
                          (_) =>
                              sendMessage(),

                      decoration:
                          InputDecoration(
                        hintText:
                            'Type message...',

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            25,
                          ),
                        ),

                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  CircleAvatar(
                    radius: 24,

                    backgroundColor:
                        const Color(
                      0xFF6750A4,
                    ),

                    child:
                        IconButton(
                      onPressed:
                          sendMessage,

                      icon:
                          const Icon(
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

// =============================================================
// CHAT MESSAGE MODEL
// =============================================================

class ChatMessage {
  final String text;

  final bool mine;

  ChatMessage({
    required this.text,
    required this.mine,
  });
}
