import 'package:flutter/material.dart';

import '../../app_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.session, required this.onSignOut});

  final AppSession session;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1820), Color(0xFF102C36), Color(0xFF08131A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to ImmichTV',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connected to ${session.serverUrl} as ${session.userEmail}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFFB8C8CF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: onSignOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: const [
                    _LibraryTile(
                      title: 'Timeline',
                      subtitle:
                          'Chronological stream for recent and favorite memories.',
                      icon: Icons.view_stream_outlined,
                    ),
                    _LibraryTile(
                      title: 'Albums',
                      subtitle:
                          'Collection-driven browsing for trips, events, and family stories.',
                      icon: Icons.photo_album_outlined,
                    ),
                    _LibraryTile(
                      title: 'Favorites',
                      subtitle:
                          'Quick access to the best shots for relaxing slideshow playback.',
                      icon: Icons.favorite_border,
                    ),
                    _LibraryTile(
                      title: 'Slideshow',
                      subtitle:
                          'Full-screen playback mode for ambient living-room photo display.',
                      icon: Icons.slideshow_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B22),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF1E3947)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next implementation targets',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '1. Replace mock onboarding with real server validation and login calls.',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '2. Persist the session securely and restore it during bootstrap.',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '3. Add API clients and repository layers for albums, timeline, and assets.',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '4. Start TV focus handling and remote-friendly grid navigation.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B22),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1E3947)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF6FE0DB), size: 30),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFB8C8CF),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
