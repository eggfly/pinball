import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:leaderboard_repository/leaderboard_repository.dart';
import 'package:pinball/game/components/backbox/bloc/backbox_bloc.dart';
import 'package:pinball/game/components/backbox/displays/displays.dart';
import 'package:pinball/game/game.dart';
import 'package:pinball/l10n/l10n.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_flame/pinball_flame.dart';
import 'package:pinball_theme/pinball_theme.dart' hide Assets;
import 'package:pinball_ui/pinball_ui.dart';
import 'package:platform_helper/platform_helper.dart';
import 'package:share_repository/share_repository.dart';

/// {@template backbox}
/// The [Backbox] of the pinball machine.
/// {@endtemplate}
class Backbox extends PositionComponent with ZIndex, HasGameRef {
  /// {@macro backbox}
  Backbox({
    required LeaderboardRepository? leaderboardRepository,
    required ShareRepository shareRepository,
    required List<LeaderboardEntryData>? entries,
  })  : _bloc = BackboxBloc(
          leaderboardRepository: null,
          initialEntries: entries,
        ),
        _shareRepository = shareRepository;

  /// {@macro backbox}
  @visibleForTesting
  Backbox.test({
    required BackboxBloc bloc,
    required ShareRepository shareRepository,
  })  : _bloc = bloc,
        _shareRepository = shareRepository;

  final ShareRepository _shareRepository;
  late final Component _display;
  final BackboxBloc _bloc;
  late StreamSubscription<BackboxState> _subscription;

  @override
  Future<void> onLoad() async {
    position = Vector2(0, -87);
    anchor = Anchor.bottomCenter;
    zIndex = ZIndexes.backbox;

    await add(_BackboxSpriteComponent());
    await add(_display = Component());
    _build(_bloc.state);

    _subscription = _bloc.stream.listen((state) {
      _display.children.removeWhere((_) => true);
      _build(state);
    });
  }

  @override
  void onRemove() {
    super.onRemove();
    _subscription.cancel();
  }

  void _build(BackboxState state) {
    if (state is LoadingState) {
      _display.add(LoadingDisplay());
    } else if (state is LeaderboardSuccessState) {
      _display.add(LeaderboardDisplay(entries: state.entries));
    } else if (state is LeaderboardFailureState) {
      _display.add(LeaderboardFailureDisplay());
    } else if (state is InitialsFormState) {
      if (readProvider<PlatformHelper>().isMobile) {
        gameRef.overlays.add(PinballGame.mobileControlsOverlay);
      }
      _display.add(
        InitialsInputDisplay(
          score: state.score,
          characterIconPath: state.character.leaderboardIcon.keyName,
          onSubmit: (initials) {
            _bloc.add(
              PlayerInitialsSubmitted(
                score: state.score,
                initials: initials,
                character: state.character,
              ),
            );
          },
        ),
      );
    } else if (state is InitialsSuccessState) {
      gameRef.overlays.remove(PinballGame.mobileControlsOverlay);

      _display.add(
        GameOverInfoDisplay(
          onShare: () {
            _bloc.add(ShareScoreRequested(score: state.score));
          },
        ),
      );
    } else if (state is ShareState) {
      _display.add(
        ShareDisplay(
          onShare: (platform) {
            final message = readProvider<AppLocalizations>()
                .iGotScoreAtPinball(state.score.formatScore());
            final url = _shareRepository.shareText(
              value: message,
              platform: platform,
            );
            openLink(url);
          },
        ),
      );
    } else if (state is InitialsFailureState) {
      _display.add(
        InitialsSubmissionFailureDisplay(
          onDismissed: () {
            _bloc.add(
              PlayerInitialsRequested(
                score: state.score,
                character: state.character,
              ),
            );
          },
        ),
      );
    }
  }

  /// Puts [InitialsInputDisplay] on the [Backbox].
  void requestInitials({
    required int score,
    required CharacterTheme character,
  }) {
    _bloc.add(
      PlayerInitialsRequested(
        score: score,
        character: character,
      ),
    );
  }
}

class _BackboxSpriteComponent extends SpriteComponent with HasGameRef {
  _BackboxSpriteComponent() : super(anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final sprite = Sprite(
      gameRef.images.fromCache(
        Assets.images.backbox.marquee.keyName,
      ),
    );
    this.sprite = sprite;
    size = sprite.originalSize / 20;
  }
}
