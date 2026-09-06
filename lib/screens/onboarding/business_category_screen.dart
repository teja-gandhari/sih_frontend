import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/onboarding_models.dart';
import '../../providers/app_state_provider.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/app_button.dart';

class BusinessCategoryScreen extends StatefulWidget {
  const BusinessCategoryScreen({super.key});

  @override
  State<BusinessCategoryScreen> createState() => _BusinessCategoryScreenState();
}

class _BusinessCategoryScreenState extends State<BusinessCategoryScreen> {
  List<BusinessCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final service = context.read<OnboardingService>();
    final cats = await service.fetchCategories();
    setState(() {
      _categories = cats;
      _isLoading = false;
    });
  }

  void _goToReview() {
    if (!mounted) return;
    Navigator.of(context).pushNamed(AppRouter.review);
  }

  Future<void> _selectCategory(BusinessCategory category) async {
    final templates = await context.read<OnboardingService>().fetchTemplates(
      category.code,
    );
    if (!mounted) return;
    if (templates.isEmpty) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('no_business_types_available')),
        ),
      );
      return;
    }
    final loc = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(loc.get('choose_business_type'))),
            ...templates.map(
              (template) => ListTile(
                title: Text(template.name),
                onTap: () async {
                  if (template.code.endsWith('_other')) {
                    // Ask user to type their plan
                    String customPlan = '';
                    await showDialog(
                      context: sheetContext,
                      builder: (dialogCtx) => AlertDialog(
                        title: Text(loc.get('describe_custom_plan')),
                        content: TextField(
                          maxLines: 3,
                          onChanged: (val) => customPlan = val,
                          decoration: InputDecoration(
                            hintText: loc.get('custom_plan_hint'),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: Text(loc.get('cancel')),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<AppStateProvider>()
                                ..setBusinessCategory(category)
                                ..setBusinessTemplate(
                                  template,
                                  customPlan: customPlan,
                                );
                              Navigator.of(dialogCtx).pop();
                              Navigator.of(sheetContext).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _goToReview();
                              });
                            },
                            child: Text(loc.get('save')),
                          ),
                        ],
                      ),
                    );
                  } else {
                    context.read<AppStateProvider>()
                      ..setBusinessCategory(category)
                      ..setBusinessTemplate(template);
                    Navigator.of(sheetContext).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _goToReview();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.get('business_category_title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Expanded(
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected =
                          appState.businessCategory?.id == cat.id;
                      return Card(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withAlpha(26)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(cat.name),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          onTap: () => _selectCategory(cat),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: loc.get('next'),
                  onPressed: appState.businessTemplate == null
                      ? null
                      : _goToReview,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
