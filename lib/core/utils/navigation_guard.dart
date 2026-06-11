import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';

bool _navigating = false;

/// Hızlı çift tıklamadan kaynaklanan duplicate page key hatasını önler.
extension SafeNavigation on BuildContext {
  void safePush(String path, {Object? extra}) {
    if (_navigating) return;
    _navigating = true;
    GoRouter.of(this).push(path, extra: extra);
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      _navigating = false;
    });
  }
}
