class MarketingSiteConfig {
  const MarketingSiteConfig._();

  static const String url = String.fromEnvironment(
    'IMMICH_TV_MARKETING_URL',
    defaultValue: 'https://immich-tv.web.app',
  );
}
