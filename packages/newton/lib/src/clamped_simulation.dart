// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'simulation.dart';

class ClampedSimulation extends Simulation {
  ClampedSimulation(this.simulation, {
    this.xMin: double.NEGATIVE_INFINITY,
    this.xMax: double.INFINITY,
    this.dxMin: double.NEGATIVE_INFINITY,
    this.dxMax: double.INFINITY
  }) {
    assert(simulation != null);
    assert(xMax >= xMin);
    assert(dxMax >= dxMin);
  }

  final Simulation simulation;
  final double xMin;
  final double xMax;
  final double dxMin;
  final double dxMax;

  @override
  double x(double time) => simulation.x(time).clamp(xMin, xMax);

  @override
  double dx(double time) => simulation.dx(time).clamp(dxMin, dxMax);

  @override
  bool isDone(double time) => simulation.isDone(time);
}
