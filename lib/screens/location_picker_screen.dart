import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _ctrl = TextEditingController();
  String _selected = '';

  // Common locations for demo + custom search
  final List<String> _suggestions = [
    'Ilerna Online, Lleida',
    'Barcelona, Spain',
    'Madrid, Spain',
    'Valencia, Spain',
    'Sevilla, Spain',
    'Zaragoza, Spain',
    'Bilbao, Spain',
    'Malaga, Spain',
    'Lleida, Spain',
    'Girona, Spain',
    'Tarragona, Spain',
    'Palma de Mallorca, Spain',
    'Las Palmas, Spain',
    'Alicante, Spain',
    'San Sebastian, Spain',
    'Salamanca, Spain',
    'Granada, Spain',
    'Cordoba, Spain',
    'Valladolid, Spain',
    'Murcia, Spain',
  ];

  List<String> get _filtered {
    if (_ctrl.text.isEmpty) return _suggestions;
    return _suggestions
        .where((s) => s.toLowerCase().contains(_ctrl.text.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicacion', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar ubicacion...',
                prefixIcon: Icon(Icons.search, color: brand),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  Navigator.pop(context, v.trim());
                }
              },
            ),
          ),
          // Custom location option
          if (_ctrl.text.isNotEmpty && !_suggestions.any((s) => s.toLowerCase() == _ctrl.text.toLowerCase()))
            ListTile(
              leading: Icon(Icons.add_location, color: brand),
              title: Text('Usar "${_ctrl.text}"', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context, _ctrl.text.trim()),
            ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final loc = _filtered[i];
                return ListTile(
                  leading: Icon(Icons.location_on, color: brand),
                  title: Text(loc),
                  selected: _selected == loc,
                  onTap: () => Navigator.pop(context, loc),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
