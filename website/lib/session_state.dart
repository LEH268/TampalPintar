import 'package:flutter/material.dart';

/// True only after a login's role check confirms a government role;
/// reset to false whenever the session ends. The auth gate shows the
/// dashboard only when a session exists AND this is true, so a citizen's
/// transient post-signin session never mounts the dashboard subtree.
final ValueNotifier<bool> govRoleVerified = ValueNotifier<bool>(false);

/// A ScaffoldMessenger key at the MaterialApp root, above the auth gate,
/// so the citizen-rejection message survives the login->gate widget swap.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
