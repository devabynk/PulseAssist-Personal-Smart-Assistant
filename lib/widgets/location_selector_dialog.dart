import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/turkish_cities.dart';
import '../data/usa_states.dart';
import '../providers/weather_provider.dart';
import '../utils/extensions.dart';

class LocationSelectorDialog extends StatefulWidget {
  const LocationSelectorDialog({super.key});

  @override
  State<LocationSelectorDialog> createState() => _LocationSelectorDialogState();
}

class _LocationSelectorDialogState extends State<LocationSelectorDialog> {
  String _selectedCountry = 'TR'; // Default to Turkey
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedState; // For USA

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.selectLocation,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.selectLocationForWeather,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Country Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedCountry,
              decoration: InputDecoration(
                labelText: l10n.country,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.public),
              ),
              items: const [
                DropdownMenuItem(value: 'TR', child: Text('🇹🇷 Türkiye')),
                DropdownMenuItem(
                  value: 'US',
                  child: Text('🇺🇸 United States'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value!;
                  _selectedCity = null;
                  _selectedDistrict = null;
                  _selectedState = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Turkey Flow: City → District
            if (_selectedCountry == 'TR') ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: InputDecoration(
                  labelText: l10n.city,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_city),
                ),
                items: TurkishCities.getCities().map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                    _selectedDistrict = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDistrict,
                decoration: InputDecoration(
                  labelText: l10n.district,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.map),
                ),
                items: _selectedCity == null
                    ? []
                    : TurkishCities.getDistricts(_selectedCity!).map((dist) {
                        return DropdownMenuItem(value: dist, child: Text(dist));
                      }).toList(),
                onChanged: _selectedCity == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedDistrict = value;
                        });
                      },
              ),
            ],

            // USA Flow: State → City
            if (_selectedCountry == 'US') ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedState,
                decoration: InputDecoration(
                  labelText: l10n.state,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_city),
                ),
                items: USAStates.getStates().map((state) {
                  return DropdownMenuItem(value: state, child: Text(state));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                    _selectedCity = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: InputDecoration(
                  labelText:
                      Localizations.localeOf(context).languageCode == 'tr'
                      ? 'Şehir'
                      : 'City',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.map),
                ),
                items: _selectedState == null
                    ? []
                    : USAStates.getCities(_selectedState!).map((city) {
                        return DropdownMenuItem(value: city, child: Text(city));
                      }).toList(),
                onChanged: _selectedState == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCity = value;
                        });
                      },
              ),
            ],

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _canSave() ? _saveLocation : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.saveAndContinue),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSave() {
    if (_selectedCountry == 'TR') {
      return _selectedCity != null && _selectedDistrict != null;
    } else {
      return _selectedState != null && _selectedCity != null;
    }
  }

  Future<void> _saveLocation() async {
    final weatherProvider = Provider.of<WeatherProvider>(
      context,
      listen: false,
    );

    if (_selectedCountry == 'TR') {
      // Turkey flow
      if (_selectedCity == null || _selectedDistrict == null) return;

      final fullLocation = '$_selectedDistrict, $_selectedCity';

      await weatherProvider.fetchWeather(
        fullLocation,
        language: 'tr',
        displayLabel: '$_selectedDistrict, $_selectedCity',
        state: _selectedCity,
        district: _selectedDistrict,
        countryCode: 'TR',
      );
    } else {
      // USA flow
      if (_selectedState == null || _selectedCity == null) return;

      final fullLocation = '$_selectedCity, $_selectedState';

      await weatherProvider.fetchWeather(
        fullLocation,
        language: 'en',
        displayLabel: '$_selectedCity, $_selectedState',
        state: _selectedState,
        district: null,
        countryCode: 'US',
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
