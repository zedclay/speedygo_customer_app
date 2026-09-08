enum NavCapability {
  liveAuth,
  navigationOnly,
  unsupported,
  productDecision,
  designToken,
}

enum NavSurface { screen, modal, tab, variant, token }

class NavLink {
  const NavLink({
    required this.label,
    this.location,
    this.blockedMessage,
    this.presentsModal = false,
  });

  final String label;
  final String? location;
  final String? blockedMessage;
  final bool presentsModal;
}

class NavEntry {
  const NavEntry({
    required this.id,
    required this.designDir,
    required this.title,
    required this.route,
    required this.capability,
    required this.surface,
    required this.purpose,
    this.group = '',
    this.protected = true,
    this.links = const [],
    this.paramKeys = const [],
  });

  final String id;
  final String designDir;
  final String title;
  final String route;
  final NavCapability capability;
  final NavSurface surface;
  final String purpose;
  final String group;
  final bool protected;
  final List<NavLink> links;
  final List<String> paramKeys;
}
