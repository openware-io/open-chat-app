import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_chat_app/app/app_routes.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:gv_chat_app/models/friend_models.dart';
import 'package:gv_chat_app/models/im_user.dart';
import 'package:gv_chat_app/models/outgoing_call_trace.dart';
import 'package:gv_chat_app/providers/call_provider.dart';
import 'package:gv_chat_app/repositories/call_repository.dart';
import 'package:gv_chat_app/repositories/friend_repository.dart';
import 'package:gv_chat_app/screens/call_screen.dart';
import 'package:gv_chat_app/services/call_platform_service.dart';
import 'package:gv_chat_app/widgets/active_call_overlay.dart';
import 'package:provider/provider.dart';

void main() {
  _CallTestWidgetsBinding();

  late _FakeCallRepository calls;
  late CallProvider provider;
  late List<OutgoingCallTrace> traces;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    // 测试环境无 audioplayers 原生插件：mock 其全局/播放器通道，避免回铃音初始化抛 MissingPluginException。
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall call) async => call.method == 'create' ? 'playerId' : null,
    );
    calls = _FakeCallRepository();
    provider = CallProvider(
      calls,
      _EmptyFriendRepository(),
      CallPlatformService(),
    );
    traces = <OutgoingCallTrace>[];
    provider.onOutgoingCallEndedTrace = traces.add;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('local caller cancellation emits a local cancelled trace', () async {
    provider.startCall(22, 'Peer', type: 'audio', peerIdStr: '22');

    await provider.hangup();

    expect(traces, hasLength(1));
    expect(traces.single.kind, 'cancelled');
    expect(traces.single.media, 'audio');
  });

  test('notification opens pending invite without banner or answer', () async {
    provider.onIncomingCall({
      'callId': 'notification-invite',
      'fromUserId': 22,
      'mediaType': 'audio',
    }, showBanner: false);
    expect(provider.isIncoming, isTrue);
    expect(provider.showIncomingCallBanner, isFalse);
    expect(provider.localStream, isNull);
    expect(calls.signals, isEmpty);
    await provider.rejectCall();
  });

  test('late duplicate invite does not mark an answered call as busy', () {
    provider
      ..status = 'connecting'
      ..callId = 'answered-call';
    provider.onIncomingCall({
      'callId': 'answered-call',
      'fromUserId': 22,
    }, showBanner: false);
    expect(provider.status, 'connecting');
    expect(calls.signals, isEmpty);
  });

  for (final media in ['audio', 'video']) {
    for (final resolution in [
      'answer',
      'decline',
      'remote_hangup',
      'system_answer',
      'already_answered',
      'banner_answer',
    ]) {
      testWidgets('$media incoming flow: $resolution', (tester) async {
        debugDefaultTargetPlatformOverride = null;
        final nativeCalls = <String>[];
        var texture = 0;
        const channel = MethodChannel('FlutterWebRTC.Method');
        const platformChannel = MethodChannel('com.gv.chat/call_platform');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(platformChannel, (_) async => null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          nativeCalls.add(call.method);
          if (call.method == 'createVideoRenderer') {
            return {'textureId': ++texture};
          }
          return null;
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(platformChannel, null);
        });
        final platform = CallPlatformService();
        final incoming = _AnswerSpyProvider(calls, platform)
          ..status =
              resolution == 'already_answered' ? 'connecting' : 'incoming'
          ..callId = 'notification-$media'
          ..remoteUserId = 22
          ..remoteUsername = 'Peer'
          ..mediaType = media;
        final router = GoRouter(
          initialLocation: AppRoutes.chats,
          routes: [
            GoRoute(
                path: AppRoutes.chats,
                builder: (_, __) => const Scaffold(body: Text('chats page'))),
            GoRoute(
                path: AppRoutes.call,
                builder: (_, __) =>
                    CallScreen(answerIncoming: resolution == 'banner_answer')),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(ChangeNotifierProvider<CallProvider>.value(
          value: incoming,
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: const [AppLocalizations.delegate],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ));
        router.push(AppRoutes.call);
        await tester.pump();
        if (resolution == 'banner_answer') {
          // Foreground Answer is already consent: never flash a second pair
          // of Answer/Decline controls while renderers/media initialize.
          expect(find.text('Answer'), findsNothing);
          expect(find.text('Decline'), findsNothing);
        }
        await tester.pumpAndSettle();
        if (resolution == 'banner_answer' || resolution == 'already_answered') {
          expect(incoming.answers, resolution == 'banner_answer' ? 1 : 0);
          expect(incoming.status, 'connecting');
          expect(find.text('Answer'), findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          return;
        }
        await tester.pump(const Duration(seconds: 31));
        expect(incoming.answers, 0);
        expect(incoming.isIncoming, isTrue);
        expect(incoming.showIncomingCallBanner, isFalse);
        expect(incoming.localStream, isNull);
        expect(nativeCalls, isNot(contains('getUserMedia')));
        expect(nativeCalls, isNot(contains('createPeerConnection')));
        expect(find.text('Peer'), findsOneWidget);
        expect(find.text('Answer'), findsOneWidget);
        expect(find.text('Decline'), findsOneWidget);
        expect(find.byIcon(Icons.mic), findsNothing);
        expect(find.textContaining('timed out'), findsNothing);

        switch (resolution) {
          case 'answer':
            await tester.tap(find.byKey(const ValueKey('incoming-answer')));
          case 'decline':
            await tester.tap(find.byKey(const ValueKey('incoming-decline')));
          case 'remote_hangup':
            await incoming.onSignal({
              'action': 'hangup',
              'callId': incoming.callId,
              'fromUserId': 22,
            });
          case 'system_answer':
            platform.onAnswerRequested!();
        }
        await tester.pumpAndSettle();
        final answered =
            resolution == 'answer' || resolution == 'system_answer';
        expect(incoming.answers, answered ? 1 : 0);
        expect(incoming.status, answered ? 'connecting' : 'idle');
        if (!answered) {
          expect(find.text('chats page'), findsOneWidget);
          expect(calls.signals.where((s) => s['action'] == 'reject'),
              hasLength(resolution == 'decline' ? 1 : 0));
        }
        expect(find.text('Answer'), findsNothing);
        expect(find.text('Decline'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }

  test('local callee rejection emits a local rejected trace', () async {
    provider
      ..status = 'incoming'
      ..callId = 'call-2'
      ..remoteUserId = 22
      ..mediaType = 'video'
      ..isOutgoing = false;

    await provider.rejectCall();

    expect(traces, hasLength(1));
    expect(traces.single.kind, 'rejected');
    expect(traces.single.media, 'video');
  });

  test('remote hangup does not create a second local trace', () async {
    provider.startCall(22, 'Peer', type: 'audio', peerIdStr: '22');
    final callId = provider.callId;

    await provider.onSignal({
      'action': 'hangup',
      'callId': callId,
      'fromUserId': 22,
    });

    expect(traces, isEmpty);
  });

  test('system overlay requests the full call only after minimization', () {
    provider.startCall(22, 'Peer', type: 'audio', peerIdStr: '22');
    final initialEpoch = provider.fullSurfaceRequestEpoch;

    provider.requestFullCallSurface();
    expect(provider.fullSurfaceRequestEpoch, initialEpoch);

    provider.minimizeCall();
    provider.requestFullCallSurface();

    expect(provider.isMinimized, isTrue);
    expect(provider.fullSurfaceRequestEpoch, initialEpoch + 1);
  });

  test('iOS pending call keeps its app answer UI when backgrounded', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const channel = MethodChannel('com.gv.chat/call_platform');
    final platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    var foreground = true;
    provider.isAppForeground = () => foreground;

    provider.onIncomingCall({
      'callId': 'incoming-ios',
      'fromUserId': 22,
      'fromUsername': 'Peer',
      'mediaType': 'audio',
    });
    await Future<void>.delayed(Duration.zero);

    expect(provider.showIncomingCallBanner, isTrue);
    expect(platformCalls.last.arguments, containsPair('appForeground', true));

    foreground = false;
    provider.handleAppBackgrounded();
    await Future<void>.delayed(Duration.zero);

    expect(provider.showIncomingCallBanner, isTrue);
    expect(platformCalls.last.arguments, containsPair('appForeground', false));

    provider.onIncomingCall({
      'callId': 'incoming-ios',
      'fromUserId': 22,
    }, showBanner: false);
    expect(provider.showIncomingCallBanner, isFalse);
    expect(provider.isIncoming, isTrue);

    await provider.rejectCall();
  });

  testWidgets('active call overlay restores through the injected router',
      (tester) async {
    debugDefaultTargetPlatformOverride = null;
    provider.startCall(22, 'Peer', type: 'audio', peerIdStr: '22');
    provider.minimizeCall();
    final router = GoRouter(
      initialLocation: AppRoutes.chats,
      routes: [
        GoRoute(
          path: AppRoutes.chats,
          builder: (_, __) => const Scaffold(body: Text('chats page')),
        ),
        GoRoute(
          path: AppRoutes.call,
          builder: (_, __) => const Scaffold(body: Text('call page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<CallProvider>.value(
        value: provider,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              ActiveCallOverlay(router: router),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.call));
    await tester.pumpAndSettle();

    expect(find.text('call page'), findsOneWidget);
    expect(provider.isMinimized, isFalse);
  });

  testWidgets('back gesture minimizes the call before leaving its route',
      (tester) async {
    debugDefaultTargetPlatformOverride = null;
    var nextTextureId = 1;
    const webRtcChannel = MethodChannel('FlutterWebRTC.Method');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(webRtcChannel, (call) async {
      if (call.method == 'createVideoRenderer') {
        return <String, dynamic>{'textureId': nextTextureId++};
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(webRtcChannel, null);
    });

    provider
      ..status = 'connecting'
      ..callId = 'active-call'
      ..remoteUserId = 22
      ..remoteUsername = 'Peer'
      ..mediaType = 'audio'
      ..isOutgoing = false;
    final router = GoRouter(
      initialLocation: AppRoutes.chats,
      routes: [
        GoRoute(
          path: AppRoutes.chats,
          builder: (_, __) => const Scaffold(body: Text('chats page')),
        ),
        GoRoute(
          path: AppRoutes.call,
          builder: (_, __) => const CallScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<CallProvider>.value(
        value: provider,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              ActiveCallOverlay(router: router),
            ],
          ),
        ),
      ),
    );
    router.push(AppRoutes.call);
    await tester.pumpAndSettle();

    expect(find.byType(CallScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(CallScreen), findsNothing);
    expect(find.text('chats page'), findsOneWidget);
    expect(provider.isMinimized, isTrue);
    expect(find.byIcon(Icons.call), findsOneWidget);

    provider
      ..status = 'idle'
      ..restoreCall();
    await tester.pump();
  });

  test('iOS call bridge forwards video tracks and can request PiP', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const channel = MethodChannel('com.gv.chat/call_platform');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'enterPictureInPicture') return true;
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final service = CallPlatformService();

    await service.updateCallState(
      active: true,
      video: true,
      callPresent: true,
      outgoing: false,
      phase: 'connected',
      remoteVideoTrackId: 'remote-video',
      localVideoTrackId: 'local-video',
      appForeground: false,
    );
    final entered = await service.enterPictureInPicture();

    expect(calls.map((call) => call.method), [
      'setCallState',
      'enterPictureInPicture',
    ]);
    expect(calls.first.arguments,
        containsPair('remoteVideoTrackId', 'remote-video'));
    expect(calls.first.arguments,
        containsPair('localVideoTrackId', 'local-video'));
    expect(calls.first.arguments, containsPair('appForeground', false));
    expect(entered, isTrue);
  });

  testWidgets('native iOS PiP keeps the call connected and removes full route',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const rtcChannel = MethodChannel('FlutterWebRTC.Method');
    const platformChannel = MethodChannel('com.gv.chat/call_platform');
    var texture = 0;
    messenger.setMockMethodCallHandler(
        rtcChannel,
        (call) async => call.method == 'createVideoRenderer'
            ? {'textureId': ++texture}
            : null);
    messenger.setMockMethodCallHandler(platformChannel, (_) async => null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(rtcChannel, null);
      messenger.setMockMethodCallHandler(platformChannel, null);
    });
    final platform = CallPlatformService();
    final connected = _AnswerSpyProvider(calls, platform)
      ..status = 'connected'
      ..callId = 'native-pip'
      ..mediaType = 'video'
      ..remoteUsername = 'Peer';
    final router = GoRouter(initialLocation: AppRoutes.chats, routes: [
      GoRoute(
          path: AppRoutes.chats,
          builder: (_, __) => const Scaffold(body: Text('chats page'))),
      GoRoute(path: AppRoutes.call, builder: (_, __) => const CallScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<CallProvider>.value(
      value: connected,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    router.push(AppRoutes.call);
    await tester.pumpAndSettle();
    platform.onPictureInPictureModeChanged!(true);
    await tester.pumpAndSettle();
    expect(connected.status, 'connected');
    expect(connected.isMinimized, isTrue);
    expect(find.byType(CallScreen), findsNothing);
    expect(find.text('chats page'), findsOneWidget);
    platform.onPictureInPictureModeChanged!(false);
    await tester.pumpAndSettle();
    expect(connected.status, 'connected');
    expect(connected.isSystemPictureInPicture, isFalse);
    expect(connected.isMinimized, isTrue);
    expect(calls.signals, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });
}

// Widget tests don't rasterize a real frame. Keep the real endOfFrame waits,
// but satisfy the native rasterization fence used before acquiring media.
class _CallTestWidgetsBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  Future<void> get waitUntilFirstFrameRasterized async {}
}

class _AnswerSpyProvider extends CallProvider {
  _AnswerSpyProvider(CallRepository calls, CallPlatformService platform)
      : super(calls, _EmptyFriendRepository(), platform);

  int answers = 0;

  @override
  Future<void> acceptCall() async {
    answers++;
    status = 'connecting';
    notifyListeners();
  }
}

class _FakeCallRepository implements CallRepository {
  final List<Map<String, dynamic>> signals = [];

  @override
  bool get signalingConnected => true;

  @override
  void emitRtcSignal(Map<String, dynamic> payload) => signals.add(payload);

  @override
  void reconnectSignalingIfNeeded() {}

  @override
  Future<Map<String, dynamic>> rtcIceConfig() async => const {};
}

class _EmptyFriendRepository implements FriendRepository {
  @override
  Future<void> blockFriend(int friendId) async {}

  @override
  Future<void> handleRequest(int requestId, String action) async {}

  @override
  Future<List<FriendItem>> loadFriends() async => const [];

  @override
  Future<List<FriendRequestItem>> loadPendingRequests() async => const [];

  @override
  Future<ImUser> loadUserProfile(int userId) async =>
      ImUser(id: userId, username: 'Peer');

  @override
  Future<void> removeFriend(int friendId) async {}

  @override
  Future<List<dynamic>> searchUser(String keyword) async => const [];

  @override
  Future<void> sendRequest(
    int userId,
    String message, {
    String? source,
    int? groupId,
  }) async {}

  @override
  Future<void> updateFriendRemark(int friendId, String remark) async {}

  @override
  Future<void> unblockFriend(int friendId) async {}

  @override
  Future<List<FriendItem>> loadBlockedList() async => const [];

  @override
  Future<List<String>> loadFriendGroups() async => const [];

  @override
  Future<void> setFriendGroup(int friendId, String groupName) async {}
}
