import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../data/turkish_cities.dart';
import '../utils/extensions.dart';

class LocationSelectorDialog extends StatefulWidget {
  const LocationSelectorDialog({super.key});

  @override
  State<LocationSelectorDialog> createState() => _LocationSelectorDialogState();
}

class _LocationSelectorDialogState extends State<LocationSelectorDialog> {
  String? _selectedCity;
  String? _selectedDistrict;

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
                const Text(
                  'Konum Seçin',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            const Text(
              'Hizmetlerin (Eczane, Hava Durumu) doğru çalışması için lütfen İl ve İlçe seçiniz.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // City Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: InputDecoration(
                labelText: 'İl / Şehir',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_city),
              ),
              items: TurkishCities.getCities().map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                  _selectedDistrict = null; // Reset district
                });
              },
            ),
            const SizedBox(height: 16),

            // District Dropdown
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: InputDecoration(
                labelText: 'İlçe',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: (_selectedCity != null && _selectedDistrict != null)
                  ? _saveLocation
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Kaydet ve Devam Et'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLocation() async {
    if (_selectedCity == null || _selectedDistrict == null) return;

    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    
    // Format: "District, City" for API search if needed, but we pass them explicitly
    final fullLocation = "$_selectedDistrict, $_selectedCity";
    
    // We pass explicit state/district to provider so it can store them for the Pharmacy service
    await weatherProvider.setLocation(
      fullLocation,
      language: 'tr',
      displayLabel: "$_selectedDistrict, $_selectedCity",
      state: _selectedCity,
      district: _selectedDistrict
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
