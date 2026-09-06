import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/market_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _subDistrictController = TextEditingController();
  final _villageController = TextEditingController();
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _subDistricts = [];
  List<Map<String, dynamic>> _villages = [];
  String? _selectedState;
  String? _selectedDistrictId;
  String? _selectedSubDistrictId;
  String? _selectedVillageId;
  bool _loadingLocations = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _subDistrictController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final districts = await context.read<MarketService>().fetchDistricts();
    if (!mounted) return;
    setState(() {
      _districts = districts;
      _loadingLocations = false;
    });
  }

  Future<void> _selectState(String? state) async {
    setState(() {
      _selectedState = state;
      _selectedDistrictId = null;
      _selectedSubDistrictId = null;
      _selectedVillageId = null;
      _subDistricts = [];
      _villages = [];
      _stateController.text = state ?? '';
      _districtController.clear();
      _subDistrictController.clear();
      _villageController.clear();
    });
  }

  Future<void> _selectDistrict(String? districtId) async {
    if (districtId == null) return;
    final district = _districts.firstWhere(
      (item) => item['id']?.toString() == districtId,
      orElse: () => <String, dynamic>{},
    );
    setState(() {
      _selectedDistrictId = districtId;
      _selectedSubDistrictId = null;
      _subDistricts = [];
      _villages = [];
      _districtController.text = district['district_name']?.toString() ?? '';
      _subDistrictController.clear();
      _villageController.clear();
    });
    final subDistricts =
        await context.read<MarketService>().fetchSubDistricts(districtId);
    if (!mounted) return;
    setState(() => _subDistricts = subDistricts);
  }

  Future<void> _selectSubDistrict(String? subDistrictId) async {
    if (subDistrictId == null) return;
    final subDistrict = _subDistricts.firstWhere(
      (item) => item['id']?.toString() == subDistrictId,
      orElse: () => <String, dynamic>{},
    );
    setState(() {
      _selectedSubDistrictId = subDistrictId;
      _villages = [];
      _subDistrictController.text =
          subDistrict['sub_district_name']?.toString() ?? '';
      _villageController.clear();
    });
    final villages =
        await context.read<MarketService>().fetchVillages(subDistrictId);
    if (!mounted) return;
    setState(() => _villages = villages);
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<AuthProvider>(context, listen: false);
      final success = await provider.register({
        'phone_number': _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'password': _passwordController.text,
        'full_name': _fullNameController.text.trim(),
        'state': _stateController.text.trim(),
        'district': _districtController.text.trim(),
        'sub_district': _subDistrictController.text.trim(),
        'village': _villageController.text.trim(),
      });

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful. Please log in to continue.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      } else if (provider.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Registration failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                AppTextField(
                  controller: _fullNameController,
                  labelText: 'Full Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().length < 10
                      ? 'Enter a valid phone number'
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  labelText: 'Email (optional)',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'State'),
                  items: _states
                      .map((state) => DropdownMenuItem(
                            value: state,
                            child: Text(state),
                          ))
                      .toList(),
                  onChanged: _loadingLocations ? null : _selectState,
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDistrictId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'District'),
                  items: _districts
                      .where((item) =>
                          item['state_name']?.toString() == _selectedState)
                      .map((item) => DropdownMenuItem(
                            value: item['id']?.toString(),
                            child: Text(item['district_name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: _selectedState == null ? null : _selectDistrict,
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubDistrictId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Mandal / Sub-district'),
                  items: _subDistricts
                      .map((item) => DropdownMenuItem(
                            value: item['id']?.toString(),
                            child: Text(item['sub_district_name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: _selectedDistrictId == null ? null : _selectSubDistrict,
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedVillageId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Village'),
                  items: _villages
                      .map((item) => DropdownMenuItem(
                            value: item['id']?.toString(),
                            child: Text(item['village_name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: _selectedSubDistrictId == null
                      ? null
                      : (id) {
                          final village = _villages.firstWhere(
                            (item) => item['id']?.toString() == id,
                            orElse: () => <String, dynamic>{},
                          );
                          setState(() {
                            _selectedVillageId = id;
                            _villageController.text =
                                village['village_name']?.toString() ?? '';
                          });
                        },
                  validator: (value) =>
                      _villageController.text.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Register',
                  isLoading: isLoading,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
