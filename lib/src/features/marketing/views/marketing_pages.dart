import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/marketing_service.dart';

const _teamcloudLogoAsset = 'assets/marketing/teamcloud-logo.png';
const _teamcloudFeaturedAsset = 'assets/marketing/teamcloud-featured.png';
const _teamcloudHeaderAsset = 'assets/marketing/teamcloud-header.png';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PublicShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroSection(),
          _TrustStrip(),
          _FeatureBand(),
          _PricingPreview(),
          _FinalCta(),
        ],
      ),
    );
  }
}

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PublicShell(
      child: _PageBand(
        title: 'Pricing',
        subtitle:
            'Choose a plan that matches your retail operation today and scales with every branch you add.',
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _plans
              .map((plan) => _PlanCard(plan: plan, expanded: true))
              .toList(),
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PublicShell(
      child: _PageBand(
        title: 'About TeamCloud',
        subtitle:
            'TeamCloud is built for retailers who need accurate sales, stock, staff, and branch control without spreadsheet workarounds.',
        child: _AboutContent(),
      ),
    );
  }
}

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _marketingService = MarketingService();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await _marketingService.submitContact(
        name: _nameController.text,
        email: _emailController.text,
        message: _messageController.text,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks. The TeamCloud team will follow up.'),
        ),
      );
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    } catch (err) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(err))));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PublicShell(
      child: _PageBand(
        title: 'Contact',
        subtitle:
            'Talk to us about onboarding, pricing, migration, branch setup, or enterprise support.',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final form = _ContactForm(
              nameController: _nameController,
              emailController: _emailController,
              messageController: _messageController,
              onSubmit: _submit,
              submitting: _submitting,
            );
            final details = const _ContactDetails();

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [details, const SizedBox(height: 16), form],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details),
                const SizedBox(width: 24),
                Expanded(child: form),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PublicShell(
      child: _PageBand(
        title: 'Legal',
        subtitle:
            'Plain-language operating terms for using TeamCloud Retail POS and related services.',
        child: _LegalContent(),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, this.initialPlan});

  final String? initialPlan;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _marketingService = MarketingService();
  late String _selectedPlan;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final requestedPlan = widget.initialPlan;
    _selectedPlan = _plans.any((plan) => plan.name == requestedPlan)
        ? requestedPlan!
        : _plans[1].name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await _marketingService.submitSignup(
        plan: _selectedPlan,
        name: _nameController.text,
        businessName: _businessController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Signup request received for $_selectedPlan. We will send checkout details.',
          ),
        ),
      );
      _nameController.clear();
      _businessController.clear();
      _emailController.clear();
      _phoneController.clear();
    } catch (err) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(err))));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PublicShell(
      child: _PageBand(
        title: 'Start with TeamCloud',
        subtitle:
            'Select a plan and send your business details. We will provision your business account and payment checkout.',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final form = _SignupForm(
              selectedPlan: _selectedPlan,
              onPlanChanged: (value) => setState(() => _selectedPlan = value),
              nameController: _nameController,
              businessController: _businessController,
              emailController: _emailController,
              phoneController: _phoneController,
              onSubmit: _submit,
              submitting: _submitting,
            );
            final summary = _PlanSummary(
              plan: _plans.firstWhere((plan) => plan.name == _selectedPlan),
            );

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [summary, const SizedBox(height: 16), form],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: summary),
                const SizedBox(width: 24),
                Expanded(child: form),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PublicShell extends StatelessWidget {
  const _PublicShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _PublicNav()),
            SliverToBoxAdapter(child: child),
            const SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }
}

