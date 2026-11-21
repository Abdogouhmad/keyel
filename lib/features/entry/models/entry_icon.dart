import 'package:flutter/material.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Categories grouping available entry icons.
enum EntryIconCategory {
  /// All icons.
  all,

  /// Popular web services and brands.
  brands,

  /// Tech, coding, infrastructure and hardware.
  tech,

  /// Banking, payments, wallets and shopping.
  finance,

  /// Email, documents, office and organization.
  work,

  /// Security, keys, locks and protection.
  security,

  /// Audio, video, camera and gaming.
  media,

  /// Chat, messaging and social platforms.
  social,

  /// Cryptocurrency, exchanges, trading and web3.
  crypto,

  /// Travel, daily life, home and utilities.
  life;

  /// Human-readable label for filter chips.
  String get label => switch (this) {
    EntryIconCategory.all => currentL10n.entryIconCategoryAll,
    EntryIconCategory.brands => currentL10n.entryIconCategoryBrands,
    EntryIconCategory.tech => currentL10n.entryIconCategoryTech,
    EntryIconCategory.finance => currentL10n.entryIconCategoryFinance,
    EntryIconCategory.work => currentL10n.entryIconCategoryWork,
    EntryIconCategory.security => currentL10n.entryIconCategorySecurity,
    EntryIconCategory.media => currentL10n.entryIconCategoryMedia,
    EntryIconCategory.social => currentL10n.entryIconCategorySocial,
    EntryIconCategory.crypto => currentL10n.entryIconCategoryCrypto,
    EntryIconCategory.life => currentL10n.entryIconCategoryLife,
  };
}

/// A selectable icon definition with a unique key, icon glyph, and search tags.
class EntryIcon {
  /// Creates an icon descriptor.
  const new({
    required this.key,
    required this.label,
    required this.icon,
    required this.category,
    this.keywords = const [],
  });

  /// Unique stable slug stored in the vault payload (e.g. `brand_github`).
  final String key;

  /// Human-readable display label (e.g. "GitHub").
  final String label;

  /// Icon glyph.
  final IconData icon;

  /// Icon category.
  final EntryIconCategory category;

  /// Extra search keywords for auto-complete and search.
  final List<String> keywords;

  /// Returns true if this icon matches the given query.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (label.toLowerCase().contains(q)) return true;
    if (key.toLowerCase().contains(q)) return true;
    return keywords.any((k) => k.toLowerCase().contains(q));
  }
}

