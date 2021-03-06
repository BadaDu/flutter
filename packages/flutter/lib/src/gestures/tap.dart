// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

typedef void GestureTapDownCallback(Point globalPosition);
typedef void GestureTapUpCallback(Point globalPosition);
typedef void GestureTapCallback();
typedef void GestureTapCancelCallback();

/// TapGestureRecognizer is a tap recognizer that tracks only one primary
/// pointer per gesture. That is, during tap recognition, extra pointer events
/// are ignored: down-1, down-2, up-1, up-2 produces only one tap on up-1.
class TapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  TapGestureRecognizer() : super(deadline: kPressTimeout);

  GestureTapDownCallback onTapDown;
  GestureTapUpCallback onTapUp;
  GestureTapCallback onTap;
  GestureTapCancelCallback onTapCancel;

  bool _sentTapDown = false;
  bool _wonArena = false;
  Point _finalPosition;

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      _finalPosition = event.position;
      _checkUp();
    }
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (_wonArena && disposition == GestureDisposition.rejected) {
      if (onTapCancel != null)
        onTapCancel();
      _reset();
    }
    super.resolve(disposition);
  }

  @override
  void didExceedDeadline() {
    _checkDown();
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    if (pointer == primaryPointer) {
      _checkDown();
      _wonArena = true;
      _checkUp();
    }
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer == primaryPointer) {
      assert(state == GestureRecognizerState.defunct);
      if (onTapCancel != null)
        onTapCancel();
      _reset();
    }
  }

  void _checkDown() {
    if (!_sentTapDown) {
      if (onTapDown != null)
        onTapDown(initialPosition);
      _sentTapDown = true;
    }
  }

  void _checkUp() {
    if (_wonArena && _finalPosition != null) {
      resolve(GestureDisposition.accepted);
      if (onTapUp != null)
        onTapUp(_finalPosition);
      if (onTap != null)
        onTap();
      _reset();
    }
  }

  void _reset() {
    _sentTapDown = false;
    _wonArena = false;
    _finalPosition = null;
  }

  @override
  String toStringShort() => 'tap';
}
