import 'package:flutter/material.dart';
import '../services/hubspot_service.dart';

class HelpCenterView extends StatefulWidget {
  const HelpCenterView({super.key});

  @override
  State<HelpCenterView> createState() => _HelpCenterViewState();
}

class _HelpCenterViewState extends State<HelpCenterView> {
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

  List<Map<String, String>> get _filteredArticles {
    final articles = HubSpotService.getHelpArticles();
    
    return articles.where((article) {
      // Filtre par catégorie
      if (_selectedCategory != 'Tous' && article['category'] != _selectedCategory) {
        return false;
      }
      // Filtre par recherche
      if (_searchQuery.isNotEmpty) {
        final title = article['title']!.toLowerCase();
        final content = article['content']!.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || content.contains(query);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final articles = _filteredArticles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre d\'aide'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Bannière HubSpot
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 4)],
                  ),
                  child: const Icon(Icons.support_agent, color: Color(0xFF1E3A8A), size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Base de connaissances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      SizedBox(height: 4),
                      Text('Propulsé par HubSpot Ticketing API', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('API en ligne', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher une solution...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
                    : null,
              ),
            ),
          ),

          // Catégories
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('Tous', _selectedCategory == 'Tous'),
                _buildCategoryChip('Matériel', _selectedCategory == 'Matériel'),
                _buildCategoryChip('Réseau', _selectedCategory == 'Réseau'),
                _buildCategoryChip('Logiciel', _selectedCategory == 'Logiciel'),
                _buildCategoryChip('Compte', _selectedCategory == 'Compte'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Liste des articles
          Expanded(
            child: articles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Aucun article trouvé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Text('Essayez d\'autres mots-clés', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                            child: Icon(_getIconForCategory(article['category']!), color: const Color(0xFF1E3A8A), size: 24),
                          ),
                          title: Text(article['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(article['category']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () => _showArticleDetail(context, article),
                        ),
                      );
                    },
                  ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Données fournies par ', style: TextStyle(color: Colors.grey.shade600)),
                const Text('HubSpot', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                Text(' • Version 1.0.0', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedCategory = label),
        backgroundColor: Colors.grey.shade100,
        selectedColor: const Color(0xFFE3F2FD),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF1976D2) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Matériel': return Icons.computer;
      case 'Réseau': return Icons.wifi;
      case 'Logiciel': return Icons.code;
      case 'Compte': return Icons.person;
      default: return Icons.article;
    }
  }

  void _showArticleDetail(BuildContext context, Map<String, String> article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                    child: Icon(_getIconForCategory(article['category']!), color: const Color(0xFF1E3A8A), size: 32)),
                  const SizedBox(height: 16),
                  Text(article['title']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Text(article['category']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Solution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(article['content']!, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Fermer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}