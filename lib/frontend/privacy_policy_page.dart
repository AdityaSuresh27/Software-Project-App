/// PrivacyPolicyPage - Privacy & Security Policy
///
/// Displays ClassFlow's Privacy Policy and Security Policy to users.
/// Based on ClassFlow System Documentation — March 9, 2026.
///
/// Covers data collection, usage, third-party services, data retention,
/// user rights, and comprehensive security measures.
///
/// Accessed from ProfilePage settings for user reference and compliance.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lastUpdated = DateFormat('MMMM d, y').format(DateTime(2026, 3, 9));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.privacy_tip_rounded,
                color: AppTheme.primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Privacy & Security Policy',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlue.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Last Updated: $lastUpdated',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your Privacy & Security Matter',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ClassFlow is committed to protecting your privacy and securing your personal data. This document explains how we collect, use, and protect your information.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // -- PART 1: PRIVACY POLICY ------------------------------
                _buildPartDivider(context, 'Part 1', 'Privacy Policy',
                    Icons.shield_rounded, AppTheme.primaryBlue),
                const SizedBox(height: 20),

                // 1. Overview
                _buildSection(
                  context,
                  '1',
                  'Overview',
                  'ClassFlow is committed to protecting the privacy and personal data of its users. ClassFlow is designed to assist students in organising academic tasks, generating intelligent study schedules, and improving productivity — while ensuring responsible data handling.',
                  Icons.info_outline_rounded,
                  AppTheme.primaryBlue,
                ),

                // 2. Information We Collect
                _buildInfoCollectionSection(context),

                // 3. How We Use Your Information
                _buildBulletSection(
                  context,
                  '3',
                  'How We Use Your Information',
                  'Collected data is used solely to support the core functionality of ClassFlow.',
                  Icons.data_usage_rounded,
                  AppTheme.meetingTeal,
                  [
                    ('Generate intelligent academic schedules', Icons.calendar_month_rounded),
                    ('Detect event conflicts', Icons.warning_amber_rounded),
                    ('Provide AI-based study recommendations', Icons.auto_stories_rounded),
                    ('Improve platform performance and usability', Icons.trending_up_rounded),
                  ],
                ),

                // 4. Third-Party Services
                _buildThirdPartySection(context),

                // 5. Data Retention
                _buildSection(
                  context,
                  '5',
                  'Data Retention',
                  'User data is retained only while the account remains active. When you delete your account, all associated academic data, schedules, and analytics are permanently removed from the database. We do not retain your data after account deletion.',
                  Icons.delete_sweep_rounded,
                  AppTheme.examOrange,
                ),

                // 6. User Rights
                _buildBulletSection(
                  context,
                  '6',
                  'Your Rights',
                  'You have the following rights regarding your personal data stored in ClassFlow:',
                  Icons.verified_user_rounded,
                  AppTheme.accentPurple,
                  [
                    ('Access your stored data at any time', Icons.visibility_rounded),
                    ('Update or modify your personal information', Icons.edit_rounded),
                    ('Request deletion of your account and all associated data', Icons.delete_forever_rounded),
                  ],
                ),

                const SizedBox(height: 12),

                // -- PART 2: SECURITY POLICY -----------------------------
                _buildPartDivider(context, 'Part 2', 'Security Policy',
                    Icons.lock_rounded, AppTheme.successGreen),
                const SizedBox(height: 20),

                // 7. Security Overview
                _buildSection(
                  context,
                  '7',
                  'Security Overview',
                  'ClassFlow implements multiple layers of security to protect the confidentiality, integrity, and availability of user data. Our approach spans data transmission, storage, authentication, and application-level protections.',
                  Icons.security_rounded,
                  AppTheme.successGreen,
                  isImportant: true,
                ),

                // 8. Data Transmission & Storage Security
                _buildStorageSecuritySection(context),

                // 9. Authentication & Authorization
                _buildBulletSection(
                  context,
                  '9',
                  'Authentication & Authorization',
                  'ClassFlow uses JSON Web Tokens (JWT) for secure session management.',
                  Icons.key_rounded,
                  AppTheme.primaryBlue,
                  [
                    ('A signed token is generated after successful login', Icons.login_rounded),
                    ('The token must be included in all future API requests', Icons.token_rounded),
                    ('Protected routes ensure users can only access their own data', Icons.lock_person_rounded),
                  ],
                ),

                // 10. Application Security
                _buildBulletSection(
                  context,
                  '10',
                  'Application Security',
                  'The backend uses security middleware to strengthen protection across all requests.',
                  Icons.shield_rounded,
                  AppTheme.meetingTeal,
                  [
                    ('Helmet middleware to configure secure HTTP headers', Icons.http_rounded),
                    ('CORS configuration to prevent unauthorised domain requests', Icons.block_rounded),
                    ('Input validation to prevent malicious or malformed requests', Icons.check_circle_outline_rounded),
                  ],
                ),

                // 11. AI Integration Security
                _buildAISection(context),

                // 12. Logging & Monitoring
                _buildBulletSection(
                  context,
                  '12',
                  'Logging & Monitoring',
                  'The system maintains operational logs to monitor activity and detect potential security threats. These logs may include:',
                  Icons.monitor_heart_rounded,
                  AppTheme.warningAmber,
                  [
                    ('Authentication attempts', Icons.login_rounded),
                    ('API request timestamps', Icons.access_time_rounded),
                    ('System error reports', Icons.error_outline_rounded),
                    ('Suspicious access activity', Icons.gpp_bad_rounded),
                  ],
                ),

                // 13. Future Security Enhancements
                _buildBulletSection(
                  context,
                  '13',
                  'Future Security Enhancements',
                  'We are continuously improving security. Planned future enhancements include:',
                  Icons.rocket_launch_rounded,
                  AppTheme.accentPurple,
                  [
                    ('Multi-factor authentication (MFA)', Icons.phonelink_lock_rounded),
                    ('Role-based access control (RBAC)', Icons.manage_accounts_rounded),
                    ('Advanced anomaly detection', Icons.radar_rounded),
                    ('Encryption of sensitive database fields', Icons.enhanced_encryption_rounded),
                  ],
                ),

                const SizedBox(height: 40),

                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppTheme.successGreen,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We\'re Committed to Your Privacy & Security',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your trust is important to us. We continuously work to ensure your data is safe, secure, and handled responsibly.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.5,
                              fontSize: 15,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -- Part divider banner --------------------------------------------------
  Widget _buildPartDivider(BuildContext context, String part, String title,
      IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.75)],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                part,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ),
      ],
    );
  }

  // -- Generic section card ------------------------------------------------
  Widget _buildSection(
    BuildContext context,
    String number,
    String title,
    String? content,
    IconData icon,
    Color color, {
    bool isImportant = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isImportant ? 0.3 : 0.15),
          width: isImportant ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section $number',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (content != null) ...[
            const SizedBox(height: 16),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    fontSize: 16,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  // -- Section with bullet list ---------------------------------------------
  Widget _buildBulletSection(
    BuildContext context,
    String number,
    String title,
    String intro,
    IconData icon,
    Color color,
    List<(String, IconData)> bullets,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section $number',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            intro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 14),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(b.$2, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        b.$1,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              fontSize: 15.5,
                            ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // -- Information We Collect -----------------------------------------------
  Widget _buildInfoCollectionSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.assignmentPurple.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.assignmentPurple.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.assignmentPurple,
                      AppTheme.assignmentPurple.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section 2',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.assignmentPurple,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Information We Collect',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoCategory(
            context,
            'Account Information',
            'Name, email address, securely hashed password, optional Aadhaar number for OTP authentication, and account creation timestamp. Passwords are never stored in plain text.',
            Icons.person_rounded,
            ['Name & email address', 'Password (hashed — never plain text)', 'Optional Aadhaar number (OTP authentication)', 'Account creation timestamp'],
          ),
          const SizedBox(height: 14),
          _buildInfoCategory(
            context,
            'Academic Planning Data',
            'Everything you create inside ClassFlow to organise your studies.',
            Icons.school_rounded,
            ['Event titles and descriptions', 'Event categories (classes, exams, assignments, meetings)', 'Start and end times', 'Priority levels and deadlines', 'Task completion status'],
          ),
          const SizedBox(height: 14),
          _buildInfoCategory(
            context,
            'User Preferences',
            'Optional personalisation settings to tailor scheduling to your lifestyle.',
            Icons.tune_rounded,
            ['Sleep schedule', 'Preferred study durations', 'Preferred break intervals'],
          ),
          const SizedBox(height: 14),
          _buildInfoCategory(
            context,
            'Behavioural Analytics',
            'Automatically generated productivity insights to help you study smarter.',
            Icons.insights_rounded,
            ['Task completion rates', 'Missed deadlines', 'Delayed task starts', 'Estimated procrastination indicators', 'Burnout risk indicators'],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCategory(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    List<String> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.assignmentPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.assignmentPurple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontSize: 14.5,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.assignmentPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              fontSize: 15,
                            ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // -- Third-Party Services -------------------------------------------------
  Widget _buildThirdPartySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.examOrange.withValues(alpha: 0.06),
            AppTheme.warningAmber.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.examOrange.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.examOrange, AppTheme.warningAmber],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section 4',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.examOrange,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Third-Party Services',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'ClassFlow integrates with the following trusted services:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildServiceTile(
            context,
            Icons.auto_awesome_rounded,
            'Google Gemini API',
            'Used for AI-based study plan generation. Only minimal task-related metadata is sent — personal identifiers are never shared.',
            AppTheme.examOrange,
          ),
          const SizedBox(height: 10),
          _buildServiceTile(
            context,
            Icons.storage_rounded,
            'MongoDB',
            'Used for secure data storage of all user and academic data.',
            AppTheme.meetingTeal,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.successGreen.withValues(alpha: 0.15) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successGreen.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_rounded, color: AppTheme.successGreen, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No personally identifiable information — such as names, emails, passwords, or Aadhaar numbers — is ever shared with external AI services.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(BuildContext context, IconData icon, String name,
      String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontSize: 14.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Data Transmission & Storage Security ---------------------------------
  Widget _buildStorageSecuritySection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.successGreen, AppTheme.secondaryTeal],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section 8',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.successGreen,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Data Transmission & Storage Security',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSecurityTile(
            context,
            Icons.https_rounded,
            'HTTPS / TLS Encryption',
            'All communication between the app and backend occurs over secure HTTPS connections using TLS encryption, protecting data from interception during transmission.',
            AppTheme.successGreen,
          ),
          const SizedBox(height: 10),
          _buildSecurityTile(
            context,
            Icons.password_rounded,
            'Password Protection',
            'Passwords are never stored in plain text. They are hashed using bcrypt with salting before being saved in the database.',
            AppTheme.primaryBlue,
          ),
          const SizedBox(height: 10),
          _buildSecurityTile(
            context,
            Icons.key_off_rounded,
            'Environment Variables',
            'Sensitive configuration data such as database connection strings, API keys, and authentication secrets are stored in environment variables and excluded from version control via .gitignore.',
            AppTheme.accentPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTile(BuildContext context, IconData icon, String title,
      String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontSize: 14.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- AI Integration Security ----------------------------------------------
  Widget _buildAISection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.examOrange.withValues(alpha: 0.06),
            AppTheme.warningAmber.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.examOrange.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.examOrange, AppTheme.warningAmber],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section 11',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.examOrange,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI Integration Security',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.warningAmber.withValues(alpha: 0.15)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warningAmber.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.warningAmber, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'What Gets Sent to the AI',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: isDark
                                ? AppTheme.warningAmber.withValues(alpha: 0.9)
                                : AppTheme.warningAmber,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Only minimal task-related metadata — such as task titles, durations, and deadlines — is transmitted to Google Gemini. Personal identifiers such as your name, email, or Aadhaar number are never shared with the AI.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        fontSize: 15.5,
                        color: isDark ? Theme.of(context).textTheme.bodyMedium?.color : null,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

