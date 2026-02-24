import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/ticket_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/side_menu.dart';

class GlobalHistoryScreen extends StatefulWidget {
  const GlobalHistoryScreen({super.key});

  @override
  State<GlobalHistoryScreen> createState() => _GlobalHistoryScreenState();
}

class _GlobalHistoryScreenState extends State<GlobalHistoryScreen> {
  // Données
  List<Map<String, dynamic>> _allTickets = [];
  List<Map<String, dynamic>> _filteredTickets = [];
  bool _isLoading = true;
  bool _isExporting = false;

  // Filtres
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _statusFilter; // Filtre par statut

  // Liste des statuts disponibles
  static const List<String> _statusList = [
    'En attente',
    'Ouvert',
    'En cours',
    'Fermé',
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Chargement des tickets depuis Firestore
  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await TicketService.getAllTicketsForHistory();
      setState(() {
        _allTickets = tickets;
        _filteredTickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filtrage des tickets
  void _filterTickets() {
    setState(() {
      _filteredTickets = _allTickets.where((ticket) {
        // Recherche textuelle
        final searchText = _searchController.text.toLowerCase();
        final matchesSearch =
            searchText.isEmpty ||
            (ticket['id']?.toString().toLowerCase().contains(searchText) ??
                false) ||
            (ticket['titre']?.toString().toLowerCase().contains(searchText) ??
                false) ||
            (ticket['tech']?.toString().toLowerCase().contains(searchText) ??
                false) ||
            (ticket['user']?.toString().toLowerCase().contains(searchText) ??
                false);

        // Filtrage par date
        bool matchesDate = true;
        final ticketDate = ticket['dateRaw'] as DateTime?;
        if (ticketDate != null) {
          if (_startDate != null && ticketDate.isBefore(_startDate!)) {
            matchesDate = false;
          }
          if (_endDate != null &&
              ticketDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
            matchesDate = false;
          }
        }

        // Filtrage par statut
        bool matchesStatus =
            _statusFilter == null ||
            _statusFilter!.isEmpty ||
            ticket['status'] == _statusFilter;

        return matchesSearch && matchesDate && matchesStatus;
      }).toList();
    });
  }

  // Exportation PDF
  Future<void> _exportToPdf() async {
    if (_filteredTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune donnée à exporter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();

      // En-têtes du tableau
      final headers = [
        'ID',
        'Titre',
        'Demandeur',
        'Technicien',
        'Département',
        'Date',
        'Statut',
      ];

      // Données du tableau
      final data = _filteredTickets
          .map(
            (t) => [
              t['id']?.toString() ?? '',
              t['titre']?.toString() ?? '',
              t['userName']?.toString() ?? 'Inconnu',
              t['tech']?.toString() ?? '',
              t['user']?.toString() ?? '',
              t['date']?.toString() ?? '',
              t['status']?.toString() ?? '',
            ],
          )
          .toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Historique des Interventions - ONT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Exporté le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              pw.SizedBox(height: 10),
            ],
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue100,
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'historique_ont',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF généré avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur exportation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // Sélection de date de début
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _startDate = date);
      _filterTickets();
    }
  }

  // Sélection de date de fin
  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _endDate = date);
      _filterTickets();
    }
  }

  // Effacer les filtres
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _statusFilter = null;
      _filteredTickets = _allTickets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Row(
        children: [
          const SizedBox(width: 260, child: SideMenu(selectedIndex: 2)),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Archives des Interventions",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Consultez l'historique complet des problèmes résolus au sein de l'ONT. (${_filteredTickets.length} tickets)",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 30),
                              _buildFilterBar(),
                              const SizedBox(height: 20),
                              _buildHistoryTable(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.blueONT,
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off, color: Colors.white),
          const SizedBox(width: 10),
          const Text(
            "ARCHIVES CENTRALISÉES",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportToPdf,
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf, size: 18),
            label: Text(_isExporting ? 'Exportation...' : 'Exporter PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Rechercher par ID, Technicien ou Titre...",
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
              onChanged: (_) => _filterTickets(),
            ),
          ),
          Container(height: 30, width: 1, color: Colors.grey.shade200),
          const SizedBox(width: 15),
          // Filtre date début
          InkWell(
            onTap: _selectStartDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _startDate != null
                      ? AppColors.blueONT
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.blueONT,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Du',
                    style: TextStyle(
                      color: _startDate != null
                          ? AppColors.blueONT
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text('à', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 10),
          // Filtre date fin
          InkWell(
            onTap: _selectEndDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _endDate != null
                      ? AppColors.blueONT
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.blueONT,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Au',
                    style: TextStyle(
                      color: _endDate != null ? AppColors.blueONT : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Bouton effacer filtres
          if (_startDate != null ||
              _endDate != null ||
              _searchController.text.isNotEmpty)
            IconButton(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all, color: Colors.red),
              tooltip: 'Effacer les filtres',
            ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _loadTickets,
            icon: const Icon(Icons.refresh, color: AppColors.blueONT),
            tooltip: 'Actualiser',
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    if (_filteredTickets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 15),
              Text(
                _allTickets.isEmpty
                    ? 'Aucun ticket résolu trouvé'
                    : 'Aucun résultat pour les filtres sélectionnés',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header du tableau
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "ID",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "TITRE DU PROBLÈME",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "DEMANDEUR",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "TECHNICIEN",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "DATE",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "DÉPARTEMENT",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Liste des éléments
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredTickets.length,
            itemBuilder: (context, index) {
              final t = _filteredTickets[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        t['id'] ?? '',
                        style: const TextStyle(
                          color: AppColors.blueONT,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        t['titre'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        t['userName'] ?? 'Inconnu',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            child: Icon(Icons.person, size: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t['tech'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: Text(t['date'] ?? '')),
                    Expanded(
                      flex: 1,
                      child: Text(
                        t['user'] ?? 'Inconnu',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
