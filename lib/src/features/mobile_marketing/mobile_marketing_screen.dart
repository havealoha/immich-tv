import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../shared/presentation/app_colors.dart';

const String _marketingSiteUrl = 'https://immichtvapp.web.app/';
final Uri _marketingSiteBaseUri = Uri.parse(_marketingSiteUrl);

class MobileMarketingScreen extends StatefulWidget {
  const MobileMarketingScreen({super.key});

  @override
  State<MobileMarketingScreen> createState() => _MobileMarketingScreenState();
}

class _MobileMarketingScreenState extends State<MobileMarketingScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(AppColors.background)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) async {
                if (_shouldOpenExternally(request.url)) {
                  final launched = await launchUrl(
                    Uri.parse(request.url),
                    mode: LaunchMode.externalApplication,
                  );
                  if (mounted && !launched) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to open the download link.'),
                      ),
                    );
                  }
                  if (mounted) {
                    await _loadMarketingSite();
                  }
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onProgress: (progress) {
                if (!mounted) {
                  return;
                }
                setState(() => _progress = progress);
              },
              onPageStarted: (_) {
                if (!mounted) {
                  return;
                }
                setState(() => _progress = 0);
              },
              onPageFinished: (_) {
                if (!mounted) {
                  return;
                }
                setState(() => _progress = 100);
              },
            ),
          );
    _loadMarketingSite();
  }

  Future<void> _loadMarketingSite() async {
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    await _controller.loadRequest(_marketingSiteUri());
  }

  Uri _marketingSiteUri() {
    final uri = Uri.parse(_marketingSiteUrl);
    final queryParameters = <String, String>{
      ...uri.queryParameters,
      'source': 'mobile-app',
      'ts': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    return uri.replace(queryParameters: queryParameters);
  }

  bool _shouldOpenExternally(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    if (_isSameMarketingHost(uri)) {
      return false;
    }

    final normalizedPath = uri.path.toLowerCase();
    return normalizedPath.endsWith('.apk') ||
        normalizedPath.contains('/releases/download/') ||
        uri.host.contains('github.com') ||
        uri.host.contains('githubusercontent.com') ||
        uri.host.contains('githubassets.com');
  }

  bool _isSameMarketingHost(Uri uri) {
    return uri.host.toLowerCase() == _marketingSiteBaseUri.host.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const footerBaseHeight = 88.0;
    final footerHeight = footerBaseHeight + safeBottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: safeTop, bottom: footerHeight),
            child: Column(
              children: [
                if (_progress < 100)
                  LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 2,
                    backgroundColor: AppColors.surfaceMuted,
                    color: AppColors.immichBlue,
                  ),
                Expanded(child: WebViewWidget(controller: _controller)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: footerBaseHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderStrong),
                          ),
                          child: const Icon(
                            Icons.tv_outlined,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Built for TV and tablets',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Use a larger screen for the full Immich TV app experience.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _loadMarketingSite,
                          tooltip: 'Reload page',
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
