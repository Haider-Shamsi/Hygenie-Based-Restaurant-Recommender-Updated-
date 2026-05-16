import 'package:flutter/material.dart';

// --- DATA MODELS ---

class MenuItem {
  final String id;
  final String name;
  final String price;
  final String category;

  MenuItem({required this.id, required this.name, required this.price, required this.category});
}

class PhotoItem {
  final String id;
  final String url;

  PhotoItem({required this.id, required this.url});
}

class OperatingHour {
  String openTime;
  String closeTime;
  bool isClosed;

  OperatingHour({required this.openTime, required this.closeTime, required this.isClosed});
}

// --- SCREEN WIDGET ---

class OwnerRestaurantManageScreen extends StatefulWidget {
  final VoidCallback onBack;
  const OwnerRestaurantManageScreen({super.key, required this.onBack});

  @override
  State<OwnerRestaurantManageScreen> createState() => _OwnerRestaurantManageScreenState();
}

class _OwnerRestaurantManageScreenState extends State<OwnerRestaurantManageScreen> {
  // Theme Colors
  final Color _brandTeal = const Color(0xFF10B981);
  final Color _bgGray = const Color(0xFFF9FBFB);
  final Color _inputBg = const Color(0xFFF3F4F6);

  bool _isSaving = false;
  String _selectedPriceRange = '\$\$';
  String _selectedCuisine = 'Mediterranean';

  // Controllers
  final _nameController = TextEditingController(text: 'The Green Table');
  final _descController = TextEditingController(text: 'A modern farm-to-table restaurant focusing on organic, locally-sourced ingredients with a seasonal menu.');
  final _phoneController = TextEditingController(text: '(555) 123-4567');
  final _emailController = TextEditingController(text: 'contact@greentable.com');
  final _streetController = TextEditingController(text: '123 Main Street');
  final _cityController = TextEditingController(text: 'San Francisco');
  final _stateController = TextEditingController(text: 'CA');
  final _zipController = TextEditingController(text: '94102');

  // Menu Add Form Controllers
  bool _showAddMenuItem = false;
  final _newItemNameController = TextEditingController();
  final _newItemPriceController = TextEditingController();
  String _newItemCategory = 'Appetizers';

  final List<String> _daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> _cuisines = ['Italian', 'Chinese', 'Indian', 'Mexican', 'Japanese', 'Thai', 'American', 'Mediterranean', 'Other'];
  final List<String> _menuCategories = ['Appetizers', 'Main Course', 'Desserts', 'Beverages'];

  // Operating Hours State
  late Map<String, OperatingHour> _operatingHours;