class _PublicNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 920;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Center(
          child: Row(
            children: [
              InkWell(
                onTap: () => context.go('/'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      _teamcloudLogoAsset,
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'TeamCloud',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!compact) ...[
                _NavLink(label: 'Pricing', path: '/pricing'),
                _NavLink(label: 'About', path: '/about'),
                _NavLink(label: 'Contact', path: '/contact'),
                _NavLink(label: 'Legal', path: '/legal'),
                const SizedBox(width: 16),
              ] else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu),
                  onSelected: context.go,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: '/pricing', child: Text('Pricing')),
                    PopupMenuItem(value: '/about', child: Text('About')),
                    PopupMenuItem(value: '/contact', child: Text('Contact')),
                    PopupMenuItem(value: '/legal', child: Text('Legal')),
                  ],
                ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Login'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => context.go('/signup'),
                child: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: () => context.go(path), child: Text(label));
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return _ConstrainedSection(
      padding: const EdgeInsets.fromLTRB(24, 54, 24, 48),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 940;
          final copy = Column(
            crossAxisAlignment: wide
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6D9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Retail POS, inventory, payments, and branches in one place',
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Run every store from one accurate retail cloud.',
                textAlign: wide ? TextAlign.start : TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.02,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'TeamCloud gives retailers a fast POS, live stock control, branch reporting, staff permissions, Nomba payments, and customer history without losing control of daily operations.',
                textAlign: wide ? TextAlign.start : TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: wide ? WrapAlignment.start : WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/pricing'),
                    icon: const Icon(Icons.payments),
                    label: const Text('See plans'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/signup'),
                    icon: const Icon(Icons.storefront),
                    label: const Text('Start signup'),
                  ),
                ],
              ),
            ],
          );

          const visual = _ProductVisual();
          if (!wide) {
            return Column(
              children: [
                copy,
                const SizedBox(height: 34),
                const SizedBox(height: 360, child: visual),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 40),
              const Expanded(child: SizedBox(height: 500, child: visual)),
            ],
          );
        },
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_teamcloudFeaturedAsset, fit: BoxFit.cover),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: (constraints.maxWidth - 36).clamp(220, 440),
                  ),
                  margin: const EdgeInsets.all(18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Color(0xFF0F52BA), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Smart POS and inventory in the cloud',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: _ConstrainedSection(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Wrap(
          spacing: 18,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: const [
            _TrustItem(icon: Icons.store, label: 'Multi-branch ready'),
            _TrustItem(icon: Icons.lock, label: 'Role-based access'),
            _TrustItem(icon: Icons.sync, label: 'Realtime stock'),
            _TrustItem(icon: Icons.receipt_long, label: 'Payment records'),
          ],
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0F52BA)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _FeatureBand extends StatelessWidget {
  const _FeatureBand();

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      title: 'Built for daily retail work',
      subtitle:
          'Every workflow is designed for repeated use by owners, branch managers, cashiers, inventory officers, and accountants.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FeatureImagePanel(),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _FeatureCard(
                icon: Icons.point_of_sale,
                title: 'Fast checkout',
                body:
                    'Search products, build carts, accept cash or Nomba payments, and finalize sales from one screen.',
              ),
              _FeatureCard(
                icon: Icons.inventory,
                title: 'Inventory control',
                body:
                    'Track product quantities by branch, catch low stock early, and keep sale totals tied to real product prices.',
              ),
              _FeatureCard(
                icon: Icons.groups,
                title: 'Staff permissions',
                body:
                    'Give each user the exact role they need across sales, stock, finance, branches, and platform admin work.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureImagePanel extends StatelessWidget {
  const _FeatureImagePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          final copy = Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: wide
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Inventory, sales, discounts, and reports stay connected.',
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Give your team a POS they can use quickly while owners keep clean records across every location.',
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          );
          final image = SizedBox(
            height: wide ? 320 : 300,
            width: double.infinity,
            child: Image.asset(
              _teamcloudHeaderAsset,
              fit: BoxFit.contain,
              alignment: wide ? Alignment.bottomRight : Alignment.center,
            ),
          );

          if (!wide) {
            return Column(children: [copy, image]);
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: copy),
              Expanded(flex: 4, child: image),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF0F52BA), size: 32),
              const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(body, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF1B5E20))),
    );
  }
}

