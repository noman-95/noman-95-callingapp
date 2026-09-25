import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // =========================================================
  // ZEGOCLOUD
  // =========================================================

  final int appID = 1876473876;

  final String appSign =
      'c5ce62449ba439e5d5fbc9ec5fdfdaaaf503393bd6bcb2fed2533fa47023505d';

  // =========================================================
  // CURRENT USER
  // =========================================================

  final String userID = 'user_001';
  final String userName = 'User 1';

  // =========================================================
  // TARGET USER
  // =========================================================

  final String targetUserID = 'user_002';
  final String targetUserName = 'User 2';

  // =========================================================
  // INITIALIZATION STATUS
  // =========================================================

  bool isReady = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    initializeZego();
  }

  // =========================================================
  // INITIALIZE ZEGOCLOUD
  // =========================================================

  Future<void> initializeZego() async {
    try {
      final service =
          ZegoUIKitPrebuiltCallInvitationService();

      await service.init(
        appID: appID,
        appSign: appSign,
        userID: userID,
        userName: userName,
        plugins: [
          ZegoUIKitSignalingPlugin(),
        ],
      );

      if (!mounted) return;

      setState(() {
        isReady = true;
        isLoading = false;
      });

      debugPrint('ZEGOCLOUD INITIALIZED SUCCESSFULLY');
    } catch (e) {
      debugPrint('ZEGOCLOUD INITIALIZATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        isReady = false;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ZEGOCLOUD initialization failed: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // AUDIO CALL
  // =========================================================

  Future<void> makeAudioCall() async {
    if (!isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Calling service abhi ready nahi hai.',
          ),
        ),
      );

      return;
    }

    try {
      final result =
          await ZegoUIKitPrebuiltCallInvitationService()
              .send(
        invitees: [
          ZegoCallUser(
            targetUserID,
            targetUserName,
          ),
        ],
        isVideoCall: false,
        timeoutSeconds: 60,
      );

      if (!result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User 2 ko call send nahi ho saki.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('AUDIO CALL ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Audio call error: $e',
            ),
          ),
        );
      }
    }
  }

  // =========================================================
  // VIDEO CALL
  // =========================================================

  Future<void> makeVideoCall() async {
    if (!isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Calling service abhi ready nahi hai.',
          ),
        ),
      );

      return;
    }

    try {
      final result =
          await ZegoUIKitPrebuiltCallInvitationService()
              .send(
        invitees: [
          ZegoCallUser(
            targetUserID,
            targetUserName,
          ),
        ],
        isVideoCall: true,
        timeoutSeconds: 60,
      );

      if (!result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User 2 ko video call send nahi ho saki.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('VIDEO CALL ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video call error: $e',
            ),
          ),
        );
      }
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    ZegoUIKitPrebuiltCallInvitationService().uninit();

    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

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

                  borderRadius:
                      BorderRadius.circular(28),
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

                    const SizedBox(height: 14),

                    Text(
                      userName,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      userID,

                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // STATUS
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: isReady
                            ? Colors.green
                                .withOpacity(0.2)
                            : Colors.orange
                                .withOpacity(0.2),

                        borderRadius:
                            BorderRadius.circular(
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
                              : Colors.orangeAccent,

                          fontSize: 12,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // CONTACT TITLE
              // =================================================

              Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  'Contacts',

                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 14),

              // =================================================
              // USER 2 CARD
              // =================================================

              Container(
                padding:
                    const EdgeInsets.all(16),

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
                                targetUserName,

                                style:
                                    const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                targetUserID,

                                style: TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                  fontSize: 13,
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
                                    color: isReady
                                        ? Colors.green
                                        : Colors.grey,
                                  ),

                                  const SizedBox(
                                    width: 5,
                                  ),

                                  Text(
                                    isReady
                                        ? 'Ready'
                                        : 'Connecting...',
                                    style:
                                        TextStyle(
                                      color: isReady
                                          ? Colors.green
                                          : Colors.grey,
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
                            onPressed: isReady
                                ? makeAudioCall
                                : null,

                            icon: const Icon(
                              Icons.call,
                            ),

                            label: const Text(
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
                                  Colors.grey.shade300,

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
                              ElevatedButton.icon(
                            onPressed: isReady
                                ? makeVideoCall
                                : null,

                            icon: const Icon(
                              Icons.videocam,
                            ),

                            label: const Text(
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
                                  Colors.grey.shade300,

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

              const Spacer(),

              Text(
                isLoading
                    ? 'Connecting to calling service...'
                    : isReady
                        ? 'Ready for calls'
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