/// Curated catalogue of icons available for vault entries.
const List<EntryIcon> kEntryIconCatalog = [
  // ── Brands & Popular Services ──
  EntryIcon(
    key: 'brand_google',
    label: 'Google',
    icon: Icons.g_mobiledata_rounded,
    category: EntryIconCategory.brands,
    keywords: ['gmail', 'google drive', 'android', 'alphabet', 'search'],
  ),
  EntryIcon(
    key: 'brand_github',
    label: 'GitHub',
    icon: Icons.code_rounded,
    category: EntryIconCategory.brands,
    keywords: ['git', 'repo', 'source', 'commit', 'developer'],
  ),
  EntryIcon(
    key: 'brand_apple',
    label: 'Apple',
    icon: Icons.apple_rounded,
    category: EntryIconCategory.brands,
    keywords: ['icloud', 'ios', 'macos', 'mac', 'iphone'],
  ),
  EntryIcon(
    key: 'brand_microsoft',
    label: 'Microsoft',
    icon: Icons.window_rounded,
    category: EntryIconCategory.brands,
    keywords: ['windows', 'office', 'outlook', 'azure', 'xbox', '365'],
  ),
  EntryIcon(
    key: 'brand_amazon',
    label: 'Amazon',
    icon: Icons.shopping_cart_rounded,
    category: EntryIconCategory.brands,
    keywords: ['aws', 'prime', 'store', 'ecommerce', 'shopping'],
  ),
  EntryIcon(
    key: 'brand_twitter',
    label: 'X / Twitter',
    icon: Icons.alternate_email_rounded,
    category: EntryIconCategory.brands,
    keywords: ['x', 'tweet', 'social', 'microblog'],
  ),
  EntryIcon(
    key: 'brand_discord',
    label: 'Discord',
    icon: Icons.forum_rounded,
    category: EntryIconCategory.brands,
    keywords: ['chat', 'voice', 'gaming', 'server', 'community'],
  ),
  EntryIcon(
    key: 'brand_slack',
    label: 'Slack',
    icon: Icons.workspaces_rounded,
    category: EntryIconCategory.brands,
    keywords: ['workspace', 'team', 'chat', 'office'],
  ),
  EntryIcon(
    key: 'brand_spotify',
    label: 'Spotify',
    icon: Icons.music_note_rounded,
    category: EntryIconCategory.brands,
    keywords: ['music', 'playlist', 'audio', 'stream', 'podcast'],
  ),
  EntryIcon(
    key: 'brand_netflix',
    label: 'Netflix',
    icon: Icons.movie_rounded,
    category: EntryIconCategory.brands,
    keywords: ['movies', 'streaming', 'film', 'series', 'tv'],
  ),
  EntryIcon(
    key: 'brand_youtube',
    label: 'YouTube',
    icon: Icons.smart_display_rounded,
    category: EntryIconCategory.brands,
    keywords: ['video', 'stream', 'media', 'channel', 'clips'],
  ),
  EntryIcon(
    key: 'brand_reddit',
    label: 'Reddit',
    icon: Icons.reddit_rounded,
    category: EntryIconCategory.brands,
    keywords: ['forum', 'community', 'subreddit', 'karma', 'threads'],
  ),
  EntryIcon(
    key: 'brand_steam',
    label: 'Steam',
    icon: Icons.sports_esports_rounded,
    category: EntryIconCategory.brands,
    keywords: ['valve', 'games', 'gaming', 'store', 'pc'],
  ),
  EntryIcon(
    key: 'brand_linkedin',
    label: 'LinkedIn',
    icon: Icons.business_center_rounded,
    category: EntryIconCategory.brands,
    keywords: ['career', 'jobs', 'professional', 'network'],
  ),
  EntryIcon(
    key: 'brand_facebook',
    label: 'Facebook',
    icon: Icons.facebook_rounded,
    category: EntryIconCategory.brands,
    keywords: ['meta', 'social', 'friends', 'feed'],
  ),
  EntryIcon(
    key: 'brand_telegram',
    label: 'Telegram',
    icon: Icons.send_rounded,
    category: EntryIconCategory.brands,
    keywords: ['messenger', 'chat', 'crypto', 'channel'],
  ),
  EntryIcon(
    key: 'brand_whatsapp',
    label: 'WhatsApp',
    icon: Icons.chat_rounded,
    category: EntryIconCategory.brands,
    keywords: ['chat', 'meta', 'messages', 'calls'],
  ),
  EntryIcon(
    key: 'brand_paypal',
    label: 'PayPal',
    icon: Icons.payments_rounded,
    category: EntryIconCategory.brands,
    keywords: ['payment', 'transfer', 'money', 'checkout', 'pay'],
  ),
  EntryIcon(
    key: 'brand_tiktok',
    label: 'TikTok',
    icon: Icons.music_video_rounded,
    category: EntryIconCategory.brands,
    keywords: ['video', 'short', 'social', 'douyin', 'clips', 'reels'],
  ),
  EntryIcon(
    key: 'brand_snapchat',
    label: 'Snapchat',
    icon: Icons.snapchat_rounded,
    category: EntryIconCategory.brands,
    keywords: ['snap', 'chat', 'social', 'stories', 'ghost'],
  ),
  EntryIcon(
    key: 'brand_pinterest',
    label: 'Pinterest',
    icon: Icons.push_pin_rounded,
    category: EntryIconCategory.brands,
    keywords: ['pins', 'boards', 'ideas', 'inspiration', 'images'],
  ),
  EntryIcon(
    key: 'brand_twitch',
    label: 'Twitch',
    icon: Icons.live_tv_rounded,
    category: EntryIconCategory.brands,
    keywords: ['stream', 'gaming', 'live', 'streamer', 'broadcast'],
  ),
  EntryIcon(
    key: 'brand_adobe',
    label: 'Adobe',
    icon: Icons.adobe_rounded,
    category: EntryIconCategory.brands,
    keywords: ['creative', 'photoshop', 'illustrator', 'pdf', 'design'],
  ),
  EntryIcon(
    key: 'brand_gitlab',
    label: 'GitLab',
    icon: Icons.account_tree_rounded,
    category: EntryIconCategory.brands,
    keywords: ['git', 'devops', 'repo', 'ci', 'source', 'pipeline'],
  ),
  EntryIcon(
    key: 'brand_bitbucket',
    label: 'Bitbucket',
    icon: Icons.source_rounded,
    category: EntryIconCategory.brands,
    keywords: ['git', 'atlassian', 'repo', 'source', 'code'],
  ),
  EntryIcon(
    key: 'brand_stackoverflow',
    label: 'Stack Overflow',
    icon: Icons.question_answer_rounded,
    category: EntryIconCategory.brands,
    keywords: ['developer', 'q&a', 'code', 'help', 'forum'],
  ),
  EntryIcon(
    key: 'brand_dropbox',
    label: 'Dropbox',
    icon: Icons.cloud_queue_rounded,
    category: EntryIconCategory.brands,
    keywords: ['files', 'storage', 'sync', 'backup', 'cloud'],
  ),
  EntryIcon(
    key: 'brand_onedrive',
    label: 'OneDrive',
    icon: Icons.cloud_upload_rounded,
    category: EntryIconCategory.brands,
    keywords: ['microsoft', 'files', 'storage', 'cloud', 'sync'],
  ),
  EntryIcon(
    key: 'brand_icloud',
    label: 'iCloud',
    icon: Icons.cloud_sync_rounded,
    category: EntryIconCategory.brands,
    keywords: ['apple', 'storage', 'backup', 'cloud', 'photos'],
  ),
  EntryIcon(
    key: 'brand_notion',
    label: 'Notion',
    icon: Icons.article_rounded,
    category: EntryIconCategory.brands,
    keywords: ['notes', 'docs', 'wiki', 'workspace', 'knowledge'],
  ),
  EntryIcon(
    key: 'brand_zoom',
    label: 'Zoom',
    icon: Icons.video_call_rounded,
    category: EntryIconCategory.brands,
    keywords: ['meetings', 'video', 'call', 'conference', 'webinar'],
  ),
  EntryIcon(
    key: 'brand_teams',
    label: 'Microsoft Teams',
    icon: Icons.groups_rounded,
    category: EntryIconCategory.brands,
    keywords: ['microsoft', 'meetings', 'chat', 'office', 'collaboration'],
  ),
  EntryIcon(
    key: 'brand_trello',
    label: 'Trello',
    icon: Icons.view_kanban_rounded,
    category: EntryIconCategory.brands,
    keywords: ['boards', 'tasks', 'kanban', 'atlassian', 'project'],
  ),
  EntryIcon(
    key: 'brand_jira',
    label: 'Jira',
    icon: Icons.track_changes_rounded,
    category: EntryIconCategory.brands,
    keywords: ['atlassian', 'issues', 'agile', 'bugs', 'sprint'],
  ),
  EntryIcon(
    key: 'brand_shopify',
    label: 'Shopify',
    icon: Icons.storefront_rounded,
    category: EntryIconCategory.brands,
    keywords: ['ecommerce', 'store', 'shop', 'selling', 'merchant'],
  ),
  EntryIcon(
    key: 'brand_uber',
    label: 'Uber',
    icon: Icons.local_taxi_rounded,
    category: EntryIconCategory.brands,
    keywords: ['ride', 'taxi', 'transport', 'driver', 'trip'],
  ),
  EntryIcon(
    key: 'brand_airbnb',
    label: 'Airbnb',
    icon: Icons.home_work_rounded,
    category: EntryIconCategory.brands,
    keywords: ['stay', 'rental', 'travel', 'booking', 'lodging'],
  ),
  EntryIcon(
    key: 'brand_booking',
    label: 'Booking.com',
    icon: Icons.hotel_rounded,
    category: EntryIconCategory.brands,
    keywords: ['hotel', 'travel', 'reservation', 'stay', 'trip'],
  ),

  // ── Technology & Development ──
  EntryIcon(
    key: 'tech_terminal',
    label: 'Terminal',
    icon: Icons.terminal_rounded,
    category: EntryIconCategory.tech,
    keywords: ['shell', 'bash', 'console', 'cli', 'code', 'command'],
  ),
  EntryIcon(
    key: 'tech_server',
    label: 'Server / VPS',
    icon: Icons.dns_rounded,
    category: EntryIconCategory.tech,
    keywords: ['dns', 'host', 'vps', 'linux', 'cloud', 'domain'],
  ),
  EntryIcon(
    key: 'tech_cloud',
    label: 'Cloud Service',
    icon: Icons.cloud_rounded,
    category: EntryIconCategory.tech,
    keywords: ['storage', 'sync', 'backup', 'drive', 'dropbox'],
  ),
  EntryIcon(
    key: 'tech_database',
    label: 'Database',
    icon: Icons.storage_rounded,
    category: EntryIconCategory.tech,
    keywords: ['sql', 'postgres', 'mysql', 'mongo', 'storage', 'data'],
  ),
  EntryIcon(
    key: 'tech_laptop',
    label: 'Computer / PC',
    icon: Icons.laptop_rounded,
    category: EntryIconCategory.tech,
    keywords: ['laptop', 'macbook', 'desktop', 'workstation'],
  ),
  EntryIcon(
    key: 'tech_smartphone',
    label: 'Mobile Device',
    icon: Icons.smartphone_rounded,
    category: EntryIconCategory.tech,
    keywords: ['phone', 'android', 'iphone', 'tablet'],
  ),
  EntryIcon(
    key: 'tech_cpu',
    label: 'Hardware / Chip',
    icon: Icons.memory_rounded,
    category: EntryIconCategory.tech,
    keywords: ['chip', 'processor', 'ram', 'hardware'],
  ),
  EntryIcon(
    key: 'tech_wifi',
    label: 'Router / Network',
    icon: Icons.wifi_rounded,
    category: EntryIconCategory.tech,
    keywords: ['internet', 'modem', 'wifi', 'gateway', 'lan'],
  ),
  EntryIcon(
    key: 'tech_bug',
    label: 'Issue Tracker',
    icon: Icons.bug_report_rounded,
    category: EntryIconCategory.tech,
    keywords: ['bug', 'jira', 'tracker', 'linear', 'sentry'],
  ),
  EntryIcon(
    key: 'tech_api',
    label: 'API / Token',
    icon: Icons.api_rounded,
    category: EntryIconCategory.tech,
    keywords: ['api key', 'rest', 'secret', 'developer', 'token'],
  ),
  EntryIcon(
    key: 'tech_integration',
    label: 'Integration / Webhook',
    icon: Icons.integration_instructions_rounded,
    category: EntryIconCategory.tech,
    keywords: ['webhook', 'zapier', 'automation', 'workflow', 'connect'],
  ),
  EntryIcon(
    key: 'tech_data',
    label: 'Data / JSON',
    icon: Icons.data_object_rounded,
    category: EntryIconCategory.tech,
    keywords: ['json', 'xml', 'payload', 'schema', 'object'],
  ),
  EntryIcon(
    key: 'tech_ai',
    label: 'AI / Machine Learning',
    icon: Icons.smart_toy_rounded,
    category: EntryIconCategory.tech,
    keywords: ['ai', 'chatgpt', 'openai', 'ml', 'model', 'bot'],
  ),
  EntryIcon(
    key: 'tech_analytics_engine',
    label: 'Monitoring / Metrics',
    icon: Icons.monitor_heart_rounded,
    category: EntryIconCategory.tech,
    keywords: ['grafana', 'prometheus', 'uptime', 'monitoring', 'status'],
  ),
  EntryIcon(
    key: 'tech_ci',
    label: 'CI / Pipelines',
    icon: Icons.rocket_launch_rounded,
    category: EntryIconCategory.tech,
    keywords: ['ci', 'cd', 'deploy', 'pipeline', 'actions', 'build'],
  ),
  EntryIcon(
    key: 'tech_router',
    label: 'Router / Gateway',
    icon: Icons.router_rounded,
    category: EntryIconCategory.tech,
    keywords: ['gateway', 'modem', 'network', 'switch', 'firewall'],
  ),
  EntryIcon(
    key: 'tech_usb',
    label: 'USB / Hardware Key',
    icon: Icons.usb_rounded,
    category: EntryIconCategory.tech,
    keywords: ['yubikey', 'hardware', 'token', 'fido', 'usb'],
  ),
  EntryIcon(
    key: 'tech_hub',
    label: 'Hub / Self-hosted',
    icon: Icons.hub_rounded,
    category: EntryIconCategory.tech,
    keywords: ['homelab', 'nas', 'selfhosted', 'services', 'cluster'],
  ),
  EntryIcon(
    key: 'tech_developer',
    label: 'Developer Board',
    icon: Icons.developer_board_rounded,
    category: EntryIconCategory.tech,
    keywords: ['embedded', 'arduino', 'raspberry pi', 'iot', 'microcontroller'],
  ),
  EntryIcon(
    key: 'tech_science',
    label: 'Science / Lab',
    icon: Icons.science_rounded,
    category: EntryIconCategory.tech,
    keywords: ['research', 'lab', 'experiment', 'chemistry', 'physics'],
  ),
  EntryIcon(
    key: 'tech_manufacturing',
    label: 'Infrastructure / Ops',
    icon: Icons.precision_manufacturing_rounded,
    category: EntryIconCategory.tech,
    keywords: ['ops', 'devops', 'infra', 'factory', 'industrial'],
  ),

  // ── Banking & Finance ──
  EntryIcon(
    key: 'finance_bank',
    label: 'Bank Account',
    icon: Icons.account_balance_rounded,
    category: EntryIconCategory.finance,
    keywords: ['bank', 'chase', 'citi', 'wells', 'savings', 'checking'],
  ),
  EntryIcon(
    key: 'finance_wallet',
    label: 'Digital Wallet',
    icon: Icons.account_balance_wallet_rounded,
    category: EntryIconCategory.finance,
    keywords: ['wallet', 'apple pay', 'google pay', 'crypto wallet'],
  ),
  EntryIcon(
    key: 'finance_card',
    label: 'Credit / Debit Card',
    icon: Icons.credit_card_rounded,
    category: EntryIconCategory.finance,
    keywords: ['visa', 'mastercard', 'amex', 'payment card'],
  ),
  EntryIcon(
    key: 'finance_savings',
    label: 'Investment / Savings',
    icon: Icons.savings_rounded,
    category: EntryIconCategory.finance,
    keywords: ['stocks', 'piggy', 'pension', 'funds', 'crypto'],
  ),
  EntryIcon(
    key: 'finance_cash',
    label: 'Currency / Cash',
    icon: Icons.attach_money_rounded,
    category: EntryIconCategory.finance,
    keywords: ['money', 'dollar', 'euro', 'salary', 'income'],
  ),
  EntryIcon(
    key: 'finance_receipt',
    label: 'Billing / Invoices',
    icon: Icons.receipt_long_rounded,
    category: EntryIconCategory.finance,
    keywords: ['invoice', 'bill', 'receipt', 'tax', 'accounting'],
  ),
  EntryIcon(
    key: 'finance_store',
    label: 'Store / Merchant',
    icon: Icons.store_rounded,
    category: EntryIconCategory.finance,
    keywords: ['shop', 'retail', 'marketplace', 'vendor'],
  ),
  EntryIcon(
    key: 'finance_shopping_bag',
    label: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    category: EntryIconCategory.finance,
    keywords: ['ecommerce', 'buy', 'orders', 'delivery'],
  ),
  EntryIcon(
    key: 'finance_analytics',
    label: 'Investing / Markets',
    icon: Icons.show_chart_rounded,
    category: EntryIconCategory.finance,
    keywords: ['stocks', 'trading', 'portfolio', 'etf', 'brokerage'],
  ),
  EntryIcon(
    key: 'finance_candles',
    label: 'Trading / Charts',
    icon: Icons.candlestick_chart_rounded,
    category: EntryIconCategory.finance,
    keywords: ['trading', 'forex', 'candles', 'market', 'exchange'],
  ),
  EntryIcon(
    key: 'finance_price',
    label: 'Pricing / Billing',
    icon: Icons.price_check_rounded,
    category: EntryIconCategory.finance,
    keywords: ['price', 'plan', 'subscription', 'quote', 'billing'],
  ),
  EntryIcon(
    key: 'finance_transfer',
    label: 'Money Transfer',
    icon: Icons.currency_exchange_rounded,
    category: EntryIconCategory.finance,
    keywords: ['remittance', 'wise', 'transfer', 'forex', 'exchange'],
  ),
  EntryIcon(
    key: 'finance_gift_card',
    label: 'Gift Card / Voucher',
    icon: Icons.card_giftcard_rounded,
    category: EntryIconCategory.finance,
    keywords: ['gift', 'voucher', 'coupon', 'promo', 'redeem'],
  ),
  EntryIcon(
    key: 'finance_rewards',
    label: 'Rewards / Loyalty',
    icon: Icons.redeem_rounded,
    category: EntryIconCategory.finance,
    keywords: ['points', 'loyalty', 'rewards', 'cashback', 'perks'],
  ),
  EntryIcon(
    key: 'finance_contactless',
    label: 'Contactless Payment',
    icon: Icons.contactless_rounded,
    category: EntryIconCategory.finance,
    keywords: ['nfc', 'tap', 'contactless', 'card', 'pay'],
  ),
  EntryIcon(
    key: 'finance_qr_pay',
    label: 'QR Payment',
    icon: Icons.qr_code_rounded,
    category: EntryIconCategory.finance,
    keywords: ['qr', 'scan', 'pay', 'code', 'checkout'],
  ),

  // ── Work & Productivity ──
  EntryIcon(
    key: 'work_email',
    label: 'Email',
    icon: Icons.mail_rounded,
    category: EntryIconCategory.work,
    keywords: ['mail', 'inbox', 'mailbox', 'proton', 'fastmail'],
  ),
  EntryIcon(
    key: 'work_inbox',
    label: 'Mailbox',
    icon: Icons.inbox_rounded,
    category: EntryIconCategory.work,
    keywords: ['inbox', 'archive', 'messages'],
  ),
  EntryIcon(
    key: 'work_calendar',
    label: 'Calendar / Schedule',
    icon: Icons.calendar_month_rounded,
    category: EntryIconCategory.work,
    keywords: ['meetings', 'schedule', 'agenda', 'appointments'],
  ),
  EntryIcon(
    key: 'work_document',
    label: 'Documents / Notes',
    icon: Icons.description_rounded,
    category: EntryIconCategory.work,
    keywords: ['notion', 'docs', 'word', 'file', 'text', 'paper'],
  ),
  EntryIcon(
    key: 'work_folder',
    label: 'Folder / Project',
    icon: Icons.folder_rounded,
    category: EntryIconCategory.work,
    keywords: ['directory', 'project', 'files', 'group'],
  ),
  EntryIcon(
    key: 'work_task',
    label: 'Tasks / Checklist',
    icon: Icons.checklist_rounded,
    category: EntryIconCategory.work,
    keywords: ['todo', 'checklist', 'tasks', 'trello', 'asana'],
  ),
  EntryIcon(
    key: 'work_briefcase',
    label: 'Job / Employment',
    icon: Icons.badge_rounded,
    category: EntryIconCategory.work,
    keywords: ['work', 'company', 'corporate', 'hr', 'payroll'],
  ),
  EntryIcon(
    key: 'work_analytics',
    label: 'Analytics / Metrics',
    icon: Icons.analytics_rounded,
    category: EntryIconCategory.work,
    keywords: ['stats', 'dashboard', 'graph', 'chart', 'kpi'],
  ),
  EntryIcon(
    key: 'work_bookmark',
    label: 'Bookmark / Portal',
    icon: Icons.bookmark_rounded,
    category: EntryIconCategory.work,
    keywords: ['favorite', 'link', 'portal', 'saved'],
  ),
  EntryIcon(
    key: 'work_task_done',
    label: 'Completed / Done',
    icon: Icons.task_alt_rounded,
    category: EntryIconCategory.work,
    keywords: ['done', 'complete', 'finished', 'approved'],
  ),
  EntryIcon(
    key: 'work_event',
    label: 'Event / Reminder',
    icon: Icons.event_note_rounded,
    category: EntryIconCategory.work,
    keywords: ['event', 'reminder', 'note', 'schedule', 'deadline'],
  ),
  EntryIcon(
    key: 'work_note',
    label: 'Quick Note',
    icon: Icons.note_alt_rounded,
    category: EntryIconCategory.work,
    keywords: ['note', 'memo', 'text', 'scratch', 'jot'],
  ),
  EntryIcon(
    key: 'work_assignment',
    label: 'Assignment / Ticket',
    icon: Icons.assignment_rounded,
    category: EntryIconCategory.work,
    keywords: ['ticket', 'task', 'assignment', 'work', 'issue'],
  ),
  EntryIcon(
    key: 'work_corporate',
    label: 'Company / Corporate',
    icon: Icons.corporate_fare_rounded,
    category: EntryIconCategory.work,
    keywords: ['company', 'corporate', 'office', 'enterprise', 'organization'],
  ),

  // ── Security & Privacy ──
  EntryIcon(
    key: 'sec_key',
    label: 'Master Key',
    icon: Icons.key_rounded,
    category: EntryIconCategory.security,
    keywords: ['key', 'login', 'credentials', 'password'],
  ),
  EntryIcon(
    key: 'sec_lock',
    label: 'Lock / Safe',
    icon: Icons.lock_rounded,
    category: EntryIconCategory.security,
    keywords: ['vault', 'secure', 'private', 'encrypted'],
  ),
  EntryIcon(
    key: 'sec_shield',
    label: 'Shield / Antivirus',
    icon: Icons.shield_rounded,
    category: EntryIconCategory.security,
    keywords: ['firewall', 'protection', 'guard', 'defense'],
  ),
  EntryIcon(
    key: 'sec_fingerprint',
    label: 'Biometrics',
    icon: Icons.fingerprint_rounded,
    category: EntryIconCategory.security,
    keywords: ['touch id', 'face id', 'biometric', 'finger'],
  ),
  EntryIcon(
    key: 'sec_password',
    label: 'Password',
    icon: Icons.password_rounded,
    category: EntryIconCategory.security,
    keywords: ['pin', 'code', 'passcode', 'secret'],
  ),
  EntryIcon(
    key: 'sec_verified',
    label: 'Verified / 2FA',
    icon: Icons.verified_user_rounded,
    category: EntryIconCategory.security,
    keywords: ['authenticator', 'totp', 'verified', 'trusted'],
  ),
  EntryIcon(
    key: 'sec_vpn',
    label: 'VPN / Proxy',
    icon: Icons.vpn_key_rounded,
    category: EntryIconCategory.security,
    keywords: ['vpn', 'proxy', 'tunnel', 'wireguard', 'openvpn'],
  ),
  EntryIcon(
    key: 'sec_badge',
    label: 'Security Clearance',
    icon: Icons.security_rounded,
    category: EntryIconCategory.security,
    keywords: ['admin', 'root', 'security', 'guard'],
  ),
  EntryIcon(
    key: 'sec_admin',
    label: 'Administrator',
    icon: Icons.admin_panel_settings_rounded,
    category: EntryIconCategory.security,
    keywords: ['admin', 'root', 'superuser', 'privileged', 'control'],
  ),
  EntryIcon(
    key: 'sec_account_guard',
    label: 'Protected Account',
    icon: Icons.lock_person_rounded,
    category: EntryIconCategory.security,
    keywords: ['account', 'protected', 'private', 'personal'],
  ),
  EntryIcon(
    key: 'sec_stealth',
    label: 'Stealth / Anonymous',
    icon: Icons.shield_moon_rounded,
    category: EntryIconCategory.security,
    keywords: ['anonymous', 'stealth', 'incognito', 'private', 'dark'],
  ),
  EntryIcon(
    key: 'sec_history',
    label: 'Audit / History',
    icon: Icons.history_rounded,
    category: EntryIconCategory.security,
    keywords: ['audit', 'history', 'log', 'activity', 'past'],
  ),
  EntryIcon(
    key: 'sec_reveal',
    label: 'Reveal / Visible',
    icon: Icons.visibility_rounded,
    category: EntryIconCategory.security,
    keywords: ['show', 'reveal', 'visible', 'view', 'eye'],
  ),
  EntryIcon(
    key: 'sec_hidden',
    label: 'Hidden / Masked',
    icon: Icons.visibility_off_rounded,
    category: EntryIconCategory.security,
    keywords: ['hide', 'hidden', 'masked', 'secret', 'concealed'],
  ),
  EntryIcon(
    key: 'sec_alarm',
    label: 'Breach Alert',
    icon: Icons.gpp_maybe_rounded,
    category: EntryIconCategory.security,
    keywords: ['alert', 'breach', 'warning', 'risk', 'leak'],
  ),
  EntryIcon(
    key: 'sec_phishing',
    label: 'Phishing / Spam',
    icon: Icons.phishing_rounded,
    category: EntryIconCategory.security,
    keywords: ['phishing', 'spam', 'scam', 'fraud', 'malicious'],
  ),
  EntryIcon(
    key: 'sec_privacy',
    label: 'Privacy',
    icon: Icons.privacy_tip_rounded,
    category: EntryIconCategory.security,
    keywords: ['privacy', 'gdpr', 'personal data', 'consent', 'policy'],
  ),
  EntryIcon(
    key: 'sec_policy',
    label: 'Policy / Compliance',
    icon: Icons.policy_rounded,
    category: EntryIconCategory.security,
    keywords: ['policy', 'compliance', 'rules', 'governance', 'terms'],
  ),
  EntryIcon(
    key: 'sec_timer',
    label: 'Session Timeout',
    icon: Icons.timer_rounded,
    category: EntryIconCategory.security,
    keywords: ['timeout', 'expiry', 'timer', 'session', 'auto-lock'],
  ),

  // ── Media & Entertainment ──
  EntryIcon(
    key: 'media_headphones',
    label: 'Audio / Music',
    icon: Icons.headphones_rounded,
    category: EntryIconCategory.media,
    keywords: ['headphones', 'listen', 'sound', 'album'],
  ),
  EntryIcon(
    key: 'media_camera',
    label: 'Photography / Photos',
    icon: Icons.photo_camera_rounded,
    category: EntryIconCategory.media,
    keywords: ['photos', 'camera', 'instagram', 'gallery', 'flick'],
  ),
  EntryIcon(
    key: 'media_video',
    label: 'Video / Cinema',
    icon: Icons.videocam_rounded,
    category: EntryIconCategory.media,
    keywords: ['recording', 'vlog', 'camera', 'twitch'],
  ),
  EntryIcon(
    key: 'media_tv',
    label: 'TV / Streaming',
    icon: Icons.tv_rounded,
    category: EntryIconCategory.media,
    keywords: ['hulu', 'disney', 'hbo', 'broadcast', 'television'],
  ),
  EntryIcon(
    key: 'media_podcast',
    label: 'Podcast / Radio',
    icon: Icons.podcasts_rounded,
    category: EntryIconCategory.media,
    keywords: ['broadcast', 'rss', 'audiobook', 'audible'],
  ),
  EntryIcon(
    key: 'media_gaming',
    label: 'Gaming / Console',
    icon: Icons.videogame_asset_rounded,
    category: EntryIconCategory.media,
    keywords: ['playstation', 'nintendo', 'game', 'epic', 'riot'],
  ),
  EntryIcon(
    key: 'media_music_library',
    label: 'Music Library',
    icon: Icons.library_music_rounded,
    category: EntryIconCategory.media,
    keywords: ['library', 'playlist', 'collection', 'songs', 'albums'],
  ),
  EntryIcon(
    key: 'media_album',
    label: 'Album / Record',
    icon: Icons.album_rounded,
    category: EntryIconCategory.media,
    keywords: ['album', 'vinyl', 'record', 'disc', 'track'],
  ),
  EntryIcon(
    key: 'media_photo_library',
    label: 'Photo Library',
    icon: Icons.photo_library_rounded,
    category: EntryIconCategory.media,
    keywords: ['photos', 'gallery', 'images', 'album', 'pictures'],
  ),
  EntryIcon(
    key: 'media_video_library',
    label: 'Video Library',
    icon: Icons.video_library_rounded,
    category: EntryIconCategory.media,
    keywords: ['videos', 'library', 'movies', 'collection', 'clips'],
  ),
  EntryIcon(
    key: 'media_theater',
    label: 'Cinema / Theatre',
    icon: Icons.theaters_rounded,
    category: EntryIconCategory.media,
    keywords: ['cinema', 'theater', 'movies', 'show', 'screen'],
  ),
  EntryIcon(
    key: 'media_radio',
    label: 'Radio / FM',
    icon: Icons.radio_rounded,
    category: EntryIconCategory.media,
    keywords: ['radio', 'fm', 'station', 'broadcast', 'tunein'],
  ),
  EntryIcon(
    key: 'media_equalizer',
    label: 'Audio / Equalizer',
    icon: Icons.graphic_eq_rounded,
    category: EntryIconCategory.media,
    keywords: ['audio', 'equalizer', 'sound', 'mix', 'producer'],
  ),
  EntryIcon(
    key: 'media_camera_roll',
    label: 'Camera Roll',
    icon: Icons.camera_roll_rounded,
    category: EntryIconCategory.media,
    keywords: ['photos', 'camera', 'roll', 'shots', 'film'],
  ),

  // ── Social & Communication ──
  EntryIcon(
    key: 'social_chat',
    label: 'Messaging / Chat',
    icon: Icons.chat_bubble_rounded,
    category: EntryIconCategory.social,
    keywords: ['signal', 'imessage', 'sms', 'text', 'talk'],
  ),
  EntryIcon(
    key: 'social_contacts',
    label: 'Contacts / Address Book',
    icon: Icons.contacts_rounded,
    category: EntryIconCategory.social,
    keywords: ['directory', 'people', 'address', 'phonebook'],
  ),
  EntryIcon(
    key: 'social_people',
    label: 'Community / Group',
    icon: Icons.people_rounded,
    category: EntryIconCategory.social,
    keywords: ['team', 'members', 'club', 'social'],
  ),
  EntryIcon(
    key: 'social_phone',
    label: 'Phone / VOIP',
    icon: Icons.call_rounded,
    category: EntryIconCategory.social,
    keywords: ['telecom', 'carrier', 'skype', 'zoom'],
  ),
  EntryIcon(
    key: 'social_group_add',
    label: 'Add Contact / Invite',
    icon: Icons.person_add_rounded,
    category: EntryIconCategory.social,
    keywords: ['invite', 'add', 'friend', 'contact', 'signup'],
  ),
  EntryIcon(
    key: 'social_forum',
    label: 'Forum / Community',
    icon: Icons.forum_rounded,
    category: EntryIconCategory.social,
    keywords: ['forum', 'community', 'discussion', 'board', 'thread'],
  ),
  EntryIcon(
    key: 'social_comment',
    label: 'Comments / Feedback',
    icon: Icons.comment_rounded,
    category: EntryIconCategory.social,
    keywords: ['comment', 'feedback', 'reply', 'review', 'chat'],
  ),
  EntryIcon(
    key: 'social_share',
    label: 'Share / Social',
    icon: Icons.share_rounded,
    category: EntryIconCategory.social,
    keywords: ['share', 'send', 'social', 'post', 'broadcast'],
  ),
  EntryIcon(
    key: 'social_public',
    label: 'Public / Web Profile',
    icon: Icons.public_rounded,
    category: EntryIconCategory.social,
    keywords: ['public', 'profile', 'global', 'web', 'world'],
  ),
  EntryIcon(
    key: 'social_campaign',
    label: 'Announcements / News',
    icon: Icons.campaign_rounded,
    category: EntryIconCategory.social,
    keywords: ['news', 'announcement', 'broadcast', 'marketing', 'feed'],
  ),
  EntryIcon(
    key: 'social_rss',
    label: 'RSS / Feeds',
    icon: Icons.rss_feed_rounded,
    category: EntryIconCategory.social,
    keywords: ['rss', 'feed', 'subscribe', 'news', 'reader'],
  ),
  EntryIcon(
    key: 'social_mic',
    label: 'Podcast / Voice',
    icon: Icons.mic_rounded,
    category: EntryIconCategory.social,
    keywords: ['voice', 'podcast', 'record', 'microphone', 'audio'],
  ),
  EntryIcon(
    key: 'social_diversity',
    label: 'Groups / Family',
    icon: Icons.diversity_3_rounded,
    category: EntryIconCategory.social,
    keywords: ['family', 'group', 'community', 'team', 'people'],
  ),

  // ── Cryptocurrency & Web3 ──
  EntryIcon(
    key: 'crypto_bitcoin',
    label: 'Bitcoin',
    icon: Icons.currency_bitcoin_rounded,
    category: EntryIconCategory.crypto,
    keywords: ['btc', 'bitcoin', 'satoshi', 'crypto', 'wallet'],
  ),
  EntryIcon(
    key: 'crypto_ethereum',
    label: 'Ethereum / Token',
    icon: Icons.token_rounded,
    category: EntryIconCategory.crypto,
    keywords: ['eth', 'ethereum', 'token', 'erc20', 'web3'],
  ),
  EntryIcon(
    key: 'crypto_exchange',
    label: 'Crypto Exchange',
    icon: Icons.currency_exchange_rounded,
    category: EntryIconCategory.crypto,
    keywords: ['binance', 'coinbase', 'kraken', 'exchange', 'swap'],
  ),
  EntryIcon(
    key: 'crypto_trading',
    label: 'Trading / DeFi',
    icon: Icons.candlestick_chart_rounded,
    category: EntryIconCategory.crypto,
    keywords: ['trading', 'defi', 'dex', 'swap', 'liquidity'],
  ),
  EntryIcon(
    key: 'crypto_portfolio',
    label: 'Portfolio / Tracker',
    icon: Icons.stacked_line_chart_rounded,
    category: EntryIconCategory.crypto,
    keywords: ['portfolio', 'tracker', 'holdings', 'gains', 'charts'],
  ),
  EntryIcon(
    key: 'crypto_nft',
    label: 'NFT / Collectibles',
    icon: Icons.interests_rounded,
    category: EntryIconCategory.crypto,
    keywords: ['nft', 'collectible', 'opensea', 'mint', 'digital art'],
  ),
  EntryIcon(
    key: 'crypto_hardware_wallet',
    label: 'Hardware Wallet',
    icon: Icons.usb_rounded,
    category: EntryIconCategory.crypto,
    keywords: ['ledger', 'trezor', 'hardware', 'cold storage', 'seed'],
  ),
  EntryIcon(
    key: 'crypto_mining',
    label: 'Mining / Node',
    icon: Icons.developer_board_rounded,
    category: EntryIconCategory.crypto,
    keywords: ['mining', 'node', 'validator', 'staking', 'rig'],
  ),
  EntryIcon(
    key: 'crypto_wallet',
    label: 'Crypto Wallet',
    icon: Icons.account_balance_wallet_rounded,
    category: EntryIconCategory.crypto,
    keywords: ['wallet', 'metamask', 'address', 'seed phrase', 'keys'],
  ),
  EntryIcon(
    key: 'crypto_earn',
    label: 'Staking / Yield',
    icon: Icons.savings_rounded,
    category: EntryIconCategory.crypto,
    keywords: ['staking', 'yield', 'apy', 'earn', 'interest'],
  ),

  // ── Life, Travel & Utilities ──
  EntryIcon(
    key: 'life_home',
    label: 'Home / Real Estate',
    icon: Icons.home_rounded,
    category: EntryIconCategory.life,
    keywords: ['house', 'apartment', 'mortgage', 'rent', 'smart home'],
  ),
  EntryIcon(
    key: 'life_car',
    label: 'Automobile / Transit',
    icon: Icons.directions_car_rounded,
    category: EntryIconCategory.life,
    keywords: ['car', 'auto', 'uber', 'lyft', 'parking', 'tesla'],
  ),
  EntryIcon(
    key: 'life_flight',
    label: 'Airlines / Travel',
    icon: Icons.flight_rounded,
    category: EntryIconCategory.life,
    keywords: ['plane', 'booking', 'flight', 'expedia', 'airbnb'],
  ),
  EntryIcon(
    key: 'life_train',
    label: 'Train / Public Transit',
    icon: Icons.train_rounded,
    category: EntryIconCategory.life,
    keywords: ['metro', 'subway', 'bus', 'rail', 'transit'],
  ),
  EntryIcon(
    key: 'life_map',
    label: 'Maps / Navigation',
    icon: Icons.location_on_rounded,
    category: EntryIconCategory.life,
    keywords: ['gps', 'directions', 'places', 'address'],
  ),
  EntryIcon(
    key: 'life_coffee',
    label: 'Coffee / Dining',
    icon: Icons.coffee_rounded,
    category: EntryIconCategory.life,
    keywords: ['starbucks', 'cafe', 'breakfast', 'food'],
  ),
  EntryIcon(
    key: 'life_restaurant',
    label: 'Restaurant / Food Delivery',
    icon: Icons.restaurant_rounded,
    category: EntryIconCategory.life,
    keywords: ['doordash', 'ubereats', 'delivery', 'dinner', 'dining'],
  ),
  EntryIcon(
    key: 'life_health',
    label: 'Healthcare / Medical',
    icon: Icons.favorite_rounded,
    category: EntryIconCategory.life,
    keywords: ['health', 'doctor', 'pharmacy', 'hospital', 'insurance'],
  ),
  EntryIcon(
    key: 'life_school',
    label: 'Education / University',
    icon: Icons.school_rounded,
    category: EntryIconCategory.life,
    keywords: ['college', 'student', 'courses', 'canvas', 'learning'],
  ),
  EntryIcon(
    key: 'life_fitness',
    label: 'Fitness / Gym',
    icon: Icons.fitness_center_rounded,
    category: EntryIconCategory.life,
    keywords: ['workout', 'gym', 'training', 'strava'],
  ),
  EntryIcon(
    key: 'life_utilities',
    label: 'Utilities / Electricity',
    icon: Icons.bolt_rounded,
    category: EntryIconCategory.life,
    keywords: ['power', 'electric', 'energy', 'water', 'gas'],
  ),
  EntryIcon(
    key: 'life_web',
    label: 'Web / Internet',
    icon: Icons.language_rounded,
    category: EntryIconCategory.life,
    keywords: ['browser', 'website', 'url', 'online'],
  ),
  EntryIcon(
    key: 'life_pets',
    label: 'Pets / Animals',
    icon: Icons.pets_rounded,
    category: EntryIconCategory.life,
    keywords: ['pet', 'dog', 'cat', 'vet', 'animal'],
  ),
  EntryIcon(
    key: 'life_medical',
    label: 'Medical / Doctor',
    icon: Icons.medical_services_rounded,
    category: EntryIconCategory.life,
    keywords: ['doctor', 'clinic', 'medical', 'health', 'appointment'],
  ),
  EntryIcon(
    key: 'life_pharmacy',
    label: 'Pharmacy',
    icon: Icons.local_pharmacy_rounded,
    category: EntryIconCategory.life,
    keywords: ['pharmacy', 'prescription', 'medicine', 'drugstore', 'rx'],
  ),
  EntryIcon(
    key: 'life_hospital',
    label: 'Hospital / Emergency',
    icon: Icons.local_hospital_rounded,
    category: EntryIconCategory.life,
    keywords: ['hospital', 'emergency', 'clinic', 'urgent', 'care'],
  ),
  EntryIcon(
    key: 'life_childcare',
    label: 'Kids / Childcare',
    icon: Icons.child_care_rounded,
    category: EntryIconCategory.life,
    keywords: ['kids', 'baby', 'childcare', 'school', 'family'],
  ),
  EntryIcon(
    key: 'life_celebration',
    label: 'Celebration / Party',
    icon: Icons.celebration_rounded,
    category: EntryIconCategory.life,
    keywords: ['party', 'celebration', 'event', 'birthday', 'festival'],
  ),
  EntryIcon(
    key: 'life_grocery',
    label: 'Groceries',
    icon: Icons.local_grocery_store_rounded,
    category: EntryIconCategory.life,
    keywords: ['grocery', 'supermarket', 'food', 'market', 'essentials'],
  ),
  EntryIcon(
    key: 'life_parking',
    label: 'Parking',
    icon: Icons.local_parking_rounded,
    category: EntryIconCategory.life,
    keywords: ['parking', 'garage', 'car park', 'lot', 'meter'],
  ),
  EntryIcon(
    key: 'life_fuel',
    label: 'Fuel / Gas Station',
    icon: Icons.local_gas_station_rounded,
    category: EntryIconCategory.life,
    keywords: ['fuel', 'gas', 'petrol', 'charging', 'station'],
  ),
  EntryIcon(
    key: 'life_cleaning',
    label: 'Cleaning / Laundry',
    icon: Icons.cleaning_services_rounded,
    category: EntryIconCategory.life,
    keywords: ['laundry', 'cleaning', 'housekeeping', 'dryer', 'maid'],
  ),
  EntryIcon(
    key: 'life_water',
    label: 'Water Utility',
    icon: Icons.water_drop_rounded,
    category: EntryIconCategory.life,
    keywords: ['water', 'utility', 'bill', 'supply', 'plumbing'],
  ),
  EntryIcon(
    key: 'life_climate',
    label: 'Heating / Cooling',
    icon: Icons.thermostat_rounded,
    category: EntryIconCategory.life,
    keywords: ['thermostat', 'heating', 'cooling', 'hvac', 'climate'],
  ),
  EntryIcon(
    key: 'life_recycling',
    label: 'Recycling / Waste',
    icon: Icons.recycling_rounded,
    category: EntryIconCategory.life,
    keywords: ['recycle', 'waste', 'environment', 'green', 'disposal'],
  ),
  EntryIcon(
    key: 'life_agriculture',
    label: 'Farming / Agriculture',
    icon: Icons.agriculture_rounded,
    category: EntryIconCategory.life,
    keywords: ['farm', 'agriculture', 'tractor', 'crops', 'garden'],
  ),
  EntryIcon(
    key: 'life_nature',
    label: 'Nature / Outdoors',
    icon: Icons.park_rounded,
    category: EntryIconCategory.life,
    keywords: ['nature', 'park', 'outdoors', 'tree', 'trail'],
  ),
  EntryIcon(
    key: 'life_beach',
    label: 'Beach / Vacation',
    icon: Icons.beach_access_rounded,
    category: EntryIconCategory.life,
    keywords: ['beach', 'vacation', 'holiday', 'umbrella', 'resort'],
  ),
  EntryIcon(
    key: 'life_spa',
    label: 'Spa / Wellness',
    icon: Icons.spa_rounded,
    category: EntryIconCategory.life,
    keywords: ['spa', 'wellness', 'massage', 'relax', 'beauty'],
  ),
  EntryIcon(
    key: 'life_luggage',
    label: 'Travel / Luggage',
    icon: Icons.luggage_rounded,
    category: EntryIconCategory.life,
    keywords: ['travel', 'luggage', 'bag', 'trip', 'packing'],
  ),
  EntryIcon(
    key: 'life_explore',
    label: 'Explore / Adventure',
    icon: Icons.explore_rounded,
    category: EntryIconCategory.life,
    keywords: ['explore', 'adventure', 'compass', 'discover', 'travel'],
  ),
  EntryIcon(
    key: 'life_sailing',
    label: 'Boat / Sailing',
    icon: Icons.sailing_rounded,
    category: EntryIconCategory.life,
    keywords: ['boat', 'sailing', 'marine', 'yacht', 'cruise'],
  ),
  EntryIcon(
    key: 'life_cycling',
    label: 'Cycling / Bike',
    icon: Icons.pedal_bike_rounded,
    category: EntryIconCategory.life,
    keywords: ['bike', 'cycling', 'bicycle', 'commute', 'peloton'],
  ),
  EntryIcon(
    key: 'life_motorbike',
    label: 'Motorbike / Scooter',
    icon: Icons.two_wheeler_rounded,
    category: EntryIconCategory.life,
    keywords: ['motorbike', 'scooter', 'motorcycle', 'moped', 'delivery'],
  ),
  EntryIcon(
    key: 'life_ev',
    label: 'Electric Vehicle',
    icon: Icons.electric_car_rounded,
    category: EntryIconCategory.life,
    keywords: ['ev', 'electric', 'tesla', 'car', 'charging'],
  ),
  EntryIcon(
    key: 'life_transit',
    label: 'Public Transit',
    icon: Icons.directions_subway_rounded,
    category: EntryIconCategory.life,
    keywords: ['subway', 'metro', 'transit', 'bus', 'commute'],
  ),
  EntryIcon(
    key: 'life_flight_takeoff',
    label: 'Flight / Departure',
    icon: Icons.flight_takeoff_rounded,
    category: EntryIconCategory.life,
    keywords: ['flight', 'departure', 'airport', 'travel', 'boarding'],
  ),
  EntryIcon(
    key: 'life_backpack',
    label: 'Backpack / School',
    icon: Icons.backpack_rounded,
    category: EntryIconCategory.life,
    keywords: ['backpack', 'school', 'student', 'bag', 'campus'],
  ),
  EntryIcon(
    key: 'life_sports',
    label: 'Sports / Ball Games',
    icon: Icons.sports_soccer_rounded,
    category: EntryIconCategory.life,
    keywords: ['sports', 'soccer', 'football', 'basketball', 'team'],
  ),
  EntryIcon(
    key: 'life_hiking',
    label: 'Hiking / Trekking',
    icon: Icons.hiking_rounded,
    category: EntryIconCategory.life,
    keywords: ['hiking', 'trek', 'trail', 'outdoors', 'camping'],
  ),
  EntryIcon(
    key: 'life_museum',
    label: 'Museum / Culture',
    icon: Icons.museum_rounded,
    category: EntryIconCategory.life,
    keywords: ['museum', 'culture', 'art', 'gallery', 'history'],
  ),
  EntryIcon(
    key: 'life_attractions',
    label: 'Attractions / Tickets',
    icon: Icons.attractions_rounded,
    category: EntryIconCategory.life,
    keywords: ['attraction', 'tickets', 'theme park', 'ferris', 'fun'],
  ),
  EntryIcon(
    key: 'life_nightlife',
    label: 'Nightlife / Bar',
    icon: Icons.nightlife_rounded,
    category: EntryIconCategory.life,
    keywords: ['nightlife', 'bar', 'club', 'cocktail', 'drinks'],
  ),
];

