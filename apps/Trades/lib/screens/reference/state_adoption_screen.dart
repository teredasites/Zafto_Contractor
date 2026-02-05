/// State NEC Adoption - Design System v2.6
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class StateAdoptionScreen extends ConsumerStatefulWidget {
  const StateAdoptionScreen({super.key});
  @override
  ConsumerState<StateAdoptionScreen> createState() => _StateAdoptionScreenState();
}

class _StateAdoptionScreenState extends ConsumerState<StateAdoptionScreen> {
  String _searchQuery = '';
  String _filterVersion = 'All';

  static const List<_StateData> _states = [
    _StateData(state: 'Alabama', code: 'AL', necVersion: '2023', notes: 'Statewide adoption'),
    _StateData(state: 'Alaska', code: 'AK', necVersion: '2020', notes: 'Statewide'),
    _StateData(state: 'Arizona', code: 'AZ', necVersion: '2020', notes: 'State minimum, local may vary'),
    _StateData(state: 'Arkansas', code: 'AR', necVersion: '2017', notes: 'Statewide'),
    _StateData(state: 'California', code: 'CA', necVersion: '2023', notes: 'Title 24 Part 3, with amendments'),
    _StateData(state: 'Colorado', code: 'CO', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'Connecticut', code: 'CT', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'Delaware', code: 'DE', necVersion: '2020', notes: 'Statewide'),
    _StateData(state: 'Florida', code: 'FL', necVersion: '2023', notes: 'Florida Building Code'),
    _StateData(state: 'Georgia', code: 'GA', necVersion: '2020', notes: 'Statewide minimum'),
    _StateData(state: 'Hawaii', code: 'HI', necVersion: '2020', notes: 'With state amendments'),
    _StateData(state: 'Idaho', code: 'ID', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'Illinois', code: 'IL', necVersion: '2020', notes: 'Local adoption varies'),
    _StateData(state: 'Indiana', code: 'IN', necVersion: '2020', notes: 'Statewide'),
    _StateData(state: 'Iowa', code: 'IA', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'Kansas', code: 'KS', necVersion: '2020', notes: 'Local adoption'),
    _StateData(state: 'Kentucky', code: 'KY', necVersion: '2020', notes: 'Statewide'),
    _StateData(state: 'Louisiana', code: 'LA', necVersion: '2020', notes: 'Statewide'),
    _StateData(state: 'Maine', code: 'ME', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'Maryland', code: 'MD', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'Massachusetts', code: 'MA', necVersion: '2023', notes: '527 CMR with amendments'),
    _StateData(state: 'Michigan', code: 'MI', necVersion: '2020', notes: 'Michigan Electrical Code'),
    _StateData(state: 'Minnesota', code: 'MN', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'Mississippi', code: 'MS', necVersion: '2020', notes: 'Local adoption'),
    _StateData(state: 'Missouri', code: 'MO', necVersion: '2018', notes: 'Local adoption varies'),
    _StateData(state: 'Montana', code: 'MT', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'Nebraska', code: 'NE', necVersion: '2020', notes: 'Statewide'),
    _StateData(state: 'Nevada', code: 'NV', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'New Hampshire', code: 'NH', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'New Jersey', code: 'NJ', necVersion: '2020', notes: 'Uniform Construction Code'),
    _StateData(state: 'New Mexico', code: 'NM', necVersion: '2020', notes: 'Statewide'),
    _StateData(state: 'New York', code: 'NY', necVersion: '2020', notes: 'NYC has separate code'),
    _StateData(state: 'North Carolina', code: 'NC', necVersion: '2023', notes: 'NC State Building Code'),
    _StateData(state: 'North Dakota', code: 'ND', necVersion: '2020', notes: 'Statewide'),
    _StateData(state: 'Ohio', code: 'OH', necVersion: '2023', notes: 'Ohio Building Code'),
    _StateData(state: 'Oklahoma', code: 'OK', necVersion: '2020', notes: 'Local adoption varies'),
    _StateData(state: 'Oregon', code: 'OR', necVersion: '2023', notes: 'Oregon Electrical Specialty Code'),
    _StateData(state: 'Pennsylvania', code: 'PA', necVersion: '2020', notes: 'UCC - local enforcement'),
    _StateData(state: 'Rhode Island', code: 'RI', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'South Carolina', code: 'SC', necVersion: '2020', notes: 'Statewide'),
    _StateData(state: 'South Dakota', code: 'SD', necVersion: '2020', notes: 'Local adoption'),
    _StateData(state: 'Tennessee', code: 'TN', necVersion: '2020', notes: 'Statewide minimum'),
    _StateData(state: 'Texas', code: 'TX', necVersion: '2020', notes: 'Local adoption - no state code'),
    _StateData(state: 'Utah', code: 'UT', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'Vermont', code: 'VT', necVersion: '2023', notes: 'Statewide'),
    _StateData(state: 'Virginia', code: 'VA', necVersion: '2020', notes: 'Virginia Construction Code'),
    _StateData(state: 'Washington', code: 'WA', necVersion: '2023', notes: 'WAC 296-46B'),
    _StateData(state: 'West Virginia', code: 'WV', necVersion: '2020', notes: 'Statewide'),
    _StateData(state: 'Wisconsin', code: 'WI', necVersion: '2020', notes: 'Wisconsin SPS 316'),
    _StateData(state: 'Wyoming', code: 'WY', necVersion: '2020', notes: 'Local adoption'),
    _StateData(state: 'Washington DC', code: 'DC', necVersion: '2020', notes: 'DC Construction Code'),
  ];

