import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

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

      // IMPORTANT:
      // Zego incoming-call UI uses this navigator.
      navigatorKey: navigatorKey,

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
        centerTitle: true,
        title: const Text(
          'Select User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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

          shape:
              RoundedRectangleBorder(
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

  AppUser get currentUser =>
      widget.currentUser;

  AppUser get targetUser {
    if (currentUser.id == user1.id) {
      return user2;
    }

    return user1;
  }

  // ===========================================================
  // INITIALIZE
  // ===========================================================

  @override
  void initState() {
    super.initState();

    initializeZego();
  }

  // ===========================================================
  // ZEGOCLOUD INITIALIZATION
  // ===========================================================

  Future<void> initializeZego() async {
    try {
      final service =
          ZegoUIKitPrebuiltCallInvitationService();

      // IMPORTANT:
      // This allows incoming-call UI to appear
      // above the Flutter application.
      service.setNavigatorKey(
        navigatorKey,
      );

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
        'ZEGO READY: ${currentUser.id}',
      );
    } catch (e) {
      debugPrint(
        'ZEGO INITIALIZATION ERROR: $e',
      );

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
  // SWITCH USER
  // ===========================================================

  Future<void> switchUser() async {
    try {
      await ZegoUIKitPrebuiltCallInvitationService()
          .uninit();
    } catch (_) {}

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      'selected_user_id',
    );

    if (!mounted) return;

    Navigator.of(context)
        .pushAndRemoveUntil(
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
    ZegoUIKitPrebuiltCallInvitationService()
        .uninit();

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
              const SizedBox(
                height: 20,
              ),

              // =================================================
              // CURRENT USER CARD
              // =================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(25),

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

              const SizedBox(
                height: 30,
              ),

              // =================================================
              // CONTACT TITLE
              // =================================================

              Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  'Contacts',

                  style: Theme.of(
                    context,
                  )
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
                                targetUser.id,

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
                                    Icons.circle,

                                    size: 9,

                                    color: Colors
                                        .grey
                                        .shade500,
                                  ),

                                  const SizedBox(
                                    width: 5,
                                  ),

                                  Text(
                                    'Available',

                                    style:
                                        TextStyle(
                                      color: Colors
                                          .grey
                                          .shade600,

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