  // Photos State
  List<PhotoItem> _photos = [
    PhotoItem(id: '1', url: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400'),
    PhotoItem(id: '2', url: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=400'),
    PhotoItem(id: '3', url: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400'),
  ];

  // Menu State
  List<MenuItem> _menuItems = [
    MenuItem(id: '1', name: 'Caesar Salad', price: '12.99', category: 'Appetizers'),
    MenuItem(id: '2', name: 'Grilled Salmon', price: '28.99', category: 'Main Course'),
    MenuItem(id: '3', name: 'Chocolate Lava Cake', price: '9.99', category: 'Desserts'),
    MenuItem(id: '4', name: 'Fresh Lemonade', price: '4.99', category: 'Beverages'),
  ];

  @override
  void initState() {
    super.initState();
    _operatingHours = {
      'Monday': OperatingHour(openTime: '11:00 AM', closeTime: '10:00 PM', isClosed: false),
      'Tuesday': OperatingHour(openTime: '11:00 AM', closeTime: '10:00 PM', isClosed: false),
      'Wednesday': OperatingHour(openTime: '11:00 AM', closeTime: '10:00 PM', isClosed: false),
      'Thursday': OperatingHour(openTime: '11:00 AM', closeTime: '10:00 PM', isClosed: false),
      'Friday': OperatingHour(openTime: '11:00 AM', closeTime: '11:00 PM', isClosed: false),
      'Saturday': OperatingHour(openTime: '10:00 AM', closeTime: '11:00 PM', isClosed: false),
      'Sunday': OperatingHour(openTime: '10:00 AM', closeTime: '09:00 PM', isClosed: false),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _newItemNameController.dispose();
    _newItemPriceController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _handleSaveChanges() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate API Call
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant details updated successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  void _handleAddPhoto() {
    if (_photos.length < 10) {
      setState(() {
        _photos.add(PhotoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400', // Mock new image
        ));
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploaded successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 10 photos allowed'), backgroundColor: Colors.red));
    }
  }

  void _handleDeletePhoto(String id) {
    setState(() {
      _photos.removeWhere((p) => p.id == id);
    });
  }

  void _handleAddMenuItem() {
    if (_newItemNameController.text.isEmpty || _newItemPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _menuItems.add(MenuItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _newItemNameController.text,
        price: _newItemPriceController.text,
        category: _newItemCategory,
      ));
      _showAddMenuItem = false;
      _newItemNameController.clear();
      _newItemPriceController.clear();
      _newItemCategory = 'Appetizers';
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu item added')));
  }

  void _handleDeleteMenuItem(String id) {
    setState(() {
      _menuItems.removeWhere((item) => item.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu item deleted')));
  }

  Future<void> _selectTime(BuildContext context, String day, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && mounted) {
      setState(() {
        if (isOpening) {
          _operatingHours[day]!.openTime = picked.format(context);
        } else {
          _operatingHours[day]!.closeTime = picked.format(context);
        }
      });
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)), onPressed: widget.onBack),
        title: const Text("Manage Restaurant", style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(color: Colors.grey.shade200, height: 1.0)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 20),
            _buildPhotosSection(),
            const SizedBox(height: 20),
            _buildMenuSection(),
            const SizedBox(height: 30),
            _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildCard(
      title: "Restaurant Profile",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel("Restaurant Name"),
          _buildTextField(_nameController, "Enter restaurant name"),
          
          _buildInputLabel("Description"),
          _buildTextField(_descController, "Describe your restaurant", maxLines: 4),

          _buildInputLabel("Cuisine Type"),
          DropdownButtonFormField<String>(
            value: _selectedCuisine,
            decoration: _inputDecoration(),
            items: _cuisines.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _selectedCuisine = val!),
          ),
          const SizedBox(height: 16),

          _buildInputLabel("Price Range"),
          Row(
            children: ['\$', '\$\$', '\$\$\$', '\$\$\$\$'].map((range) {
              bool isSelected = _selectedPriceRange == range;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPriceRange = range),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _brandTeal.withOpacity(0.1) : Colors.white,
                      border: Border.all(color: isSelected ? _brandTeal : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(range, style: TextStyle(color: isSelected ? _brandTeal : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("Phone Number"), _buildTextField(_phoneController, "(555) 123-4567")])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("Email"), _buildTextField(_emailController, "contact@example.com")])),
            ],
          ),

          _buildInputLabel("Street Address"),
          _buildTextField(_streetController, "123 Main Street"),

          Row(
            children: [
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("City"), _buildTextField(_cityController, "San Francisco")])),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("State"), _buildTextField(_stateController, "CA")])),
            ],
          ),

          _buildInputLabel("ZIP Code"),
          _buildTextField(_zipController, "94102"),

          _buildInputLabel("Operating Hours"),
          ..._daysOfWeek.map((day) => _buildOperatingHourRow(day)),
        ],
      ),
    );
  }

  Widget _buildOperatingHourRow(String day) {
    final hours = _operatingHours[day]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 45, child: Text(day.substring(0, 3), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(
            child: hours.isClosed
                ? Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _inputBg, borderRadius: BorderRadius.circular(10)),
                    child: const Text("Closed", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                : Row(
                    children: [
                      Expanded(child: _buildTimePickerField(hours.openTime, () => _selectTime(context, day, true))),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("-", style: TextStyle(color: Colors.grey))),
                      Expanded(child: _buildTimePickerField(hours.closeTime, () => _selectTime(context, day, false))),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => setState(() => hours.isClosed = !hours.isClosed),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hours.isClosed ? _brandTeal.withOpacity(0.1) : _inputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(hours.isClosed ? "Open" : "Close", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: hours.isClosed ? _brandTeal : Colors.grey.shade700)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimePickerField(String time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _inputBg, borderRadius: BorderRadius.circular(10)),
        child: Text(time, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return _buildCard(
      title: "Photos",
      trailing: Text("${_photos.length}/10 photos", style: const TextStyle(color: Colors.grey, fontSize: 12)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: _photos.length < 10 ? _photos.length + 1 : 10,
        itemBuilder: (context, index) {
          if (index == _photos.length) {
            return InkWell(
              onTap: _handleAddPhoto,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2), // Mimicking dashed
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: Colors.grey.shade400),
                    const SizedBox(height: 4),
                    Text("Add Photo", style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_photos[index].url, fit: BoxFit.cover)),
              Positioned(
                top: 4, right: 4,
                child: InkWell(
                  onTap: () => _handleDeletePhoto(_photos[index].id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuSection() {
    return _buildCard(
      title: "Menu Highlights",
      trailing: OutlinedButton.icon(
        onPressed: () => setState(() => _showAddMenuItem = !_showAddMenuItem),
        icon: const Icon(Icons.add, size: 16),
        label: const Text("Add Item"),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showAddMenuItem) _buildAddMenuItemForm(),
          ..._menuCategories.map((category) {
            final categoryItems = _menuItems.where((i) => i.category == category).toList();
            if (categoryItems.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                ),
                ...categoryItems.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text("\$${item.price}", style: TextStyle(color: _brandTeal, fontWeight: FontWeight.w500, fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), onPressed: () => _handleDeleteMenuItem(item.id)),
                        ],
                      ),
                    ))
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddMenuItemForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildTextField(_newItemNameController, "Item name"),
          Row(
            children: [
              Expanded(child: _buildTextField(_newItemPriceController, "Price (e.g., 12.99)")),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _newItemCategory,
                  decoration: _inputDecoration().copyWith(fillColor: Colors.white),
                  items: _menuCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _newItemCategory = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _handleAddMenuItem,
                child: const Text("Add", style: TextStyle(color: Colors.white)),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => setState(() => _showAddMenuItem = false),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              )),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _handleSaveChanges,
        icon: _isSaving 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
          : const Icon(Icons.save_outlined, color: Colors.white),
        label: Text(_isSaving ? "Saving Changes..." : "Save Changes", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandTeal,
          disabledBackgroundColor: _brandTeal.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: _inputDecoration(hint),
      ),
    );
  }

  InputDecoration _inputDecoration([String? hint]) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: _inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}