  List<_StateData> get _filteredStates {
    var list = _states;
    if (_filterVersion != 'All') list = list.where((s) => s.necVersion == _filterVersion).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) => s.state.toLowerCase().contains(q) || s.code.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0, leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)), title: Text('State NEC Adoption', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600))),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
          child: Row(children: [const Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 20), const SizedBox(width: 10), Expanded(child: Text('Always verify with local AHJ. Adoption dates change.', style: TextStyle(color: Colors.orange, fontSize: 12)))])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(onChanged: (v) => setState(() => _searchQuery = v), style: TextStyle(color: colors.textPrimary), decoration: InputDecoration(hintText: 'Search state...', hintStyle: TextStyle(color: colors.textTertiary), prefixIcon: Icon(LucideIcons.search, size: 20, color: colors.textSecondary), filled: true, fillColor: colors.bgElevated, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
        const SizedBox(height: 12),
        SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: ['All', '2023', '2020', '2017'].map((v) {
          final isSelected = _filterVersion == v;
          return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(onTap: () => setState(() => _filterVersion = v), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8)), child: Text(v == 'All' ? 'All' : 'NEC $v', style: TextStyle(color: isSelected ? colors.bgBase : colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)))));
        }).toList())),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerLeft, child: Text('${_filteredStates.length} states', style: TextStyle(color: colors.textTertiary, fontSize: 13)))),
        const SizedBox(height: 8),
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _filteredStates.length, itemBuilder: (context, index) {
          final state = _filteredStates[index];
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderDefault)),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(state.code, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 13)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(state.state, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)), Text(state.notes, style: TextStyle(color: colors.textTertiary, fontSize: 11))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: state.necVersion == '2023' ? colors.accentSuccess.withValues(alpha: 0.1) : colors.bgInset, borderRadius: BorderRadius.circular(6)), child: Text('NEC ${state.necVersion}', style: TextStyle(color: state.necVersion == '2023' ? colors.accentSuccess : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
            ]));
        })),
      ]),
    );
  }
}

class _StateData { final String state; final String code; final String necVersion; final String notes; const _StateData({required this.state, required this.code, required this.necVersion, required this.notes}); }
