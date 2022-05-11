import 'package:authentication_repository/authentication_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:leaderboard_repository/leaderboard_repository.dart';
import 'package:pinball/app/app.dart';
import 'package:pinball/bootstrap.dart';
import 'package:pinball_audio/pinball_audio.dart';
import 'package:platform_helper/platform_helper.dart';
import 'package:share_repository/share_repository.dart';

void main() async {
  await bootstrap((firestore, firebaseAuth) async {
    const shareRepository =
        ShareRepository(appUrl: ShareRepository.pinballGameUrl);
    final pinballAudioPlayer = PinballAudioPlayer();
    final platformHelper = PlatformHelper();
    final app = App(
      authenticationRepository: null,
      leaderboardRepository: null,
      shareRepository: shareRepository,
      pinballAudioPlayer: pinballAudioPlayer,
      platformHelper: platformHelper,
    );
    return app;
  });
}
