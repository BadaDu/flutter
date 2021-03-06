// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Locale, WindowPadding, window;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'asset_vendor.dart';
import 'basic.dart';
import 'binding.dart';
import 'checked_mode_banner.dart';
import 'framework.dart';
import 'locale_query.dart';
import 'media_query.dart';
import 'navigator.dart';
import 'performance_overlay.dart';
import 'semantics_debugger.dart';
import 'title.dart';

AssetBundle _initDefaultBundle() {
  if (rootBundle != null)
    return rootBundle;
  return new NetworkAssetBundle(Uri.base);
}

final AssetBundle _defaultBundle = _initDefaultBundle();

typedef Future<LocaleQueryData> LocaleChangedCallback(Locale locale);

class WidgetsApp extends StatefulWidget {
  WidgetsApp({
    Key key,
    this.title,
    this.textStyle,
    this.color,
    this.routes: const <String, WidgetBuilder>{},
    this.onGenerateRoute,
    this.onLocaleChanged,
    this.showPerformanceOverlay: false,
    this.showSemanticsDebugger: false,
    this.debugShowCheckedModeBanner: true
  }) : super(key: key) {
    assert(routes != null);
    assert(routes.containsKey(Navigator.defaultRouteName) || onGenerateRoute != null);
    assert(showPerformanceOverlay != null);
    assert(showSemanticsDebugger != null);
  }

  /// A one-line description of this app for use in the window manager.
  final String title;

  /// The default text style for [Text] in the application.
  final TextStyle textStyle;

  /// The primary color to use for the application in the operating system
  /// interface.
  ///
  /// For example, on Android this is the color used for the application in the
  /// application switcher.
  final Color color;

  /// The default table of routes for the application. When the
  /// [Navigator] is given a named route, the name will be looked up
  /// in this table first. If the name is not available, then
  /// [onGenerateRoute] will be called instead.
  final Map<String, WidgetBuilder> routes;

  /// The route generator callback used when the app is navigated to a
  /// named route but the name is not in the [routes] table.
  final RouteFactory onGenerateRoute;

  /// Callback that is invoked when the operating system changes the
  /// current locale.
  final LocaleChangedCallback onLocaleChanged;

  /// Turns on a performance overlay.
  /// https://flutter.io/debugging/#performanceoverlay
  final bool showPerformanceOverlay;

  /// Turns on an overlay that shows the accessibility information
  /// reported by the framework.
  final bool showSemanticsDebugger;

  /// Turns on a "SLOW MODE" little banner in checked mode to indicate
  /// that the app is in checked mode. This is on by default (in
  /// checked mode), to turn it off, set the constructor argument to
  /// false. In release mode this has no effect.
  ///
  /// To get this banner in your application if you're not using
  /// WidgetsApp, include a [CheckedModeBanner] widget in your app.
  ///
  /// This banner is intended to avoid people complaining that your
  /// app is slow when it's in checked mode. In checked mode, Flutter
  /// enables a large number of expensive diagnostics to aid in
  /// development, and so performance in checked mode is not
  /// representative of what will happen in release mode.
  final bool debugShowCheckedModeBanner;

  @override
  WidgetsAppState<WidgetsApp> createState() => new WidgetsAppState<WidgetsApp>();
}

EdgeInsets _getPadding(ui.WindowPadding padding) {
  return new EdgeInsets.TRBL(padding.top, padding.right, padding.bottom, padding.left);
}

class WidgetsAppState<T extends WidgetsApp> extends State<T> implements BindingObserver {

  GlobalObjectKey _navigator;

  LocaleQueryData _localeData;

  @override
  void initState() {
    super.initState();
    _navigator = new GlobalObjectKey(this);
    didChangeLocale(ui.window.locale);
    WidgetFlutterBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetFlutterBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool didPopRoute() {
    assert(mounted);
    NavigatorState navigator = _navigator.currentState;
    assert(navigator != null);
    bool result = false;
    navigator.openTransaction((NavigatorTransaction transaction) {
      result = transaction.pop();
    });
    return result;
  }

  @override
  void didChangeMetrics() {
    setState(() {
      // The properties of ui.window have changed. We use them in our build
      // function, so we need setState(), but we don't cache anything locally.
    });
  }

  @override
  void didChangeLocale(Locale locale) {
    if (config.onLocaleChanged != null) {
      config.onLocaleChanged(locale).then((LocaleQueryData data) {
        if (mounted)
          setState(() { _localeData = data; });
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { }

  NavigatorObserver get navigatorObserver => null;

  @override
  Widget build(BuildContext context) {
    if (config.onLocaleChanged != null && _localeData == null) {
      // If the app expects a locale but we don't yet know the locale, then
      // don't build the widgets now.
      // TODO(ianh): Make this unnecessary. See https://github.com/flutter/flutter/issues/1865
      return new Container();
    }

    Widget result = new MediaQuery(
      data: new MediaQueryData(
        size: ui.window.size,
        devicePixelRatio: ui.window.devicePixelRatio,
        padding: _getPadding(ui.window.padding)
      ),
      child: new LocaleQuery(
        data: _localeData,
        child: new DefaultTextStyle(
          style: config.textStyle,
          child: new AssetVendor(
            bundle: _defaultBundle,
            devicePixelRatio: ui.window.devicePixelRatio,
            child: new Title(
              title: config.title,
              color: config.color,
              child: new Navigator(
                key: _navigator,
                initialRoute: ui.window.defaultRouteName,
                onGenerateRoute: config.onGenerateRoute,
                observer: navigatorObserver
              )
            )
          )
        )
      )
    );
    if (config.showPerformanceOverlay) {
      result = new Stack(
        children: <Widget>[
          result,
          new Positioned(bottom: 0.0, left: 0.0, right: 0.0, child: new PerformanceOverlay.allEnabled()),
        ]
      );
    }
    if (config.showSemanticsDebugger) {
      result = new SemanticsDebugger(
        child: result
      );
    }
    assert(() {
      if (config.debugShowCheckedModeBanner) {
        result = new CheckedModeBanner(
          child: result
        );
      }
      return true;
    });
    return result;
  }

}
