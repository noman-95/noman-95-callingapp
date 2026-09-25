import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zego_uikit/zego_uikit.dart';
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

class _UserSelectionPageState
    extends State<UserSelectionPage> {
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
        icon: const Icon(Icons.person),
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
  // ===========================================================
  // ZEGOCLOUD
  // ===========================================================

  final int appID = 1876473876;

  final String appSign =
      'c5ce62449ba439e5d5fbc9ec5fdfdaaaf503393bd6bcb2fed2533fa47023505d';

  // ===========================================================
  // STATE
  // ===========================================================

  bool isReady = false;
  bool isLoading = true;

  bool isChatReady = false;

  AppUser get currentUser =>
      widget.currentUser;

  AppUser get targetUser {
    if (currentUser.id == user1.id) {
      return user2;
    }

    return user1;
  }

  // ===========================================================
  // CHAT
  // ===========================================================

  final List<ChatMessage> messages = [];

  final TextEditingController messageController =
      TextEditingController();

  StreamSubscription? _dummySubscription;

  // ===========================================================
  // INIT
  // ===========================================================

  @override
  void initState() {
    super.initState();

    initializeZego();
    initializeChat();
  }

  // ===========================================================
  // ZEGOCLOUD CALLING
  // ===========================================================

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

      debugPrint(
        'ZEGO CALL READY: ${currentUser.id}',
      );
    } catch (e) {
      debugPrint(
        'ZEGO CALL INITIALIZATION ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isReady = false;
        isLoading = false;
      });

      showMessage(
        'Calling service failed:\n$e',
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
        '${currentUser.id} -> ${targetUser.id}',
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
        'VIDEO CALL: '
        '${currentUser.id} -> ${targetUser.id}',
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
  // ZIM CHAT INITIALIZATION
  // ===========================================================

  Future<void> initializeChat() async {
    try {
      // Create ZIM instance.
      final appConfig = ZIMAppConfig();

      appConfig.appID = appID;
      appConfig.appSign = appSign;

      ZIM.create(appConfig);

      final zim = ZIM.getInstance();

      if (zim == null) {
        throw Exception(
          'ZIM instance create nahi hui.',
        );
      }

      // -------------------------------------------------------
      // RECEIVE PEER MESSAGES
      // -------------------------------------------------------

      ZIMEventHandler.onPeerMessageReceived =
          (
        ZIM zim,
        List<ZIMMessage> messageList,
        ZIMMessageReceivedInfo info,
        String fromUserID,
      ) {
        for (final message in messageList) {
          if (message is ZIMTextMessage) {
            if (!mounted) return;

            setState(() {
              messages.add(
                ChatMessage(
                  text: message.message,
                  fromMe: false,
                  senderID: fromUserID,
                ),
              );
            });
          }
        }
      };

      // -------------------------------------------------------
      // LOGIN
      // -------------------------------------------------------

      final loginConfig = ZIMLoginConfig();

      loginConfig.userName =
          currentUser.name;

      loginConfig.token = '';

      loginConfig.isOfflineLogin = false;

      await zim.login(
        currentUser.id,
        loginConfig,
      );

      if (!mounted) return;

      setState(() {
        isChatReady = true;
      });

      debugPrint(
        'ZIM CHAT READY: ${currentUser.id}',
      );
    } on PlatformException catch (e) {
      debugPrint(
        'ZIM LOGIN ERROR: ${e.code} ${e.message}',
      );

      if (!mounted) return;

      setState(() {
        isChatReady = false;
      });

      showMessage(
        'Chat login failed:\n${e.message}',
      );
    } catch (e) {
      debugPrint(
        'ZIM ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isChatReady = false;
      });

      showMessage(
        'Chat initialization failed:\n$e',
      );
    }
  }

  // ===========================================================
  // SEND TEXT MESSAGE
  // ===========================================================

  Future<void> sendTextMessage() async {
    final text =
        messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    if (!isChatReady) {
      showMessage(
        'Chat service abhi ready nahi hai.',
      );
      return;
    }

    if (currentUser.id == targetUser.id) {
      showMessage(
        'Apne aap ko message nahi bhej sakte.',
      );
      return;
    }

    try {
      final zim = ZIM.getInstance();

      if (zim == null) {
        showMessage(
          'Chat service available nahi hai.',
        );
        return;
      }

      final zimMessage =
          ZIMTextMessage(
        message: text,
      );

      final sendConfig =
          ZIMMessageSendConfig();

      sendConfig.priority =
          ZIMMessagePriority.low;

      await zim.sendMessage(
        zimMessage,
        targetUser.id,
        ZIMConversationType.peer,
        sendConfig,
      );

      if (!mounted) return;

      setState(() {
        messages.add(
          ChatMessage(
            text: text,
            fromMe: true,
            senderID: currentUser.id,
          ),
        );
      });

      messageController.clear();
    } on PlatformException catch (e) {
      debugPrint(
        'SEND MESSAGE ERROR: '
        '${e.code} ${e.message}',
      );

      if (mounted) {
        showMessage(
          'Message send nahi hua:\n${e.message}',
        );
      }
    } catch (e) {
      debugPrint(
        'SEND MESSAGE ERROR: $e',
      );

      if (mounted) {
        showMessage(
          'Message send nahi hua:\n$e',
        );
      }
    }
  }

  // ===========================================================
  // SHOW MESSAGE
  // ===========================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
      ZIM.getInstance()?.logout();
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
  // DISPOSE
  // ===========================================================

  @override
  void dispose() {
    messageController.dispose();

    _dummySubscription?.cancel();

    try {
      ZegoUIKitPrebuiltCallInvitationService()
          .uninit();
    } catch (_) {}

    try {
      ZIM.getInstance()?.logout();
      ZIM.getInstance()?.destroy();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // =================================================
              // CURRENT USER CARD
              // =================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(25),
                decoration: BoxDecoration(
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
                        color: Colors.white,
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

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color: isReady
                            ? Colors.green
                                .withOpacity(
                                0.2,
                              )
                            : Colors.orange
                                .withOpacity(
                                0.2,
                              ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child: Text(
                        isLoading
                            ? 'Connecting...'
                            : isReady
                                ? 'Online'
                                : 'Offline',
                        style:
                            TextStyle(
                          color: isReady
                              ? Colors.white
                              : Colors
                                  .orangeAccent,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // =================================================
              // CONTACT
              // =================================================

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
                                FontWeight
                                    .bold,
                          ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              Container(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
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
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                targetUser
                                    .name,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      17,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                targetUser
                                    .id,
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
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
                                    Icons
                                        .circle,
                                    size: 9,
                                    color:
                                        isReady
                                            ? Colors
                                                .green
                                            : Colors
                                                .grey,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    isReady
                                        ? 'Available'
                                        : 'Connecting...',
                                    style:
                                        TextStyle(
                                      color:
                                          isReady
                                              ? Colors
                                                  .green
                                              : Colors
                                                  .grey,
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
                              ElevatedButton
                                  .icon(
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
                              disabledBackgroundColor:
                                  Colors
                                      .grey
                                      .shade300,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 14,
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
                              ElevatedButton
                                  .icon(
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
                              disabledBackgroundColor:
                                  Colors
                                      .grey
                                      .shade300,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 14,
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
                  ],
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // =================================================
              // CHAT SECTION
              // =================================================

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_rounded,
                      color:
                          Color(0xFF6750A4),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      'Messages',
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Container(
                width: double.infinity,
                height: 330,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
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
                    // -------------------------------------------------
                    // CHAT STATUS
                    // -------------------------------------------------

                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color: isChatReady
                              ? Colors.green
                                  .withOpacity(
                                  0.10,
                                )
                              : Colors.orange
                                  .withOpacity(
                                  0.10,
                                ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Text(
                          isChatReady
                              ? 'Chat Online'
                              : 'Chat Connecting...',
                          style: TextStyle(
                            color:
                                isChatReady
                                    ? Colors
                                        .green
                                    : Colors
                                        .orange,
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // -------------------------------------------------
                    // MESSAGES
                    // -------------------------------------------------

                    Expanded(
                      child: messages
                              .isEmpty
                          ? Center(
                              child: Text(
                                'Abhi koi message nahi.',
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade500,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    4,
                              ),
                              itemCount:
                                  messages
                                      .length,
                              itemBuilder:
                                  (
                                context,
                                index,
                              ) {
                                final msg =
                                    messages[
                                        index];

                                return Align(
                                  alignment: msg
                                          .fromMe
                                      ? Alignment
                                          .centerRight
                                      : Alignment
                                          .centerLeft,
                                  child:
                                      Container(
                                    constraints:
                                        const BoxConstraints(
                                      maxWidth:
                                          280,
                                    ),
                                    margin:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical:
                                          4,
                                    ),
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal:
                                          14,
                                      vertical:
                                          10,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: msg
                                              .fromMe
                                          ? const Color(
                                              0xFF6750A4,
                                            )
                                          : const Color(
                                              0xFFE9E1FF,
                                            ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                    ),
                                    child:
                                        Text(
                                      msg.text,
                                      style:
                                          TextStyle(
                                        color: msg
                                                .fromMe
                                            ? Colors
                                                .white
                                            : Colors
                                                .black87,
                                        fontSize:
                                            15,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // -------------------------------------------------
                    // MESSAGE INPUT
                    // -------------------------------------------------

                    Row(
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
                                    sendTextMessage(),
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Message likhein...',
                              filled: true,
                              fillColor:
                                  const Color(
                                0xFFF4F2F8,
                              ),
                              contentPadding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    16,
                                vertical:
                                    12,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  25,
                                ),
                                borderSide:
                                    BorderSide
                                        .none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        FloatingActionButton(
                          mini: true,
                          heroTag:
                              'send_message',
                          onPressed:
                              sendTextMessage,
                          backgroundColor:
                              const Color(
                            0xFF6750A4,
                          ),
                          foregroundColor:
                              Colors.white,
                          child:
                              const Icon(
                            Icons.send,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

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
// CHAT MESSAGE MODEL
// =============================================================

class ChatMessage {
  final String text;
  final bool fromMe;
  final String senderID;

  ChatMessage({
    required this.text,
    required this.fromMe,
    required this.senderID,
  });
}
