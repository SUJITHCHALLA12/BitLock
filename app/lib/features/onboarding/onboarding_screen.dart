import 'package:flutter/material.dart';

import '../../theme/bitlock_theme.dart';

/// First-run introduction: three pages explaining what BitLock does
/// and, just as plainly, what it cannot do.
///
/// Page 2 states the limits of view-only sharing and page 3 states
/// the recovery limit, following the honest-claims rule: no copy here
/// promises protection the app does not provide.
class OnboardingScreen extends StatefulWidget {
  /// Creates the onboarding screen.
  const OnboardingScreen({
    required this.onGetStarted,
    required this.onAlreadyHaveVault,
    super.key,
  });

  /// Called when the user finishes or skips onboarding to set up a
  /// new vault.
  final VoidCallback onGetStarted;

  /// Called when the user already has a vault and wants to unlock it.
  final VoidCallback onAlreadyHaveVault;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const List<_OnboardingPage> _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.lock_outline,
      title: 'Files encrypted on this device',
      body: 'Files you import are encrypted locally before they are '
          'stored in the app-private vault. Each file gets its own '
          'random key, wrapped by a key derived from your vault '
          'password. Plaintext is not written to shared storage.',
    ),
    _OnboardingPage(
      icon: Icons.share_outlined,
      title: 'Sharing you control',
      body: 'You can create share grants that expire, can be revoked, '
          'and can be limited to a single access. The backend stores '
          'ciphertext only and checks the grant on every request. '
          'View-only means BitLock provides no download action and '
          'blocks supported capture paths — it cannot stop someone '
          'photographing a screen.',
    ),
    _OnboardingPage(
      icon: Icons.warning_amber_outlined,
      title: 'Your password is the only way back',
      body: 'There is no account recovery for the vault password and '
          'no copy of your keys on any server. If you forget the '
          'password, the files in the vault may be impossible to '
          'recover. Choose a password you can remember and keep a '
          'separate backup of anything you cannot afford to lose.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _page == _pages.length - 1;

  void _next() {
    if (_isLastPage) {
      widget.onGetStarted();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int index) {
                  setState(() {
                    _page = index;
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  final _OnboardingPage page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: BitLockColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 44,
                            color: BitLockColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.45),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < _pages.length; i++)
                  Container(
                    width: i == _page ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _page
                          ? BitLockColors.primaryLight
                          : BitLockColors.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: <Widget>[
                  if (!_isLastPage)
                    TextButton(
                      onPressed: widget.onGetStarted,
                      child: const Text('Skip'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_isLastPage ? 'Create my vault' : 'Next'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onAlreadyHaveVault,
              child: const Text('I already have a vault'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// One onboarding page of content.
class _OnboardingPage {
  /// Creates an onboarding page description.
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  /// Icon shown at the top of the page.
  final IconData icon;

  /// Page headline.
  final String title;

  /// Page body text.
  final String body;
}
