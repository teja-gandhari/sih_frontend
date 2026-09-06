import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/app_state_provider.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;
  final _scaleController = TextEditingController();
  final _landAreaController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _ownsLand = true;
  bool _isScaleUnknown = false;

  String _getScaleQuestion() {
    final templateName = (context.read<AppStateProvider>().businessTemplate?.name ?? '')
        .toLowerCase();
    final categoryName = (context.read<AppStateProvider>().businessCategory?.name ?? '')
        .toLowerCase();
    final combined = '$templateName $categoryName';

    if (combined.contains('digital') ||
        combined.contains('citizen') ||
        combined.contains('electronics') ||
        combined.contains('service') ||
        combined.contains('computer')) {
      return AppLocalizations.of(context).get('scale_question_custom');
    }
    if (combined.contains('dairy') ||
        combined.contains('animal') ||
        combined.contains('milk') ||
        combined.contains('buffalo')) {
      return AppLocalizations.of(context).get('scale_question_dairy');
    }
    if (combined.contains('tailor') ||
        combined.contains('garment') ||
        combined.contains('stitch') ||
        combined.contains('textile')) {
      return AppLocalizations.of(context).get('scale_question_tailoring');
    }
    if (combined.contains('kirana') ||
        combined.contains('retail') ||
        combined.contains('store') ||
        combined.contains('shop')) {
      return AppLocalizations.of(context).get('scale_question_retail');
    }
    if (combined.contains('food') ||
        combined.contains('processing') ||
        combined.contains('grinding') ||
        combined.contains('mill')) {
      return AppLocalizations.of(context).get('scale_question_food');
    }
    if (combined.contains('agric') ||
        combined.contains('farm') ||
        combined.contains('vermi') ||
        combined.contains('bio')) {
      return AppLocalizations.of(context).get('scale_question_agri');
    }
    return AppLocalizations.of(context).get('scale_question_default');
  }

  String _getScaleHelperText() {
    final templateName = (context.read<AppStateProvider>().businessTemplate?.name ?? '')
        .toLowerCase();
    final categoryName = (context.read<AppStateProvider>().businessCategory?.name ?? '')
        .toLowerCase();
    final combined = '$templateName $categoryName';

    if (combined.contains('digital') ||
        combined.contains('citizen') ||
        combined.contains('electronics') ||
        combined.contains('service') ||
        combined.contains('computer')) {
      return AppLocalizations.of(context).get('scale_helper_default');
    }
    if (combined.contains('dairy') ||
        combined.contains('animal') ||
        combined.contains('milk') ||
        combined.contains('buffalo')) {
      return 'Enter the approximate number of animals.';
    }
    if (combined.contains('tailor') ||
        combined.contains('garment') ||
        combined.contains('stitch') ||
        combined.contains('textile')) {
      return 'An approximate number is enough.';
    }
    if (combined.contains('kirana') ||
        combined.contains('retail') ||
        combined.contains('store') ||
        combined.contains('shop')) {
      return 'Enter an approximate amount.';
    }
    if (combined.contains('food') ||
        combined.contains('processing') ||
        combined.contains('grinding') ||
        combined.contains('mill')) {
      return 'Enter an approximate monthly output.';
    }
    if (combined.contains('agric') ||
        combined.contains('farm') ||
        combined.contains('vermi') ||
        combined.contains('bio')) {
      return 'Enter an approximate monthly scale.';
    }
    return AppLocalizations.of(context).get('scale_helper_default');
  }

  String? _getScaleSuffixText() {
    final templateName = (context.read<AppStateProvider>().businessTemplate?.name ?? '')
        .toLowerCase();
    final categoryName = (context.read<AppStateProvider>().businessCategory?.name ?? '')
        .toLowerCase();
    final combined = '$templateName $categoryName';

    if (combined.contains('digital') || combined.contains('citizen') || combined.contains('electronics')) {
      return AppLocalizations.of(context).get('scale_suffix_customers');
    }
    if (combined.contains('dairy') || combined.contains('animal') || combined.contains('milk')) {
      return AppLocalizations.of(context).get('scale_suffix_animals');
    }
    if (combined.contains('tailor') || combined.contains('garment') || combined.contains('stitch')) {
      return AppLocalizations.of(context).get('scale_suffix_clothes');
    }
    if (combined.contains('kirana') || combined.contains('retail') || combined.contains('store')) {
      return AppLocalizations.of(context).get('scale_suffix_stock');
    }
    if (combined.contains('food') || combined.contains('processing') || combined.contains('grinding')) {
      return AppLocalizations.of(context).get('scale_suffix_kg');
    }
    if (combined.contains('agric') || combined.contains('farm') || combined.contains('vermi')) {
      return AppLocalizations.of(context).get('scale_suffix_acres');
    }
    return null;
  }

  void _toggleScaleUnknown() {
    setState(() {
      _isScaleUnknown = !_isScaleUnknown;
      if (_isScaleUnknown) {
        _scaleController.clear();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _landAreaController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _createApplication() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isCreating = true);
    final appState = context.read<AppStateProvider>();
    final service = context.read<OnboardingService>();
    final loc = AppLocalizations.of(context);

    if (appState.businessTemplate == null) {
      _showMessage('Please select a business type before continuing.');
      setState(() => _isCreating = false);
      return;
    }
    if (appState.village == null ||
        appState.block == null ||
        appState.district == null ||
        appState.districtId == null ||
        appState.subDistrictId == null ||
        appState.villageId == null) {
      _showMessage('Please complete the location selection step first.');
      setState(() => _isCreating = false);
      return;
    }

    int? scale;
    if (_isScaleUnknown) {
      scale = appState.businessTemplate?.defaultScale ?? 1;
    } else {
      scale = int.tryParse(_scaleController.text.trim());
    }
    final landArea = double.tryParse(_landAreaController.text.trim());
    final experience = double.tryParse(_experienceController.text.trim());
    if ((scale == null || scale <= 0) ||
        landArea == null ||
        landArea < 0 ||
        experience == null ||
        experience < 0) {
      _showMessage('Enter valid business scale, land area, and experience.');
      setState(() => _isCreating = false);
      return;
    }

    try {
      appState.setScaleUnits(scale);
      await service.saveProfileLocation(
        village: appState.village!,
        subDistrict: appState.block!,
        district: appState.district!,
      );
      final payload = {
        'business_type_id': appState.businessTemplate!.id,
        'district_id': appState.districtId,
        'sub_district_id': appState.subDistrictId,
        'village_id': appState.villageId,
        'scale_units': scale,
        'user_margin_available': appState.marginCapital,
        'own_land_available': _ownsLand,
        'land_area_sqft': landArea,
        'prior_experience_years': experience,
      };
      if (appState.customBusinessPlan != null &&
          appState.customBusinessPlan!.isNotEmpty) {
        payload['custom_business_plan'] = appState.customBusinessPlan!;
      }

      final appId = await service.createApplication(payload);
      appState.setApplicationId(appId);
      appState.addApplicationSummary(
        applicationId: appId,
        businessName: appState.businessTemplate?.name ?? 'Business',
        location: '${appState.village ?? ''}, ${appState.block ?? ''}, ${appState.district ?? ''}'.replaceAll(RegExp(r',\s*,'), ',').trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('success_created').replaceAll('%s', appId)),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/financial');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('error_creating')),
          action: SnackBarAction(
            label: loc.get('retry'),
            onPressed: _createApplication,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final loc = AppLocalizations.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: Text(loc.get('review_title'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSection(
                  title: loc.get('location_title'),
                  content:
                      '${loc.get('village')}: ${appState.village ?? '-'}\n${loc.get('block_mandal')}: ${appState.block ?? '-'}\n${loc.get('district')}: ${appState.district ?? '-'}',
                  onEdit: () => Navigator.of(
                    context,
                  ).popUntil((r) => r.settings.name == AppRouter.location),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: loc.get('available_margin'),
                  content: currencyFormat.format(appState.marginCapital ?? 0),
                  onEdit: () => Navigator.of(
                    context,
                  ).popUntil((r) => r.settings.name == AppRouter.marginCapital),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: loc.get('business'),
                  content:
                      appState.customBusinessPlan != null &&
                              appState.customBusinessPlan!.isNotEmpty
                          ? '${appState.businessTemplate?.name ?? '-'}\nPlan: ${appState.customBusinessPlan}'
                          : appState.businessTemplate?.name ?? '-',
                  onEdit: () => Navigator.of(context).popUntil(
                    (r) => r.settings.name == AppRouter.businessCategory,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: loc.get('language'),
                  content: appState.selectedLanguage == 'en'
                      ? 'English'
                      : (appState.selectedLanguage == 'te' ? 'తెలుగు' : 'हिंदी'),
                  onEdit: () => Navigator.of(
                    context,
                  ).popUntil((r) => r.settings.name == AppRouter.language),
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _getScaleQuestion(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(loc.get('scale_info_title')),
                            content: Text(loc.get('scale_info_text')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      tooltip: loc.get('scale_info_title'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _scaleController,
                  enabled: !_isScaleUnknown,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_isScaleUnknown) return null;
                    if (value == null || value.trim().isEmpty) {
                      return loc.get('scale_validation_required');
                    }
                    final number = int.tryParse(value.trim());
                    if (number == null || number <= 0) {
                      return loc.get('scale_validation_invalid');
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: loc.get('scale_hint_example'),
                    helperText: _isScaleUnknown
                        ? loc.get('scale_unknown_message')
                        : _getScaleHelperText(),
                    suffixText: _isScaleUnknown ? null : _getScaleSuffixText(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _toggleScaleUnknown,
                  child: Text(
                    _isScaleUnknown
                        ? loc.get('cancel')
                        : loc.get('scale_unknown'),
                  ),
                ),
                if (_isScaleUnknown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      loc.get('scale_unknown_message'),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Do you own the land/premises?'),
                  value: _ownsLand,
                  onChanged: (value) {
                    setState(() {
                      _ownsLand = value;
                      if (!value) {
                        // The API requires a numeric area even for rented
                        // premises; zero represents no owned land.
                        _landAreaController.text = '0';
                      } else if (_landAreaController.text.trim() == '0') {
                        _landAreaController.clear();
                      }
                    });
                  },
                ),
                AppTextField(
                  controller: _landAreaController,
                  labelText: _ownsLand
                      ? 'Land or premises area (sq ft)'
                      : 'Land or premises area (sq ft, enter 0 if rented)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (!_ownsLand && (value == null || value.trim().isEmpty)) {
                      return null;
                    }
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final number = double.tryParse(value.trim());
                    if (number == null || number < 0) return 'Enter a valid area';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _experienceController,
                  labelText: 'Relevant experience (years)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final number = double.tryParse(value.trim());
                    if (number == null || number < 0) return 'Enter a valid value';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: _isCreating
                      ? loc.get('creating_application')
                      : loc.get('confirm_continue'),
                  isLoading: _isCreating,
                  onPressed: _isCreating ? null : _createApplication,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required VoidCallback onEdit,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: Text(AppLocalizations.of(context).get('edit')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