class _PricingPreview extends StatelessWidget {
  const _PricingPreview();

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      title: 'Plans for every retail stage',
      subtitle:
          'Start with one store, add branches, then unlock deeper reporting and operations controls as you grow.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _plans.map((plan) => _PlanCard(plan: plan)).toList(),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () => context.go('/pricing'),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Compare all pricing'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, this.expanded = false});

  final _Plan plan;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expanded ? 360 : 340,
      child: Card(
        elevation: plan.highlight ? 3 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: plan.highlight
                ? const Color(0xFF0F52BA)
                : Colors.grey.shade200,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (plan.highlight) ...[
                    const Spacer(),
                    const _StatusPill(label: 'Popular'),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(plan.description),
              const SizedBox(height: 16),
              Text(
                plan.price,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              ...plan.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 19),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/signup?plan=${plan.name}'),
                  child: Text('Buy ${plan.name}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinalCta extends StatelessWidget {
  const _FinalCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1F44),
      child: _ConstrainedSection(
        padding: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 34),
          child: Column(
            children: [
              Text(
                'Ready to clean up sales, stock, and branch reporting?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/signup'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Start signup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: const [
        _FeatureCard(
          icon: Icons.flag,
          title: 'Our focus',
          body:
              'We help retailers replace disconnected spreadsheets, manual stock counts, and unclear end-of-day reports with one operating system.',
        ),
        _FeatureCard(
          icon: Icons.security,
          title: 'Our standard',
          body:
              'Business data separation, role-based access, server-side sale finalization, and auditable admin actions are core requirements.',
        ),
        _FeatureCard(
          icon: Icons.handshake,
          title: 'Our support',
          body:
              'We support onboarding, branch setup, staff permissions, payment configuration, and data migration planning.',
        ),
      ],
    );
  }
}

class _ContactDetails extends StatelessWidget {
  const _ContactDetails();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ContactLine(icon: Icons.email, label: 'support@teamcloudslt.com'),
            _ContactLine(
              icon: Icons.language,
              label: 'teamcloud retail support',
            ),
            _ContactLine(icon: Icons.schedule, label: 'Monday to Friday'),
          ],
        ),
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F52BA)),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _ContactForm extends StatelessWidget {
  const _ContactForm({
    required this.nameController,
    required this.emailController,
    required this.messageController,
    required this.onSubmit,
    required this.submitting,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController messageController;
  final Future<void> Function() onSubmit;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: submitting ? null : onSubmit,
                child: Text(submitting ? 'Sending...' : 'Send message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalContent extends StatelessWidget {
  const _LegalContent();

  @override
  Widget build(BuildContext context) {
    const sections = [
      (
        'Terms of use',
        'TeamCloud accounts are issued for legitimate business operations. Users are responsible for accurate staff access, product data, payment configuration, and compliance with local regulations.',
      ),
      (
        'Privacy',
        'TeamCloud stores business, staff, customer, inventory, and transaction data needed to operate the retail platform. Access is restricted by business account and role.',
      ),
      (
        'Payments',
        'Payment credentials are managed by Super Admin users. Live payment processing depends on provider approval, active credentials, and successful webhook configuration.',
      ),
      (
        'Service limits',
        'Plan limits, support response, onboarding scope, and billing terms are confirmed during signup and provisioning.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections
          .map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.$1,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(section.$2),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    required this.selectedPlan,
    required this.onPlanChanged,
    required this.nameController,
    required this.businessController,
    required this.emailController,
    required this.phoneController,
    required this.onSubmit,
    required this.submitting,
  });

  final String selectedPlan;
  final ValueChanged<String> onPlanChanged;
  final TextEditingController nameController;
  final TextEditingController businessController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final Future<void> Function() onSubmit;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedPlan,
              decoration: const InputDecoration(labelText: 'Plan'),
              items: _plans
                  .map(
                    (plan) => DropdownMenuItem(
                      value: plan.name,
                      child: Text('${plan.name} - ${plan.price}'),
                    ),
                  )
                  .toList(),
              onChanged: submitting
                  ? null
                  : (value) {
                      if (value != null) {
                        onPlanChanged(value);
                      }
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: businessController,
              decoration: const InputDecoration(labelText: 'Business name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Work email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: submitting ? null : onSubmit,
                icon: const Icon(Icons.shopping_cart_checkout),
                label: Text(submitting ? 'Submitting...' : 'Request checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final _Plan plan;

  @override
  Widget build(BuildContext context) {
    return _PlanCard(plan: plan, expanded: true);
  }
}

class _PageBand extends StatelessWidget {
  const _PageBand({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _ConstrainedSection(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }
}

class _ConstrainedSection extends StatelessWidget {
  const _ConstrainedSection({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text('TeamCloud Retail POS'),
              TextButton(
                onPressed: () => context.go('/pricing'),
                child: const Text('Pricing'),
              ),
              TextButton(
                onPressed: () => context.go('/about'),
                child: const Text('About'),
              ),
              TextButton(
                onPressed: () => context.go('/contact'),
                child: const Text('Contact'),
              ),
              TextButton(
                onPressed: () => context.go('/legal'),
                child: const Text('Legal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Plan {
  const _Plan({
    required this.name,
    required this.price,
    required this.description,
    required this.features,
    this.highlight = false,
  });

  final String name;
  final String price;
  final String description;
  final List<String> features;
  final bool highlight;
}

const _plans = [
  _Plan(
    name: 'Starter',
    price: '₦25k/mo',
    description: 'For one store getting sales and stock under control.',
    features: [
      '1 branch',
      'POS checkout',
      'Products and inventory',
      'Basic reports',
    ],
  ),
  _Plan(
    name: 'Growth',
    price: '₦65k/mo',
    description: 'For growing retailers with multiple staff and branches.',
    features: [
      'Up to 3 branches',
      'Nomba payment flow',
      'Staff roles',
      'Customer records',
      'Branch reporting',
    ],
    highlight: true,
  ),
  _Plan(
    name: 'Enterprise',
    price: 'Custom',
    description: 'For larger operations needing controls and onboarding.',
    features: [
      'Unlimited branch planning',
      'Advanced permissions',
      'Data migration support',
      'Priority onboarding',
    ],
  ),
];
