import 'package:flutter/material.dart';

/// Shared navigator observer for security-sensitive route transitions.
///
/// Screens that can hold revealed secrets subscribe with [RouteAware] so a
/// pushed route (or returning from one) masks everything immediately.
final RouteObserver<ModalRoute<dynamic>> keyelRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();
