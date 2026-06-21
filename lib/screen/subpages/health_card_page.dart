import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medicare_admin_remaster/class/loa_request.dart';
import 'package:medicare_admin_remaster/shared/api.dart';
import 'package:medicare_admin_remaster/shared/download_bytes.dart';
import 'package:medicare_admin_remaster/shared/list.dart';

class HealthCardPage extends StatefulWidget {
  const HealthCardPage({super.key});

  @override
  State<HealthCardPage> createState() => _HealthCardPageState();
}

class _HealthCardPageState extends State<HealthCardPage>
    with SingleTickerProviderStateMixin {
  static const String _cardDesignBucket = 'mp-card-designs';
  static const String _cardDesignFolder = 'variants';

  late TabController _tabController;

  // Data
  List<Map<String, dynamic>> companies = [];
  List<Map<String, dynamic>> cardVariants = [];
  Map<int, String> cardVariantImageUrls = {};
  bool isLoading = true;

  // Form controllers
  final TextEditingController companyNameController = TextEditingController();
  int? selectedCardVariantId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    companyNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchCompanies(),
      _fetchCardVariants(),
      _fetchCardDesignImageUrls(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _fetchCompanies() async {
    try {
      final response = await Supabase.instance.client
          .from('mp_companies_table')
          .select('*, mp_card_variants_table(card_name, card_variant)')
          .order('created_at', ascending: false);
      setState(() {
        companies = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching companies: $e');
    }
  }

  Future<void> _fetchCardVariants() async {
    try {
      final response = await Supabase.instance.client
          .from('mp_card_variants_table')
          .select();
      setState(() {
        cardVariants = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching card variants: $e');
    }
  }

  Future<void> _fetchCardDesignImageUrls() async {
    try {
      final files = await Supabase.instance.client.storage
          .from(_cardDesignBucket)
          .list(path: _cardDesignFolder);

      final Map<int, String> urlMap = {};
      for (final file in files) {
        final fileName = file.name;
        final idPart = fileName.split('.').first;
        final id = int.tryParse(idPart);
        if (id == null) {
          continue;
        }
        final publicUrl = Supabase.instance.client.storage
            .from(_cardDesignBucket)
            .getPublicUrl('$_cardDesignFolder/$fileName');
        urlMap[id] = publicUrl;
      }

      if (!mounted) return;
      setState(() {
        cardVariantImageUrls = urlMap;
      });
    } catch (e) {
      debugPrint('Error fetching card design images: $e');
      if (!mounted) return;
      setState(() {
        cardVariantImageUrls = {};
      });
    }
  }

  Future<int?> _createCardDesign({
    required String cardName,
    required String cardVariant,
  }) async {
    // UAT fallback: this table's PK default currently does not auto-increment.
    // We derive the next card_variant_id client-side so inserts remain usable.
    int? lastId;
    final latest = await Supabase.instance.client
        .from('mp_card_variants_table')
        .select('card_variant_id')
        .order('card_variant_id', ascending: false)
        .limit(1);

    if (latest.isNotEmpty) {
      final dynamic rawId = latest.first['card_variant_id'];
      if (rawId is int) {
        lastId = rawId;
      } else {
        lastId = int.tryParse('$rawId');
      }
    }

    int nextId = (lastId ?? 0) + 1;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await Supabase.instance.client
            .from('mp_card_variants_table')
            .insert({
              'card_variant_id': nextId,
              'card_name': cardName,
              'card_variant': cardVariant,
            })
            .select('card_variant_id')
            .single();

        final dynamic variantId = response['card_variant_id'];
        if (variantId is int) {
          return variantId;
        }
        return int.tryParse('$variantId');
      } catch (_) {
        nextId += 1;
      }
    }

    throw Exception('Unable to allocate a unique card design ID.');
  }

  Future<void> _uploadCardDesignImage({
    required int cardVariantId,
    required PlatformFile imageFile,
    bool replaceExisting = true,
  }) async {
    final bytes = imageFile.bytes;
    if (bytes == null) {
      throw Exception('Selected image has no readable bytes.');
    }

    final extension = _resolveImageExtension(imageFile);
    final path = '$_cardDesignFolder/$cardVariantId.$extension';
    final storage = Supabase.instance.client.storage.from(_cardDesignBucket);

    if (replaceExisting) {
      await _deleteCardDesignImagesForVariant(cardVariantId);
    }

    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: _contentTypeForExtension(extension),
      ),
    );
  }

  Future<void> _deleteCardDesignImagesForVariant(int cardVariantId) async {
    final storage = Supabase.instance.client.storage.from(_cardDesignBucket);
    final files = await storage.list(path: _cardDesignFolder);
    final targets = files
        .map((file) => file.name)
        .where((name) => name.split('.').first == '$cardVariantId')
        .map((name) => '$_cardDesignFolder/$name')
        .toList();

    if (targets.isEmpty) {
      return;
    }

    await storage.remove(targets);
  }

  Future<void> _updateCardDesign({
    required int cardVariantId,
    required String cardName,
    required String cardVariant,
    PlatformFile? imageFile,
  }) async {
    await Supabase.instance.client.from('mp_card_variants_table').update({
      'card_name': cardName,
      'card_variant': cardVariant,
    }).eq('card_variant_id', cardVariantId);

    if (imageFile != null) {
      await _uploadCardDesignImage(
        cardVariantId: cardVariantId,
        imageFile: imageFile,
        replaceExisting: true,
      );
    }
  }

  String _resolveImageExtension(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase().trim();
    if (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp') {
      return ext;
    }
    final fileName = file.name.toLowerCase();
    if (fileName.endsWith('.png')) return 'png';
    if (fileName.endsWith('.jpg')) return 'jpg';
    if (fileName.endsWith('.jpeg')) return 'jpeg';
    if (fileName.endsWith('.webp')) return 'webp';
    return 'png';
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'png':
      default:
        return 'image/png';
    }
  }

  Future<int?> _showAddCardDesignDialog() async {
    final cardNameController = TextEditingController();
    final cardVariantController = TextEditingController();
    PlatformFile? selectedDesignFile;

    final int? createdVariantId = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleCreateCardDesign() async {
              final cardName = cardNameController.text.trim();
              final cardVariantInput = cardVariantController.text.trim();
              final cardVariant =
                  cardVariantInput.isEmpty ? cardName : cardVariantInput;

              if (cardName.isEmpty) {
                _showMessage(
                    'Card design name is required.', 'Missing Information');
                return;
              }

              try {
                setDialogState(() => isSaving = true);
                final int? variantId = await _createCardDesign(
                  cardName: cardName,
                  cardVariant: cardVariant,
                );
                if (variantId != null && selectedDesignFile != null) {
                  try {
                    await _uploadCardDesignImage(
                      cardVariantId: variantId,
                      imageFile: selectedDesignFile!,
                    );
                  } catch (e) {
                    await Supabase.instance.client
                        .from('mp_card_variants_table')
                        .delete()
                        .eq('card_variant_id', variantId);
                    rethrow;
                  }
                }
                if (!context.mounted) return;
                Navigator.of(context).pop(variantId);
              } catch (e) {
                if (!context.mounted) return;
                setDialogState(() => isSaving = false);
                _showMessage('Failed to create card design: $e', 'Error');
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: const BorderSide(color: Color(0xff13322b), width: 2),
              ),
              title: const Center(
                child: Text(
                  'Add Card Design',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff13322b),
                  ),
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Card Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff13322b),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: cardNameController,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. PREMIER PLUS',
                        hintStyle: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xff13322b)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Card Variant (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff13322b),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: cardVariantController,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. COMPREHENSIVE - PREMIER PLUS',
                        hintStyle: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xff13322b)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Card Design Image',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff13322b),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xff13322b)
                                    .withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedDesignFile?.name ?? 'No image selected',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selectedDesignFile == null
                                    ? Colors.black.withValues(alpha: 0.6)
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final result =
                                        await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: [
                                        'png',
                                        'jpg',
                                        'jpeg',
                                        'webp'
                                      ],
                                      withData: true,
                                    );
                                    if (result == null ||
                                        result.files.isEmpty) {
                                      return;
                                    }
                                    setDialogState(() {
                                      selectedDesignFile = result.files.first;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xff13322b),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Upload',
                              style: TextStyle(color: Color(0xff13322b)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 35,
                      child: ElevatedButton(
                        onPressed:
                            isSaving ? null : () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(color: Color(0xff13322b)),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : handleCreateCardDesign,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          backgroundColor: const Color(0xff13322b),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    cardNameController.dispose();
    cardVariantController.dispose();

    if (createdVariantId != null) {
      await Future.wait([
        _fetchCardVariants(),
        _fetchCardDesignImageUrls(),
      ]);
    }

    return createdVariantId;
  }

  Future<void> _addCompany() async {
    if (companyNameController.text.isEmpty || selectedCardVariantId == null) {
      _showMessage('Please fill in all fields.', 'Missing Information');
      return;
    }

    try {
      await Supabase.instance.client.from('mp_companies_table').insert({
        'name': companyNameController.text.trim(),
        'card_variant_id': selectedCardVariantId,
      });
      if (!mounted) return;
      companyNameController.clear();
      selectedCardVariantId = null;
      Navigator.of(context).pop();
      _showMessage('Company has been successfully created.', 'Company Added');
      await _fetchCompanies();
    } catch (e) {
      _showMessage('Failed to create company: $e', 'Error');
    }
  }

  Future<void> _updateCompanyCardDesign(
      int companyId, int newCardVariantId) async {
    try {
      await Supabase.instance.client
          .from('mp_companies_table')
          .update({'card_variant_id': newCardVariantId}).eq('id', companyId);
      _showMessage('Card design updated successfully.', 'Design Updated');
      await _fetchCompanies();
    } catch (e) {
      _showMessage('Failed to update card design: $e', 'Error');
    }
  }

  Future<void> _deleteCompany(int companyId) async {
    // Check if company has members
    try {
      final members = await Supabase.instance.client
          .from('mp_customers_info_table')
          .select('id')
          .eq('company_id', companyId)
          .limit(1);

      if ((members as List).isNotEmpty) {
        _showMessage(
            'Cannot delete company with existing members. Remove or reassign members first.',
            'Cannot Delete');
        return;
      }

      await Supabase.instance.client
          .from('mp_companies_table')
          .delete()
          .eq('id', companyId);
      _showMessage('Company deleted successfully.', 'Deleted');
      await _fetchCompanies();
    } catch (e) {
      _showMessage('Failed to delete company: $e', 'Error');
    }
  }

  Future<int> _getMemberCount(int companyId) async {
    try {
      final response = await Supabase.instance.client
          .from('mp_customers_info_table')
          .select('id')
          .eq('company_id', companyId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  static const int _pageSize = 50;

  Future<List<Map<String, dynamic>>> _fetchCompanyMembers(
      int companyId, {int page = 0}) async {
    final from = page * _pageSize;
    final to = from + _pageSize - 1;
    final response = await Supabase.instance.client
        .from('mp_customers_info_table')
        .select(
            'id, first_name, middle_name, last_name, email_address, contact_no, is_active')
        .filter('company_id', 'eq', companyId)
        .order('last_name', ascending: true)
        .order('first_name', ascending: true)
        .range(from, to);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> _countCompanyMembers(int companyId) async {
    try {
      final response = await Supabase.instance.client
          .from('mp_customers_info_table')
          .select('id')
          .filter('company_id', 'eq', companyId);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _searchMembersNotInCompany(
      int companyId, String query) async {
    final response = await Supabase.instance.client
        .from('mp_customers_info_table')
        .select('id, first_name, middle_name, last_name, email_address, contact_no')
        .or('company_id.is.null,company_id.neq.$companyId')
        .or(
          'first_name.ilike.%$query%,last_name.ilike.%$query%,email_address.ilike.%$query%,contact_no.ilike.%$query%',
        )
        .order('last_name')
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _assignMemberToCompany(
      int memberId, int companyId, int? cardVariantId) async {
    await Supabase.instance.client
        .from('mp_customers_info_table')
        .update({'company_id': companyId}).eq('id', memberId);

    if (cardVariantId != null) {
      final cards = await Supabase.instance.client
          .from('mp_card_table')
          .select('card_id')
          .eq('customer_id', memberId);

      for (final card in cards) {
        await Supabase.instance.client
            .from('mp_card_table')
            .update({'card_type': cardVariantId}).eq('card_id', card['card_id']);
      }
    }
  }

  Future<bool> _uploadMembersToCompany({
    required int companyId,
    required String companyName,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['csv', 'xls', 'xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/bulk_upload'),
      );

      request.headers.addAll({
        'supabase-url': supabaseUrl,
        'supabase-key': supabaseKey,
      });
      request.fields['company_id'] = companyId.toString();

      for (final file in result.files) {
        if (file.bytes == null) {
          _showMessage(
            'Unable to read file "${file.name}". Please try again.',
            'Upload Error',
          );
          return false;
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
          ),
        );
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final successes = body['successes'] ?? 0;
        final failures = (body['failures'] as List?) ?? [];

        final summary = failures.isEmpty
            ? '$successes members uploaded to $companyName.'
            : '$successes uploaded to $companyName, ${failures.length} failed.';
        _showMessage(summary, 'Bulk Upload Complete');
        await _fetchCompanies();
        ApiService.signalMembersUpdated();
        return true;
      }

      _showMessage(
        'Bulk upload failed (${response.statusCode}). ${response.body}',
        'Upload Error',
      );
      return false;
    } catch (e) {
      _showMessage('Failed to bulk upload members: $e', 'Upload Error');
      return false;
    }
  }

  Future<void> _downloadCompanyBulkTemplate({
    required String companyName,
    int? preferredCardTypeId,
  }) async {
    try {
      final cardTypeLegend = _resolveCardTypeLegend();
      final sampleCardTypeId = preferredCardTypeId ??
          (cardTypeLegend.isNotEmpty ? cardTypeLegend.keys.first : 1);
      final template = StringBuffer()
        ..writeln(
            'first_name,middle_name,last_name,contact_no,birth_date,card_number,card_type,type_id,enrollment_type_id,rb_id,rb_amount,lt_id,amount,email_address')
        ..writeln(
            'Juan,D,Delacruz,09171234567,1990-01-15,REPLACE_WITH_UNIQUE_CARD_NO,$sampleCardTypeId,2,1,1,1000,1,50000,replace.with.unique.email@example.com');

      final Uint8List csvBytes =
          Uint8List.fromList(utf8.encode(template.toString()));
      final sanitizedCompany = companyName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      final fileName = sanitizedCompany.isEmpty
          ? 'member_bulk_upload_template.csv'
          : '${sanitizedCompany}_member_bulk_upload_template.csv';

      if (kIsWeb) {
        final downloaded = downloadBytes(
          fileName: fileName,
          bytes: csvBytes,
          mimeType: 'text/csv;charset=utf-8',
        );

        if (!downloaded) {
          _showMessage(
            'Template download is not supported in this browser session.',
            'Download Failed',
          );
          return;
        }

        _showMessage(
          'Template downloaded: $fileName',
          'Template Ready',
        );
        return;
      }

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save bulk upload template',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: csvBytes,
      );

      if (savedPath == null) {
        return;
      }

      _showMessage(
        'Template saved to:\n$savedPath',
        'Template Ready',
      );
    } catch (e) {
      _showMessage('Failed to download template: $e', 'Download Failed');
    }
  }

  Map<int, String> _resolveCardTypeLegend() {
    final Map<int, String> legend = {};
    for (final variant in cardVariants) {
      final int? id = int.tryParse('${variant['card_variant_id'] ?? ''}');
      if (id == null) continue;
      final cardName = (variant['card_name'] ?? '').toString().trim();
      final cardVariant = (variant['card_variant'] ?? '').toString().trim();
      final label = cardVariant.isEmpty
          ? (cardName.isEmpty ? 'Card Type $id' : cardName)
          : (cardName.isEmpty ? cardVariant : '$cardName - $cardVariant');
      legend[id] = label;
    }

    if (legend.isEmpty) {
      legend.addAll(const {
        1: 'ER GUARD',
        2: 'ER GUARD PLUS',
        3: 'COMPREHENSIVE - REGULAR',
        4: 'COMPREHENSIVE - PSMBFI',
      });
    }

    final entries = legend.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map<int, String>.fromEntries(entries);
  }

  Widget _buildLegendSection({
    required String title,
    required List<String> entries,
    required double maxWidth,
  }) {
    final isNarrow = maxWidth < 680;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xff13322b),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries
              .map(
                (entry) => Container(
                  constraints: BoxConstraints(
                    maxWidth: isNarrow ? maxWidth - 36 : 340,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xff13322b).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xff13322b).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    entry,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff13322b),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBulkUploadLegend({
    required Map<String, dynamic> company,
  }) {
    final cardTypeLegend = _resolveCardTypeLegend();
    final companyCardTypeId =
        int.tryParse('${company['card_variant_id'] ?? ''}');
    final companyCardTypeName =
        companyCardTypeId != null ? cardTypeLegend[companyCardTypeId] : null;

    final memberTypeLegend =
        memberTypeItems.map((item) => '${item.id} = ${item.status}').toList();
    final enrollmentLegend = enrollmentTypeItems
        .map((item) => '${item.id} = ${item.status}')
        .toList();
    final roomBoardLegend = roomBoardTypeItems
        .map((item) => '${item.id} = ${item.status}')
        .toList();
    final cardTypeEntries = cardTypeLegend.entries
        .map((entry) => '${entry.key} = ${entry.value}')
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfff6fbf9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xffd0e2db)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bulk Upload Legend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff13322b),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Use these IDs in your CSV/XLSX columns. `card_type` maps to Card Design ID (`mp_card_variants_table.card_variant_id`).',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xff35524a),
                ),
              ),
              if (companyCardTypeId != null && companyCardTypeName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xff13322b),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'This company currently uses card_type=$companyCardTypeId ($companyCardTypeName)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _buildLegendSection(
                title: 'card_type (Card Design)',
                entries: cardTypeEntries,
                maxWidth: maxWidth,
              ),
              const SizedBox(height: 10),
              _buildLegendSection(
                title: 'type_id (Member Type)',
                entries: memberTypeLegend,
                maxWidth: maxWidth,
              ),
              const SizedBox(height: 10),
              _buildLegendSection(
                title: 'enrollment_type_id',
                entries: enrollmentLegend,
                maxWidth: maxWidth,
              ),
              const SizedBox(height: 10),
              _buildLegendSection(
                title: 'rb_id (Room & Board Type)',
                entries: roomBoardLegend,
                maxWidth: maxWidth,
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    if (value is Map) {
      return [Map<String, dynamic>.from(value)];
    }
    return <Map<String, dynamic>>[];
  }

  String _formatDate(dynamic rawValue) {
    final text = (rawValue ?? '').toString().trim();
    if (text.isEmpty) return 'N/A';
    if (text.length >= 10 && text[4] == '-' && text[7] == '-') {
      return text.substring(0, 10);
    }
    return text;
  }

  Future<Map<String, dynamic>> _fetchMemberFullDetails(int memberId) async {
    final response = await Supabase.instance.client
        .from('mp_customers_info_table')
        .select(
            '*, mp_customer_type_table(customer_type), mp_card_table(card_number, card_type, expiration_date, mp_card_variants_table(card_name, card_variant), mp_card_plan_table(card_id, plan_id, mp_plan_table(plan_status, limit_id, prb_id, mp_limit_table(lt_id, amount, mp_limit_type_table(limit_type)), mp_plan_room_boards_table(rb_id, rb_amount, mp_room_boards_table(room_boards)), enrollment_type_id, mp_enrollment_type_table(enrollment_type))))')
        .eq('id', memberId)
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchMemberLoaHistory(
      int memberId) async {
    final response = await Supabase.instance.client
        .from('mp_form_request_table')
        .select(
            'request_id, date_created, form_status, remarks, chief_complaint, diagnosis, location, cancel_reason, mp_form_type_table(form_type), mp_hospital_info_table(hospital_name), mp_doctors_appointment_table(date_schedule, time_schedule, mp_doctors_info_table(first_name, middle_name, last_name, mp_doctor_specialization_table(specialization)))')
        .eq('customer_id', memberId)
        .order('request_id', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> _fetchMemberDetailBundle(int memberId) async {
    final details = await _fetchMemberFullDetails(memberId);
    final loa = await _fetchMemberLoaHistory(memberId);
    return {
      'member': details,
      'loa': loa,
    };
  }

  TableRow _memberTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: const TextStyle(color: Colors.black),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberSection({
    required String title,
    required List<TableRow> rows,
  }) {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Table(
              border: const TableBorder(
                horizontalInside: BorderSide(color: Colors.grey),
                verticalInside: BorderSide.none,
                top: BorderSide(color: Colors.grey),
                bottom: BorderSide(color: Colors.grey),
              ),
              children: rows,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaHistorySection(List<Map<String, dynamic>> loaHistory) {
    if (loaHistory.isEmpty) {
      return Card(
        color: Colors.white,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LOA Request History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'No LOA requests found for this member.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    final rows = loaHistory.map((loa) {
      final formType = _asMap(loa['mp_form_type_table'])['form_type'] ?? 'N/A';
      final hospital =
          _asMap(loa['mp_hospital_info_table'])['hospital_name'] ?? 'N/A';
      final appointmentList = _asMapList(loa['mp_doctors_appointment_table']);
      final appointment = appointmentList.isNotEmpty
          ? appointmentList.first
          : <String, dynamic>{};
      final doctor = _asMap(appointment['mp_doctors_info_table']);
      final doctorFirst = (doctor['first_name'] ?? '').toString();
      final doctorLast = (doctor['last_name'] ?? '').toString();
      final doctorName = '$doctorLast, $doctorFirst'.trim();
      final scheduleDate = _formatDate(appointment['date_schedule']);
      final scheduleTime = (appointment['time_schedule'] ?? '').toString();

      return DataRow(
        cells: [
          DataCell(Text('${loa['request_id'] ?? 'N/A'}')),
          DataCell(Text(_formatDate(loa['date_created']))),
          DataCell(Text((formType ?? 'N/A').toString())),
          DataCell(Text((loa['form_status'] ?? 'N/A').toString())),
          DataCell(Text((hospital ?? 'N/A').toString())),
          DataCell(Text(doctorName.isEmpty ? 'N/A' : doctorName)),
          DataCell(Text(
            scheduleTime.isEmpty || scheduleTime == 'N/A'
                ? scheduleDate
                : '$scheduleDate $scheduleTime',
          )),
          DataCell(Text((loa['remarks'] ?? '').toString().isEmpty
              ? 'N/A'
              : (loa['remarks'] ?? '').toString())),
        ],
      );
    }).toList();

    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LOA Request History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xfff2f2f2)),
                columns: const [
                  DataColumn(label: Text('Request ID')),
                  DataColumn(label: Text('Date Created')),
                  DataColumn(label: Text('Form Type')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Hospital')),
                  DataColumn(label: Text('Doctor')),
                  DataColumn(label: Text('Schedule')),
                  DataColumn(label: Text('Remarks')),
                ],
                rows: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompanyMemberDetailsDialog(Map<String, dynamic> memberSummary) {
    final memberId = int.tryParse('${memberSummary['id'] ?? ''}');
    if (memberId == null) {
      _showMessage('Invalid member selected. Please refresh and try again.',
          'Member Details');
      return;
    }

    final memberFuture = _fetchMemberDetailBundle(memberId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Member Details',
            style: TextStyle(color: Colors.black),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9 > 900 ? 900 : MediaQuery.of(context).size.width * 0.9,
            child: FutureBuilder<Map<String, dynamic>>(
              future: memberFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 320,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff13322b),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(
                        'Failed to load member details: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final member =
                    Map<String, dynamic>.from(snapshot.data!['member'] ?? {});
                final loaHistory = List<Map<String, dynamic>>.from(
                  snapshot.data!['loa'] ?? <Map<String, dynamic>>[],
                );

                final customerType =
                    _asMap(member['mp_customer_type_table'])['customer_type'] ??
                        'N/A';
                final cards = _asMapList(member['mp_card_table']);
                final selectedCard =
                    cards.isNotEmpty ? cards.first : <String, dynamic>{};
                final cardPlans =
                    _asMapList(selectedCard['mp_card_plan_table']);
                final planData = cardPlans.isNotEmpty
                    ? _asMap(cardPlans.first['mp_plan_table'])
                    : <String, dynamic>{};
                final limitData = _asMap(planData['mp_limit_table']);
                final roomBoardData =
                    _asMap(planData['mp_plan_room_boards_table']);
                final enrollmentType =
                    _asMap(planData['mp_enrollment_type_table'])[
                            'enrollment_type'] ??
                        'N/A';
                final limitType =
                    _asMap(limitData['mp_limit_type_table'])['limit_type'] ??
                        'N/A';
                final roomBoardType = _asMap(
                        roomBoardData['mp_room_boards_table'])['room_boards'] ??
                    'N/A';
                final cardType = _asMap(selectedCard['mp_card_variants_table'])[
                        'card_variant'] ??
                    _asMap(
                        selectedCard['mp_card_variants_table'])['card_name'] ??
                    'N/A';

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMemberSection(
                        title: 'Personal Details',
                        rows: [
                          _memberTableRow(
                              'First Name', '${member['first_name'] ?? 'N/A'}'),
                          _memberTableRow('Middle Name',
                              '${member['middle_name'] ?? 'N/A'}'),
                          _memberTableRow(
                              'Last Name', '${member['last_name'] ?? 'N/A'}'),
                          _memberTableRow('Contact Number',
                              '${member['contact_no'] ?? 'N/A'}'),
                          _memberTableRow('Email Address',
                              '${member['email_address'] ?? 'N/A'}'),
                          _memberTableRow('Sex', '${member['sex'] ?? 'N/A'}'),
                          _memberTableRow(
                              'Birthdate', _formatDate(member['birth_date'])),
                          _memberTableRow('Civil Status',
                              '${member['civil_status'] ?? 'N/A'}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMemberSection(
                        title: 'Address',
                        rows: [
                          _memberTableRow(
                              'House Address', '${member['address'] ?? 'N/A'}'),
                          _memberTableRow(
                              'Barangay', '${member['barangay'] ?? 'N/A'}'),
                          _memberTableRow('City', '${member['city'] ?? 'N/A'}'),
                          _memberTableRow(
                              'Province', '${member['province'] ?? 'N/A'}'),
                          _memberTableRow(
                              'Region', '${member['region'] ?? 'N/A'}'),
                          _memberTableRow('Postal Code',
                              '${member['postal_code'] ?? 'N/A'}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMemberSection(
                        title: 'Membership',
                        rows: [
                          _memberTableRow('Member Type', '$customerType'),
                          _memberTableRow('Enrollment Type', '$enrollmentType'),
                          _memberTableRow('Plan Type', '$limitType'),
                          _memberTableRow(
                              'Room and Board Type', '$roomBoardType'),
                          _memberTableRow('Room and Board Limit',
                              '${roomBoardData['rb_amount'] ?? 'N/A'}'),
                          _memberTableRow('Benefit Limit',
                              '${limitData['amount'] ?? 'N/A'}'),
                          _memberTableRow('Card Type', '$cardType'),
                          _memberTableRow('Card Number',
                              '${selectedCard['card_number'] ?? 'N/A'}'),
                          _memberTableRow('Card Validity',
                              '${selectedCard['expiration_date'] ?? 'N/A'}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLoaHistorySection(loaHistory),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCompanyMembersDialog(Map<String, dynamic> company) {
    final int? companyId = int.tryParse('${company['id'] ?? ''}');
    if (companyId == null) {
      _showMessage('Invalid company selected. Please refresh and try again.',
          'Open Company Failed');
      return;
    }
    final String companyName = (company['name'] ?? '').toString();
    final String cardName =
        (company['mp_card_variants_table']?['card_name'] ?? 'No Design')
            .toString();

    int currentPage = 0;
    int totalMembers = 0;

    Future<List<Map<String, dynamic>>> membersFuture =
        _fetchCompanyMembers(companyId, page: currentPage);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final int totalPages =
                totalMembers > 0 ? (totalMembers / _pageSize).ceil() : 1;

            void loadPage(int page) {
              currentPage = page;
              setDialogState(() {
                membersFuture = _fetchCompanyMembers(companyId, page: page);
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: const BorderSide(color: Color(0xff13322b), width: 2),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$companyName Members',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff13322b),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xff13322b)),
                    tooltip: 'Refresh members',
                    onPressed: () => loadPage(currentPage),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9 > 900 ? 900 : MediaQuery.of(context).size.width * 0.9,
                child: SizedBox(
                  height: 700,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulkUploadLegend(company: company),
                      const SizedBox(height: 12),
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: membersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff13322b),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Failed to load members: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            final members =
                                snapshot.data ?? <Map<String, dynamic>>[];

                            // Count total on first successful load
                            if (totalMembers == 0 && members.isNotEmpty) {
                              _countCompanyMembers(companyId).then((count) {
                                if (count > 0) {
                                  setDialogState(() => totalMembers = count);
                                }
                              });
                            }

                            if (members.isEmpty && currentPage == 0) {
                              return Center(
                                child: Text(
                                  'No members assigned to this company yet.',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              );
                            }

                            if (members.isEmpty && currentPage > 0) {
                              return Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      onPressed: () => loadPage(currentPage - 1),
                                    ),
                                    Text('Page $currentPage'),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getCardDesignColor(cardName),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        cardName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${totalMembers > 0 ? totalMembers : members.length} members',
                                      style: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: members.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final member = members[index];
                                      final firstName =
                                          (member['first_name'] ?? '')
                                              .toString();
                                      final lastName =
                                          (member['last_name'] ?? '')
                                              .toString();
                                      final middleName =
                                          (member['middle_name'] ?? '')
                                              .toString();
                                      final fullName =
                                          '$lastName, $firstName ${middleName.isEmpty ? '' : middleName[0]}'
                                              .trim();
                                      final isActive =
                                          member['is_active'] == true;

                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              const Color(0xff13322b),
                                          child: Text(
                                            '${index + 1 + (currentPage * _pageSize)}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11),
                                          ),
                                        ),
                                        title: Text(
                                          fullName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${member['email_address'] ?? ''} • ${member['contact_no'] ?? ''}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.green.shade50
                                                : Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isActive
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                        onTap: () =>
                                            _showCompanyMemberDetailsDialog(member),
                                      );
                                    },
                                  ),
                                ),
                                // Pagination controls
                                if (totalPages > 1) ...[
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.first_page),
                                        onPressed: currentPage > 0
                                            ? () => loadPage(0)
                                            : null,
                                        tooltip: 'First page',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back_ios),
                                        onPressed: currentPage > 0
                                            ? () => loadPage(currentPage - 1)
                                            : null,
                                        tooltip: 'Previous page',
                                      ),
                                      Text(
                                        'Page ${currentPage + 1} of $totalPages',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xff13322b),
                                        ),
                                      ),
                                      IconButton(
                                        icon:
                                            const Icon(Icons.arrow_forward_ios),
                                        onPressed:
                                            currentPage < totalPages - 1
                                                ? () => loadPage(currentPage + 1)
                                                : null,
                                        tooltip: 'Next page',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.last_page),
                                        onPressed: currentPage < totalPages - 1
                                            ? () => loadPage(totalPages - 1)
                                            : null,
                                        tooltip: 'Last page',
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 35,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _downloadCompanyBulkTemplate(
                            companyName: companyName,
                            preferredCardTypeId:
                                int.tryParse('${company['card_variant_id'] ?? ''}'),
                          );
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download Template'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff13322b),
                          side: const BorderSide(color: Color(0xff13322b)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      height: 35,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _uploadMembersToCompany(
                            companyId: companyId,
                            companyName: companyName,
                          );
                          if (context.mounted) {
                            setDialogState(() {
                              currentPage = 0;
                              totalMembers = 0;
                              membersFuture =
                                  _fetchCompanyMembers(companyId, page: 0);
                            });
                          }
                        },
                        icon: const Icon(Icons.upload, size: 16),
                        label: const Text('Bulk Upload'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff13322b),
                          side: const BorderSide(color: Color(0xff13322b)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      height: 35,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddExistingMemberDialog(
                          companyId: companyId,
                          companyName: companyName,
                          onMemberAdded: () {
                            setDialogState(() {
                              currentPage = 0;
                              totalMembers = 0;
                              membersFuture =
                                  _fetchCompanyMembers(companyId, page: 0);
                            });
                          },
                        ),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Add Existing Member'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff13322b),
                          side: const BorderSide(color: Color(0xff13322b)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          backgroundColor: const Color(0xff13322b),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddExistingMemberDialog({
    required int companyId,
    required String companyName,
    int? cardVariantId,
    VoidCallback? onMemberAdded,
  }) async {
    String searchQuery = '';
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    final searchController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: const BorderSide(color: Color(0xff13322b), width: 2),
              ),
              title: Text(
                'Add Member to $companyName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff13322b),
                ),
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by name, email, or contact',
                        hintText: 'Type to search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) async {
                        searchQuery = value.trim();
                        if (searchQuery.length < 2) {
                          setDialogState(() {
                            searchResults = [];
                            isSearching = false;
                          });
                          return;
                        }
                        setDialogState(() => isSearching = true);
                        try {
                          final results = await _searchMembersNotInCompany(
                              companyId, searchQuery);
                          setDialogState(() {
                            searchResults = results;
                            isSearching = false;
                          });
                        } catch (e) {
                          setDialogState(() => isSearching = false);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: isSearching
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xff13322b)),
                            )
                          : searchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    searchQuery.length < 2
                                        ? 'Type at least 2 characters to search.'
                                        : 'No unassigned members found.',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: searchResults.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final member = searchResults[index];
                                    final firstName =
                                        (member['first_name'] ?? '')
                                            .toString();
                                    final lastName =
                                        (member['last_name'] ?? '')
                                            .toString();
                                    final middleName =
                                        (member['middle_name'] ?? '')
                                            .toString();
                                    final fullName =
                                        '$lastName, $firstName ${middleName.isNotEmpty ? middleName[0] : ''}'
                                            .trim();
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        fullName,
                                        style: const TextStyle(
                                          color: Color(0xff13322b),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${member['email_address'] ?? 'No email'} | ${member['contact_no'] ?? 'No contact'}',
                                        style:
                                            const TextStyle(fontSize: 12),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Color(0xff13322b)),
                                        tooltip: 'Assign to company',
                                        onPressed: () async {
                                          try {
                                            await _assignMemberToCompany(
                                                member['id'], companyId, cardVariantId);
                                            setDialogState(() {
                                              searchResults.removeAt(index);
                                            });
                                            onMemberAdded?.call();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  backgroundColor:
                                                      const Color(0xff13322b),
                                                  content: Text(
                                                      '$fullName added to $companyName.'),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  backgroundColor:
                                                      Colors.red.shade700,
                                                  content: Text(
                                                      'Failed to assign member: $e'),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff13322b),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    searchController.dispose();
  }

  void _showMessage(String message, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(color: Color(0xff13322b), width: 2),
          ),
          title: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xff13322b),
              ),
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xff13322b)),
          ),
          actions: [
            Center(
              child: SizedBox(
                width: 100,
                height: 35,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: const BorderSide(color: Color(0xff13322b)),
                    ),
                    backgroundColor: const Color(0xff13322b),
                  ),
                  child:
                      const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddCompanyDialog() {
    companyNameController.clear();
    selectedCardVariantId = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: const BorderSide(color: Color(0xff13322b), width: 2),
              ),
              title: const Center(
                child: Text(
                  'Add New Company',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff13322b),
                  ),
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Company Name',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xff13322b))),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: companyNameController,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter company name',
                        hintStyle: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xff13322b)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('Card Design',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xff13322b))),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final int? createdVariantId =
                                await _showAddCardDesignDialog();
                            if (!mounted) return;
                            if (createdVariantId != null) {
                              setDialogState(() {
                                selectedCardVariantId = createdVariantId;
                              });
                            }
                          },
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: Color(0xff13322b),
                          ),
                          label: const Text(
                            'Add Design',
                            style: TextStyle(
                              color: Color(0xff13322b),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: selectedCardVariantId,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Select card design',
                        hintStyle: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xff13322b)),
                        ),
                      ),
                      items: cardVariants.map((variant) {
                        return DropdownMenuItem<int>(
                          value: variant['card_variant_id'],
                          child: Text(
                            variant['card_name'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCardVariantId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(color: Color(0xff13322b)),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: _addCompany,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          backgroundColor: const Color(0xff13322b),
                        ),
                        child: const Text('Add',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCardDesignDialog(Map<String, dynamic> company) {
    int? editCardVariantId = company['card_variant_id'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: const BorderSide(color: Color(0xff13322b), width: 2),
              ),
              title: Center(
                child: Text(
                  'Edit Card Design - ${company['name']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff13322b),
                  ),
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Card Design',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xff13322b))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: editCardVariantId,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xff13322b)),
                        ),
                      ),
                      items: cardVariants.map((variant) {
                        return DropdownMenuItem<int>(
                          value: variant['card_variant_id'],
                          child: Text(
                            variant['card_name'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          editCardVariantId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(color: Color(0xff13322b)),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () {
                          if (editCardVariantId != null) {
                            Navigator.of(context).pop();
                            _updateCompanyCardDesign(
                                company['id'], editCardVariantId!);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          backgroundColor: const Color(0xff13322b),
                        ),
                        child: const Text('Save',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final cardVariantData = company['mp_card_variants_table'];
    final cardName = cardVariantData?['card_name'] ?? 'No Design';

    return FutureBuilder<int>(
      future: _getMemberCount(company['id']),
      builder: (context, snapshot) {
        final memberCount = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () => _showCompanyMembersDialog(company),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Company icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xff13322b).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Color(0xff13322b),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Company details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Roboto-M',
                            color: Color(0xff13322b),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCardDesignColor(cardName),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cardName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$memberCount members',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.groups_outlined,
                            color: Color(0xff13322b)),
                        tooltip: 'View Members',
                        onPressed: () => _showCompanyMembersDialog(company),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xff13322b)),
                        tooltip: 'Edit Card Design',
                        onPressed: () => _showEditCardDesignDialog(company),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete Company',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                side: const BorderSide(
                                    color: Color(0xff13322b), width: 2),
                              ),
                              title: const Center(
                                child: Text('Confirm Delete',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff13322b),
                                    )),
                              ),
                              content: Text(
                                'Are you sure you want to delete "${company['name']}"?',
                                style:
                                    const TextStyle(color: Color(0xff13322b)),
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      height: 35,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            side: const BorderSide(
                                                color: Color(0xff13322b)),
                                          ),
                                          backgroundColor: Colors.white,
                                        ),
                                        child: const Text('Cancel',
                                            style:
                                                TextStyle(color: Colors.black)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 100,
                                      height: 35,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          _deleteCompany(company['id']);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCardDesignColor(String cardName) {
    switch (cardName.toUpperCase()) {
      case 'ER GUARD':
        return const Color(0xFFE53935);
      case 'ER GUARD PLUS':
        return const Color(0xFFFF6F00);
      case 'REGULAR':
        return const Color(0xFF1565C0);
      case 'PSMBFI':
        return const Color(0xff13322b);
      default:
        return _getGeneratedCardColor(cardName);
    }
  }

  Color _getGeneratedCardColor(String seed) {
    if (seed.isEmpty) {
      return Colors.grey;
    }
    final hash = seed.toUpperCase().codeUnits.fold<int>(
          0,
          (previousValue, element) => previousValue * 31 + element,
        );
    final hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.52, 0.42).toColor();
  }

  void _showCardDesignPreview({
    required int cardVariantId,
    required String cardName,
    required String cardVariant,
    required int companiesWithVariant,
    required Color accentColor,
    String? imageUrl,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(color: Color(0xff13322b), width: 2),
          ),
          title: const Center(
            child: Text(
              'Card Design Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xff13322b),
              ),
            ),
          ),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 250,
                    color: accentColor.withValues(alpha: 0.12),
                    child: imageUrl == null
                        ? Icon(
                            Icons.credit_card,
                            color: accentColor,
                            size: 84,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Icon(
                                Icons.credit_card,
                                color: accentColor,
                                size: 84,
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  cardName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontFamily: 'Roboto-M',
                    color: Color(0xff13322b),
                  ),
                ),
                if (cardVariant.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    cardVariant,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xff13322b),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '$companiesWithVariant companies',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 35,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _showUpdateCardDesignDialog(
                        cardVariantId: cardVariantId,
                        initialCardName: cardName,
                        initialCardVariant: cardVariant,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xff13322b)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'Update Design',
                      style: TextStyle(color: Color(0xff13322b)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      backgroundColor: const Color(0xff13322b),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUpdateCardDesignDialog({
    required int cardVariantId,
    required String initialCardName,
    required String initialCardVariant,
  }) async {
    final cardNameController = TextEditingController(text: initialCardName);
    final cardVariantController =
        TextEditingController(text: initialCardVariant);
    PlatformFile? selectedDesignFile;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleUpdateCardDesign() async {
              final cardName = cardNameController.text.trim();
              final cardVariantInput = cardVariantController.text.trim();
              final cardVariant =
                  cardVariantInput.isEmpty ? cardName : cardVariantInput;

              if (cardName.isEmpty) {
                _showMessage(
                    'Card design name is required.', 'Missing Information');
                return;
              }

              try {
                setDialogState(() => isSaving = true);
                await _updateCardDesign(
                  cardVariantId: cardVariantId,
                  cardName: cardName,
                  cardVariant: cardVariant,
                  imageFile: selectedDesignFile,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                _showMessage(
                    'Card design has been updated successfully.', 'Updated');
                await Future.wait([
                  _fetchCardVariants(),
                  _fetchCardDesignImageUrls(),
                  _fetchCompanies(),
                ]);
              } catch (e) {
                if (!context.mounted) return;
                setDialogState(() => isSaving = false);
                _showMessage('Failed to update card design: $e', 'Error');
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: const BorderSide(color: Color(0xff13322b), width: 2),
              ),
              title: const Center(
                child: Text(
                  'Update Card Design',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff13322b),
                  ),
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Card Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff13322b),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: cardNameController,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'e.g. PREMIER PLUS',
                        hintStyle: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xff13322b)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Card Variant (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff13322b),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: cardVariantController,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'e.g. COMPREHENSIVE - PREMIER PLUS',
                        hintStyle: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xff13322b)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Replace Design Image (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff13322b),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xff13322b)
                                    .withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedDesignFile?.name ??
                                  'No new image selected',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selectedDesignFile == null
                                    ? Colors.black.withValues(alpha: 0.6)
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final result =
                                        await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: [
                                        'png',
                                        'jpg',
                                        'jpeg',
                                        'webp'
                                      ],
                                      withData: true,
                                    );
                                    if (result == null ||
                                        result.files.isEmpty) {
                                      return;
                                    }
                                    setDialogState(() {
                                      selectedDesignFile = result.files.first;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xff13322b),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Upload',
                              style: TextStyle(color: Color(0xff13322b)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 35,
                      child: ElevatedButton(
                        onPressed:
                            isSaving ? null : () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(color: Color(0xff13322b)),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : handleUpdateCardDesign,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          backgroundColor: const Color(0xff13322b),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    cardNameController.dispose();
    cardVariantController.dispose();
  }

  Widget _buildCardVariantSummary() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: cardVariants.map((variant) {
        final variantName = variant['card_name'] ?? '';
        final variantDescription = (variant['card_variant'] ?? '').toString();
        final variantId = int.tryParse('${variant['card_variant_id'] ?? ''}');
        final imageUrl =
            variantId == null ? null : cardVariantImageUrls[variantId];
        final companiesWithVariant = companies
            .where((c) =>
                int.tryParse('${c['card_variant_id'] ?? ''}') == variantId)
            .length;
        final accentColor = _getCardDesignColor(variantName);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (variantId == null) {
                _showMessage('Card design ID is missing for this entry.',
                    'Invalid Card Design');
                return;
              }
              _showCardDesignPreview(
                cardVariantId: variantId,
                cardName: variantName,
                cardVariant: variantDescription,
                companiesWithVariant: companiesWithVariant,
                accentColor: accentColor,
                imageUrl: imageUrl,
              );
            },
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl == null
                        ? const Icon(Icons.credit_card,
                            color: Colors.white, size: 20)
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Icon(Icons.credit_card,
                                  color: Colors.white, size: 20);
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    variantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Roboto-M',
                      color: Color(0xff13322b),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$companiesWithVariant companies',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        toolbarHeight: 140,
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    'Health Card Management',
                    style: TextStyle(
                      color: Color(0xff222222),
                      fontFamily: 'Roboto-M',
                      fontSize: 32,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Company',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff13322b),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _showAddCompanyDialog,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 2, color: Color(0XFFB6B6B6)),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xff13322b),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Design Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Card Designs',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Roboto-M',
                            color: Color(0xff13322b),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _showAddCardDesignDialog();
                            if (!mounted) return;
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: Color(0xff13322b),
                          ),
                          label: const Text(
                            'Add Card Design',
                            style: TextStyle(
                              color: Color(0xff13322b),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xff13322b)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCardVariantSummary(),
                    const SizedBox(height: 32),

                    // Companies List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Companies (${companies.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'Roboto-M',
                            color: Color(0xff13322b),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Color(0xff13322b)),
                          tooltip: 'Refresh',
                          onPressed: _fetchData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    companies.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.business_outlined,
                                    size: 60, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No companies added yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Click "Add Company" to get started',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: companies
                                .map((c) => _buildCompanyCard(c))
                                .toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
