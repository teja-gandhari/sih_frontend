import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/app_state_provider.dart';
import '../../services/market_service.dart';
import '../../widgets/app_button.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  static const _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar',
    'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh',
    'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra',
    'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  ];
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _subDistricts = [];
  List<Map<String, dynamic>> _villages = [];

  bool _isLoadingDistricts = true;
  bool _isLoadingSubDistricts = false;
  bool _isLoadingVillages = false;

  String? _selectedDistrictId;
  String? _selectedSubDistrictId;
  String? _selectedVillageId;

  String? _selectedDistrictName;
  String? _selectedSubDistrictName;
  String? _selectedVillageName;
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    final service = context.read<MarketService>();
    final districts = await service.fetchDistricts();
    if (!mounted) return;

    final appState = context.read<AppStateProvider>();
    _selectedState = appState.state;
    final savedDistrict = appState.district;
    String? matchedDistrictId;
    if (savedDistrict != null && savedDistrict.isNotEmpty) {
      final match = districts.firstWhere(
        (item) =>
            (item['district_name'] as String? ?? '').toLowerCase() ==
            savedDistrict.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        matchedDistrictId = match['id']?.toString();
      }
    }

    setState(() {
      _districts = districts;
      _selectedState ??= districts.isNotEmpty
          ? districts.first['state_name']?.toString()
          : null;
      _selectedDistrictId = matchedDistrictId ?? _selectedDistrictId;
      _selectedDistrictName = matchedDistrictId == null
          ? _selectedDistrictName
          : districts
                .firstWhere(
                  (item) => item['id']?.toString() == matchedDistrictId,
                  orElse: () => <String, dynamic>{},
                )['district_name']
                ?.toString();
      _isLoadingDistricts = false;
    });

    if (matchedDistrictId != null) {
      await _loadSubDistricts(matchedDistrictId);
    }
  }

  Future<void> _loadSubDistricts(String districtId) async {
    setState(() {
      _isLoadingSubDistricts = true;
      _villages = [];
      _selectedSubDistrictId = null;
      _selectedVillageId = null;
      _selectedSubDistrictName = null;
      _selectedVillageName = null;
    });

    final service = context.read<MarketService>();
    final subDistricts = await service.fetchSubDistricts(districtId);
    if (!mounted) return;

    final appState = context.read<AppStateProvider>();
    String? matchedSubDistrictId;
    if (appState.block != null && appState.block!.isNotEmpty) {
      final match = subDistricts.firstWhere(
        (item) =>
            (item['sub_district_name'] as String? ?? '').toLowerCase() ==
            appState.block!.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        matchedSubDistrictId = match['id']?.toString();
      }
    }

    setState(() {
      _subDistricts = subDistricts;
      _selectedSubDistrictId = matchedSubDistrictId ?? _selectedSubDistrictId;
      _selectedSubDistrictName = matchedSubDistrictId == null
          ? _selectedSubDistrictName
          : subDistricts
                .firstWhere(
                  (item) => item['id']?.toString() == matchedSubDistrictId,
                  orElse: () => <String, dynamic>{},
                )['sub_district_name']
                ?.toString();
      _isLoadingSubDistricts = false;
    });

    if (matchedSubDistrictId != null) {
      await _loadVillages(matchedSubDistrictId);
    }
  }

  Future<void> _loadVillages(String subDistrictId) async {
    setState(() {
      _isLoadingVillages = true;
      _selectedVillageId = null;
      _selectedVillageName = null;
    });

    final service = context.read<MarketService>();
    final villages = await service.fetchVillages(subDistrictId);
    if (!mounted) return;

    final appState = context.read<AppStateProvider>();
    String? matchedVillageId;
    if (appState.village != null && appState.village!.isNotEmpty) {
      final match = villages.firstWhere(
        (item) =>
            (item['village_name'] as String? ?? '').toLowerCase() ==
            appState.village!.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        matchedVillageId = match['id']?.toString();
      }
    }

    setState(() {
      _villages = villages;
      _selectedVillageId = matchedVillageId ?? _selectedVillageId;
      _selectedVillageName = matchedVillageId == null
          ? _selectedVillageName
          : villages
                .firstWhere(
                  (item) => item['id']?.toString() == matchedVillageId,
                  orElse: () => <String, dynamic>{},
                )['village_name']
                ?.toString();
      _isLoadingVillages = false;
    });
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) labelBuilder,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    // ignore: deprecated_member_use
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item['id'] as T,
              child: Text(labelBuilder(item)),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: (val) => val == null ? AppLocalizations.of(context).get('required') : null,
    );
  }

  Future<void> _continue() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDistrictName == null ||
          _selectedSubDistrictName == null ||
          _selectedVillageName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).get('please_choose_valid_location'))),
        );
        return;
      }

      context.read<AppStateProvider>().setLocation(
        _selectedVillageName!,
        _selectedSubDistrictName!,
        _selectedDistrictName!,
        districtId: _selectedDistrictId,
        subDistrictId: _selectedSubDistrictId,
        villageId: _selectedVillageId,
        state: _selectedState,
      );
      Navigator.of(context).pushNamed(AppRouter.marginCapital);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.get('location_title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildStateDropdown(),
                const SizedBox(height: 16),
                if (_isLoadingDistricts)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildDropdown<String>(
                    label: loc.get('district'),
                    value: _selectedDistrictId,
                    items: _districts
                        .where((item) =>
                            item['state_name']?.toString() == _selectedState)
                        .toList(),
                    labelBuilder: (item) =>
                        (item['district_name'] as String?) ?? '',
                    onChanged: (value) async {
                      setState(() {
                        _selectedDistrictId = value;
                        _selectedDistrictName = _districts
                            .firstWhere(
                              (item) => item['id']?.toString() == value,
                              orElse: () => <String, dynamic>{},
                            )['district_name']
                            ?.toString();
                      });
                      if (value != null) {
                        await _loadSubDistricts(value);
                      }

                    },
                  ),
                const SizedBox(height: 16),
                if (_isLoadingSubDistricts)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildDropdown<String>(
                    label: loc.get('block_mandal'),
                    value: _selectedSubDistrictId,
                    items: _subDistricts,
                    labelBuilder: (item) =>
                        (item['sub_district_name'] as String?) ?? '',
                    onChanged: (value) async {
                      setState(() {
                        _selectedSubDistrictId = value;
                        _selectedSubDistrictName = _subDistricts
                            .firstWhere(
                              (item) => item['id']?.toString() == value,
                              orElse: () => <String, dynamic>{},
                            )['sub_district_name']
                            ?.toString();
                      });
                      if (value != null) {
                        await _loadVillages(value);
                      }
                    },
                  ),
                const SizedBox(height: 16),
                if (_isLoadingVillages)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildDropdown<String>(
                    label: loc.get('village'),
                    value: _selectedVillageId,
                    items: _villages,
                    labelBuilder: (item) =>
                        (item['village_name'] as String?) ?? '',
                    onChanged: (value) {
                      setState(() {
                        _selectedVillageId = value;
                        _selectedVillageName = _villages
                            .firstWhere(
                              (item) => item['id']?.toString() == value,
                              orElse: () => <String, dynamic>{},
                            )['village_name']
                            ?.toString();
                      });
                    },
                  ),
                const Spacer(),
                AppButton(text: loc.get('next'), onPressed: _continue),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedState,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'State',
        border: OutlineInputBorder(),
      ),
      items: _states
          .map((state) => DropdownMenuItem(value: state, child: Text(state)))
          .toList(),
      onChanged: (state) {
        setState(() {
          _selectedState = state;
          _selectedDistrictId = null;
          _selectedDistrictName = null;
          _subDistricts = [];
          _villages = [];
          _selectedSubDistrictId = null;
          _selectedVillageId = null;
          _selectedSubDistrictName = null;
          _selectedVillageName = null;
        });
      },
      validator: (value) => value == null ? 'Required' : null,
    );
  }
}
