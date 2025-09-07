// screens/contact_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_maintain/riverpod/show_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contact_screen.dart';
import 'models/contact.dart';

class ContactListScreen extends ConsumerStatefulWidget {
  const ContactListScreen({super.key});

  @override
  ConsumerState<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends ConsumerState<ContactListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Hide search bar when scrolling if it's visible
    if (_showSearchBar && _scrollController.position.hasContentDimensions) {
      if (_scrollController.offset > 20) {
        setState(() {
          _showSearchBar = false;
        });
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        // Focus on search field when it appears
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        // Clear search when hiding
        ref.read(searchQueryProvider.notifier).state = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final filteredContacts = ref.watch(filteredContactsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: _showSearchBar
            ? _buildSearchField(ref)
            : const Text(
          'Contacts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        actions: [
          if (!_showSearchBar) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
              tooltip: 'Search',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  ContactInfoScreen()),
                );
              },
              tooltip: 'Add New Contact',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSearch,
              tooltip: 'Close Search',
            ),
          ],
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.primary.withOpacity(0.02),
              Colors.transparent,
            ],
          ),
        ),
        child: contactsAsync.when(
          loading: () => const _LoadingState(),
          error: (error, stack) => _ErrorState(error: error, ref: ref),
          data: (contacts) {
            final displayContacts = searchQuery.isEmpty ? contacts : filteredContacts;

            if (displayContacts.isEmpty) {
              return _buildEmptyState(searchQuery);
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(contactsProvider);
              },
              color: theme.colorScheme.primary,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: displayContacts.length,
                itemBuilder: (context, index) {
                  final contact = displayContacts[index];
                  return _ContactCard(contact: contact);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  ContactInfoScreen()),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildSearchField(WidgetRef ref) {
    return TextField(
      focusNode: _searchFocusNode,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search contacts...',
        hintStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      style: const TextStyle(color: Colors.white, fontSize: 18),
      cursorColor: Colors.white,
      onChanged: (value) {
        ref.read(searchQueryProvider.notifier).state = value;
      },
    );
  }

  Widget _buildEmptyState(String searchQuery) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Icon(
              Icons.contacts_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              searchQuery.isEmpty ? 'No contacts yet' : 'No matches found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                searchQuery.isEmpty
                    ? 'Get started by adding your first contact'
                    : 'Try a different search term or add a new contact',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContactInfoScreen()),
                  );
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add First Contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading contacts...',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final WidgetRef ref;

  const _ErrorState({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 24),
            const Text(
              'Unable to load contacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(contactsProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;

  const _ContactCard({required this.contact});

  AlertDialog _buildDeleteDialog(Contact contact,BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Contact'),
      content: Text(
          'Are you sure you want to delete ${contact.personName} from your contacts?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Close the dialog
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            FirebaseFirestore.instance.collection('contacts').doc(contact.id).delete();

            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _showContactDetails(context, contact),
          onLongPress: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return _buildDeleteDialog(contact, context);
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with gradient
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [
                        _getColorFromName(contact.personName),
                        _getColorFromName(contact.personName).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      contact.personName.isNotEmpty ? contact.personName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.personName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contact.companyName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          contact.companyName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (contact.phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              contact.phoneNumber,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Contact Type & Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getColorForType(contact.contactType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        contact.contactType,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getColorForType(contact.contactType),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM dd').format(contact.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorFromName(String name) {
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.red.shade700,
      Colors.teal.shade700,
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'business':
        return Colors.blue.shade700;
      case 'personal':
        return Colors.green.shade700;
      case 'client':
        return Colors.orange.shade700;
      case 'supplier':
        return Colors.purple.shade700;
      case 'colleague':
        return Colors.teal.shade700;
      case 'friend':
        return Colors.pink.shade700;
      case 'family':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  void _showContactDetails(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => _ContactDetailsSheet(contact: contact),
    );
  }
}

class _ContactDetailsSheet extends StatelessWidget {
  final Contact contact;

  const _ContactDetailsSheet({required this.contact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Contact header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        _getColorFromName(contact.personName),
                        _getColorFromName(contact.personName).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      contact.personName.isNotEmpty ? contact.personName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.personName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (contact.companyName.isNotEmpty)
                        Text(
                          contact.companyName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(onPressed: (){
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ContactInfoScreen(contact: contact,)));
                }, icon: Icon(Icons.edit))
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contact.phoneNumber.isNotEmpty)
                  _DetailItem(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: contact.phoneNumber,
                    color: theme.colorScheme.primary,
                  ),
                if (contact.email.isNotEmpty)
                  _DetailItem(
                    icon: Icons.email,
                    label: 'Email',
                    value: contact.email,
                    color: theme.colorScheme.primary,
                  ),
                if (contact.location.isNotEmpty)
                  _DetailItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: contact.location,
                    color: theme.colorScheme.primary,
                  ),
                if (contact.notes.isNotEmpty)
                  _DetailItem(
                    icon: Icons.notes,
                    label: 'Notes',
                    value: contact.notes,
                    color: theme.colorScheme.primary,
                  ),
                _DetailItem(
                  icon: Icons.category,
                  label: 'Type',
                  value: contact.contactType,
                  color: theme.colorScheme.primary,
                ),
                _DetailItem(
                  icon: Icons.circle,
                  label: 'Status',
                  value: contact.status,
                  color: contact.status.toLowerCase() == 'active'
                      ? Colors.green
                      : Colors.orange,
                ),
                _DetailItem(
                  icon: Icons.calendar_today,
                  label: 'Added',
                  value: DateFormat('MMM dd, yyyy - HH:mm').format(contact.timestamp),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: contact.imageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = contact.imageUrls[index];
                final heroTag = 'image-$index';

                return GestureDetector(
                  onTap: () => _showFullScreenImage(contact.imageUrls, heroTag,context,index),
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 16 : 8,
                      right: index == contact.imageUrls.length - 1 ? 16 : 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Hero(
                        tag: heroTag,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String name) {
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.red.shade700,
      Colors.teal.shade700,
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  void _showFullScreenImage(List<String> imageUrls, String heroTag,BuildContext ctx,int index) {
    Navigator.of(ctx).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return FullScreenImage(imageUrls: imageUrls, heroTag: heroTag,initialIndex: index,);
        },
      ),
    );
  }
}


class FullScreenImage extends StatefulWidget {
  final String heroTag;
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImage({
    super.key,
    required this.heroTag,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for swiping between images
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Optional: Add tap to toggle UI visibility
                },
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: widget.heroTag,
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),

          // Image counter indicator
          if (widget.imageUrls.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

          // Navigation arrows (for larger screens or optional)
          if (widget.imageUrls.length > 1)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 36,
                  ),
                  onPressed: _currentIndex > 0
                      ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                      : null,
                ),
              ),
            ),

          if (widget.imageUrls.length > 1)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 36,
                  ),
                  onPressed: _currentIndex < widget.imageUrls.length - 1
                      ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if(label=='Phone')IconButton(onPressed: () async {
            final Uri launchUri = Uri(
              scheme: 'tel',
              path: value,
            );
            await launchUrl(launchUri);
          }, icon: Icon(Icons.call))
        ],
      ),
    );
  }
}