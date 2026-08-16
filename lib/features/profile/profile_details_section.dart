import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/category/vendor_category.dart';
import '../../core/widgets/common.dart';

/// Extended marketplace profile fields — comp card, spaces, equipment, scenes, etc.
class ProfileDetailsSection extends StatefulWidget {
  final VendorCategoryConfig cfg;
  final Map<String, dynamic> initial;
  final Future<void> Function(Map<String, dynamic> payload) onSave;
  const ProfileDetailsSection({
    super.key,
    required this.cfg,
    required this.initial,
    required this.onSave,
  });

  @override
  State<ProfileDetailsSection> createState() => _ProfileDetailsSectionState();
}

class _ProfileDetailsSectionState extends State<ProfileDetailsSection> {
  late final TextEditingController _overview;
  late final TextEditingController _experience;
  late final TextEditingController _training;
  late final TextEditingController _languages;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _bust;
  late final TextEditingController _chest;
  late final TextEditingController _waist;
  late final TextEditingController _hip;
  late final TextEditingController _shoe;
  late final TextEditingController _age;
  late final TextEditingController _hair;
  late final TextEditingController _eye;
  late final TextEditingController _skin;

  List<Map<String, dynamic>> _equipment = [];
  List<Map<String, dynamic>> _spaces = [];
  List<Map<String, dynamic>> _reels = [];
  List<String> _services = [];
  List<String> _amenities = [];
  List<String> _availability = [];
  List<Map<String, dynamic>> _sceneData = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    final cc = (d['comp_card'] as Map?)?.cast<String, dynamic>() ?? {};
    _overview = TextEditingController(text: d['overview'] as String? ?? '');
    _experience = TextEditingController(text: d['experience'] as String? ?? '');
    _training = TextEditingController(text: d['training'] as String? ?? '');
    _languages = TextEditingController(text: d['languages'] as String? ?? '');
    _height = TextEditingController(text: cc['height'] as String? ?? '');
    _weight = TextEditingController(text: cc['weight'] as String? ?? '');
    _bust = TextEditingController(text: cc['bust'] as String? ?? '');
    _chest = TextEditingController(text: cc['chest'] as String? ?? '');
    _waist = TextEditingController(text: cc['waist'] as String? ?? '');
    _hip = TextEditingController(text: cc['hip'] as String? ?? '');
    _shoe = TextEditingController(text: cc['shoe'] as String? ?? '');
    _age = TextEditingController(text: cc['age']?.toString() ?? '');
    _hair = TextEditingController(text: cc['hair'] as String? ?? '');
    _eye = TextEditingController(text: cc['eye'] as String? ?? '');
    _skin = TextEditingController(text: cc['skin'] as String? ?? '');
    _equipment = ((d['equipment'] as List?) ?? []).cast<Map<String, dynamic>>();
    _spaces = ((d['spaces'] as List?) ?? []).cast<Map<String, dynamic>>();
    _reels = ((d['reels'] as List?) ?? []).cast<Map<String, dynamic>>();
    _services = ((d['services'] as List?) ?? []).cast<String>();
    _amenities = ((d['amenities'] as List?) ?? []).cast<String>();
    _availability = ((d['availability'] as List?) ?? []).cast<String>();
    _sceneData = ((d['scene_data'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  @override
  void dispose() {
    for (final c in [_overview, _experience, _training, _languages, _height, _weight, _bust, _chest, _waist, _hip, _shoe, _age, _hair, _eye, _skin]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final age = int.tryParse(_age.text.trim());
    return {
      'overview': _overview.text.trim(),
      'experience': _experience.text.trim(),
      'training': _training.text.trim(),
      'languages': _languages.text.trim(),
      'comp_card': {
        'height': _height.text.trim(),
        'weight': _weight.text.trim(),
        'bust': _bust.text.trim(),
        'chest': _chest.text.trim(),
        'waist': _waist.text.trim(),
        'hip': _hip.text.trim(),
        'shoe': _shoe.text.trim(),
        'age': age,
        'hair': _hair.text.trim(),
        'eye': _eye.text.trim(),
        'skin': _skin.text.trim(),
      },
      'equipment': _equipment,
      'spaces': _spaces,
      'reels': _reels,
      'services': _services,
      'amenities': _amenities,
      'availability': _availability,
      'scene_data': _sceneData,
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_payload());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cfg;
    final isTalent = c.category == VendorCategory.talent;
    final isVenue = c.category == VendorCategory.venue;
    final isVideo = c.category == VendorCategory.videography;
    final isPhoto = c.category == VendorCategory.photography;
    final isEvent = c.category == VendorCategory.events;

    return SectionCard(
      title: 'Marketplace Profile Details',
      actions: [
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1407)))
              : const Icon(Icons.save_outlined, size: 16),
          label: Text(_saving ? 'Saving…' : 'Save details'),
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('These fields power the extra tabs on your public profile in the user app.', style: AppType.body(size: 12.5, color: AppColors.textMuted, height: 1.5)),
        const SizedBox(height: 16),
        _field('Extended overview', _overview, lines: 3),
        _field('Experience label', _experience, hint: 'e.g. 5 yrs'),
        _field('Training', _training),
        _field('Languages', _languages, hint: 'Hindi, English'),
        if (isTalent) ...[
          const SizedBox(height: 8),
          Text('Comp card measurements', style: AppType.body(size: 13, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _mini('Height', _height),
            _mini('Weight', _weight),
            _mini('Bust', _bust),
            _mini('Chest', _chest),
            _mini('Waist', _waist),
            _mini('Hip', _hip),
            _mini('Shoe', _shoe),
            _mini('Age', _age),
            _mini('Hair', _hair),
            _mini('Eyes', _eye),
            _mini('Skin', _skin),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text('Scene availability items', style: AppType.body(size: 13, weight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: _addSceneGroup,
              icon: const Icon(Icons.folder_outlined, size: 16),
              label: const Text('Add section'),
            ),
            TextButton.icon(
              onPressed: () => _editSceneItem(null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add item'),
            ),
          ]),
          if (_sceneData.isEmpty)
            Text('None added yet', style: AppType.body(size: 12, color: AppColors.textMuted))
          else
            for (var i = 0; i < _sceneData.length; i++)
              if (_sceneData[i].containsKey('group'))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${_sceneData[i]['group']}',
                    style: AppType.body(size: 13, weight: FontWeight.w700),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => setState(() => _sceneData.removeAt(i)),
                  ),
                )
              else
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${_sceneData[i]['label'] ?? 'Scene'}', style: AppType.body(size: 13)),
                  subtitle: Text(
                    '${_sceneData[i]['status'] ?? 'avail'} · ${_sceneData[i]['desc'] ?? ''}',
                    style: AppType.body(size: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _editSceneItem(_sceneData[i], index: i)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => setState(() => _sceneData.removeAt(i))),
                  ]),
                ),
        ],
        if (isVenue) ...[
          _stringListSection('Amenities', _amenities, (v) => setState(() => _amenities.add(v)), (i) => setState(() => _amenities.removeAt(i))),
          _listSection('Event spaces', _spaces.length, () => _editSpace(null), (i) => _editSpace(_spaces[i], index: i), (i) => setState(() => _spaces.removeAt(i)), (i) => '${_spaces[i]['name'] ?? 'Space'}'),
          _stringListSection('Availability (14 days)', _availability, (v) => setState(() => _availability.add(v)), (i) => setState(() => _availability.removeAt(i)), hint: 'open, busy, or today'),
        ],
        if (isPhoto || isVideo) ...[
          _listSection('Equipment', _equipment.length, () => _editEquipment(null), (i) => _editEquipment(_equipment[i], index: i), (i) => setState(() => _equipment.removeAt(i)), (i) => '${_equipment[i]['name'] ?? 'Item'}'),
        ],
        if (isVideo) ...[
          _listSection('Showreels', _reels.length, () => _editReel(null), (i) => _editReel(_reels[i], index: i), (i) => setState(() => _reels.removeAt(i)), (i) => '${_reels[i]['name'] ?? 'Reel'}'),
        ],
        if (isEvent) ...[
          _stringListSection('Services managed', _services, (v) => setState(() => _services.add(v)), (i) => setState(() => _services.removeAt(i))),
        ],
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int lines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppType.body(size: 12.5, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, maxLines: lines, decoration: InputDecoration(hintText: hint)),
      ]),
    );
  }

  Widget _mini(String label, TextEditingController ctrl) {
    return SizedBox(
      width: 120,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppType.body(size: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        TextField(controller: ctrl),
      ]),
    );
  }

  Widget _listSection(String title, int count, VoidCallback onAdd, void Function(int) onEdit, void Function(int) onDelete, String Function(int) label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: AppType.body(size: 13, weight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
        ]),
        if (count == 0)
          Text('None added yet', style: AppType.body(size: 12, color: AppColors.textMuted))
        else
          for (var i = 0; i < count; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(label(i), style: AppType.body(size: 13)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => onEdit(i)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => onDelete(i)),
              ]),
            ),
      ]),
    );
  }

  Widget _stringListSection(String title, List<String> items, ValueChanged<String> onAdd, void Function(int) onDelete, {String hint = ''}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: AppType.body(size: 13, weight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _prompt('Add item', hint: hint, onSubmit: onAdd),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
          ),
        ]),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < items.length; i++)
            InputChip(label: Text(items[i]), onDeleted: () => onDelete(i)),
        ]),
      ]),
    );
  }

  void _prompt(String title, {String hint = '', required ValueChanged<String> onSubmit}) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (ctrl.text.trim().isEmpty) return;
            onSubmit(ctrl.text.trim());
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  void _editEquipment(Map<String, dynamic>? item, {int? index}) {
    final name = TextEditingController(text: item?['name'] as String? ?? '');
    final note = TextEditingController(text: item?['note'] as String? ?? '');
    final emoji = TextEditingController(text: item?['e'] as String? ?? '📷');
    _mapDialog('Equipment item', () => {}, [name, note, emoji], () {
      final map = {
        'name': name.text.trim(),
        'note': note.text.trim(),
        'e': emoji.text.trim().isEmpty ? '📷' : emoji.text.trim(),
      };
      setState(() {
        if (index == null) {
          _equipment.add(map);
        } else {
          _equipment[index] = map;
        }
      });
    }, fields: [
      ('Name', name),
      ('Note', note),
      ('Emoji', emoji),
    ]);
  }

  void _editSpace(Map<String, dynamic>? item, {int? index}) {
    final name = TextEditingController(text: item?['name'] as String? ?? '');
    final cap = TextEditingController(text: item?['cap'] as String? ?? '');
    final price = TextEditingController(text: item?['price'] as String? ?? '');
    final emoji = TextEditingController(text: item?['e'] as String? ?? '🏛️');
    _mapDialog('Space', () => {}, [name, cap, price, emoji], () {
      final map = {
        'name': name.text.trim(),
        'cap': cap.text.trim(),
        'price': price.text.trim(),
        'e': emoji.text.trim().isEmpty ? '🏛️' : emoji.text.trim(),
        'bg': index ?? _spaces.length,
      };
      setState(() {
        if (index == null) {
          _spaces.add(map);
        } else {
          _spaces[index] = map;
        }
      });
    }, fields: [
      ('Name', name),
      ('Capacity', cap),
      ('Price', price),
      ('Emoji', emoji),
    ]);
  }

  void _editReel(Map<String, dynamic>? item, {int? index}) {
    final name = TextEditingController(text: item?['name'] as String? ?? '');
    final dur = TextEditingController(text: item?['dur'] as String? ?? '');
    final type = TextEditingController(text: item?['type'] as String? ?? '');
    final emoji = TextEditingController(text: item?['e'] as String? ?? '🎥');
    _mapDialog('Showreel', () => {}, [name, dur, type, emoji], () {
      final map = {
        'name': name.text.trim(),
        'dur': dur.text.trim(),
        'type': type.text.trim(),
        'e': emoji.text.trim().isEmpty ? '🎥' : emoji.text.trim(),
      };
      setState(() {
        if (index == null) {
          _reels.add(map);
        } else {
          _reels[index] = map;
        }
      });
    }, fields: [
      ('Title', name),
      ('Duration', dur),
      ('Type', type),
      ('Emoji', emoji),
    ]);
  }

  void _addSceneGroup() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scene section'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'e.g. Film & On-Screen Work'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (ctrl.text.trim().isEmpty) return;
            setState(() => _sceneData.add({'group': ctrl.text.trim()}));
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  void _editSceneItem(Map<String, dynamic>? item, {int? index}) {
    final label = TextEditingController(text: item?['label'] as String? ?? '');
    final desc = TextEditingController(text: item?['desc'] as String? ?? '');
    var status = (item?['status'] as String?)?.trim().isNotEmpty == true ? item!['status'] as String : 'avail';
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Scene item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
                const SizedBox(height: 10),
                TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Availability status'),
                  items: const [
                    DropdownMenuItem(value: 'avail', child: Text('Available')),
                    DropdownMenuItem(value: 'verified', child: Text('Verified client required')),
                    DropdownMenuItem(value: 'restricted', child: Text('Admin approval required')),
                    DropdownMenuItem(value: 'no', child: Text('Not available')),
                  ],
                  onChanged: (v) => setLocal(() => status = v ?? 'avail'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () {
              if (label.text.trim().isEmpty) return;
              final map = {
                'status': status,
                'icon': switch (status) {
                  'verified' => '⚠',
                  'restricted' => '🔒',
                  'no' => '✗',
                  _ => '✓',
                },
                'label': label.text.trim(),
                'desc': desc.text.trim(),
              };
              setState(() {
                if (index == null) {
                  _sceneData.add(map);
                } else {
                  _sceneData[index] = map;
                }
              });
              Navigator.pop(ctx);
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  void _mapDialog(String title, VoidCallback _, List<TextEditingController> controllers, VoidCallback onSave, {List<(String, TextEditingController)>? fields}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in fields ?? [])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(controller: f.$2, decoration: InputDecoration(labelText: f.$1)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            onSave();
            Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}