/// Map of icon key to [EntryIcon] for fast lookups.
final Map<String, EntryIcon> kEntryIconMap = {
  for (final item in kEntryIconCatalog) item.key: item,
};

/// Resolves an icon key (slug) to an [IconData].
///
/// Falls back to the default glyph for [kind] when the key is null or unknown.
IconData resolveEntryIcon(
  String? key, [
  VaultEntryKind kind = VaultEntryKind.login,
]) {
  if (key != null && kEntryIconMap.containsKey(key)) {
    return kEntryIconMap[key]!.icon;
  }
  return switch (kind) {
    VaultEntryKind.login => Icons.key_rounded,
    VaultEntryKind.card => Icons.credit_card_rounded,
    VaultEntryKind.note => Icons.sticky_note_2_rounded,
    VaultEntryKind.passkey => Icons.vpn_key_rounded,
  };
}

/// Automatically suggests an icon key based on entry title or website domain.
String? suggestEntryIcon(String? title, String? url) {
  final candidates = [
    if (title != null && title.isNotEmpty) title.toLowerCase(),
    if (url != null && url.isNotEmpty) url.toLowerCase(),
  ];

  for (final text in candidates) {
    // 1. Direct label match (e.g. "netflix", "github", "google")
    for (final icon in kEntryIconCatalog) {
      final label = icon.label.toLowerCase();
      final parts = label.split('/').map((s) => s.trim());
      for (final part in parts) {
        if (part.length > 2 && text.contains(part)) {
          return icon.key;
        }
      }
    }

    // 2. Keyword match (require word boundary for short keywords <= 3 chars)
    for (final icon in kEntryIconCatalog) {
      for (final kw in icon.keywords) {
        final k = kw.toLowerCase();
        if (k.length <= 3) {
          final words = text.split(RegExp(r'[\s\-_./@:]+'));
          if (words.contains(k)) {
            return icon.key;
          }
        } else if (text.contains(k)) {
          return icon.key;
        }
      }
    }
  }
  return null;
}
