// lib/presentation/pages/admin/admin_users_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin/admin_dashboard_provider.dart';
import '../../../domain/entities/user_entity.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  // Controleur pour la barre de recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRole;

  // Options de filtrage par role
  final List<Map<String, String?>> _roleOptions = [
    {'label': 'Tous les roles', 'value': null},
    {'label': 'Client', 'value': 'CLIENT'},
    {'label': 'Restaurateur', 'value': 'RESTAURATEUR'},
    {'label': 'Admin', 'value': 'ADMIN'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Rafraichir la liste des utilisateurs
  void _refreshUsers() {
    ref.refresh(adminUsersProvider(_selectedRole));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Liste rafraichie'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_selectedRole));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Gestion des utilisateurs',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/admin-home'),
          tooltip: 'Retour au tableau de bord',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: 'Rafraichir la liste',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              context.go('/admin/users/create-restaurateur');
            },
            tooltip: 'Creer un restaurateur',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.orange.shade300,
          ),
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchAndFilters(),
          
          // Liste des utilisateurs
          Expanded(
            child: usersAsync.when(
              data: (users) {
                // Filtrage par recherche
                final filteredUsers = users.where((user) {
                  if (_searchQuery.isEmpty) return true;
                  final query = _searchQuery.toLowerCase().trim();
                  return user.nom.toLowerCase().contains(query) ||
                         user.telephone.contains(query);
                }).toList();

                if (users.isEmpty) {
                  return _buildEmptyState();
                }

                if (filteredUsers.isEmpty) {
                  return _buildEmptySearchResults();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(adminUsersProvider(_selectedRole));
                  },
                  color: Colors.orange.shade700,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _UserCard(
                        key: ValueKey(user.id),
                        user: user,
                        onUserChanged: () {
                          ref.refresh(adminUsersProvider(_selectedRole));
                        },
                        onUserDeleted: () {
                          ref.refresh(adminUsersProvider(_selectedRole));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Utilisateur supprime'),
                              duration: Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chargement des utilisateurs...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: $err',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _refreshUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Barre de recherche et filtres
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Champ de recherche
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.orange.shade400,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // Filtre par role
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: DropdownButtonFormField<String?>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Filtrer par role',
                      prefixIcon: Icon(Icons.filter_list),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    items: _roleOptions.map((option) {
                      return DropdownMenuItem<String?>(
                        value: option['value'],
                        child: Text(option['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                      ref.refresh(adminUsersProvider(_selectedRole));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton effacer le filtre
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: _selectedRole != null 
                        ? Colors.orange.shade700 
                        : Colors.grey.shade400,
                  ),
                  onPressed: _selectedRole != null
                      ? () {
                          setState(() {
                            _selectedRole = null;
                          });
                          ref.refresh(adminUsersProvider(null));
                        }
                      : null,
                  tooltip: 'Effacer le filtre',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Etat vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people,
              size: 50,
              color: Colors.orange.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun utilisateur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les utilisateurs apparaitront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Resultats de recherche vides
  Widget _buildEmptySearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun utilisateur trouve',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez une autre recherche ou modifiez les filtres',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedRole = null;
              });
              ref.refresh(adminUsersProvider(null));
            },
            icon: Icon(Icons.clear, color: Colors.orange.shade700),
            label: Text(
              'Effacer les filtres',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== CARTE D'UN UTILISATEUR =====
class _UserCard extends ConsumerStatefulWidget {
  final UserEntity user;
  final VoidCallback onUserChanged;
  final VoidCallback onUserDeleted;

  const _UserCard({
    super.key,
    required this.user,
    required this.onUserChanged,
    required this.onUserDeleted,
  });

  @override
  ConsumerState<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<_UserCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isAdmin = user.role == 'ADMIN';
    final roleColor = _getRoleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: roleColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            
            // Informations utilisateur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.telephone,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Badge de role
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: roleColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRoleIcon(user.role),
                          size: 14,
                          color: roleColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getRoleLabel(user.role),
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            if (!isAdmin)
              PopupMenuButton<String>(
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade600,
                      ),
                tooltip: 'Actions',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _deleteUser(context);
                  } else if (value == 'edit') {
                    await _showEditDialog(context);
                  } else if (value.startsWith('role_')) {
                    final newRole = value.replaceFirst('role_', '');
                    await _changeUserRole(context, newRole);
                  }
                },
                itemBuilder: (context) => [
                  // Modifier
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  // Changer le role
                  const PopupMenuItem(
                    value: 'role_CLIENT',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Changer en Client'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'role_RESTAURATEUR',
                    child: Row(
                      children: [
                        Icon(Icons.restaurant_outlined, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Changer en Restaurateur'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'role_ADMIN',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Changer en Admin'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // Supprimer
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outlined, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.red.shade700,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Couleur du role
  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.red.shade700;
      case 'RESTAURATEUR':
        return Colors.orange.shade700;
      case 'CLIENT':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  // Icone du role
  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'RESTAURATEUR':
        return Icons.restaurant;
      case 'CLIENT':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  // Libelle du role
  String _getRoleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrateur';
      case 'RESTAURATEUR':
        return 'Restaurateur';
      case 'CLIENT':
        return 'Client';
      default:
        return role;
    }
  }

  // Dialogue de modification
  Future<void> _showEditDialog(BuildContext context) async {
    final user = widget.user;
    final nomController = TextEditingController(text: user.nom);
    final telephoneController = TextEditingController(text: user.telephone);
    String selectedRole = user.role;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text('Modifier l\'utilisateur'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  TextField(
                    controller: nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Telephone
                  TextField(
                    controller: telephoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telephone *',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  // Role
                  const Text(
                    'Role',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildRoleRadio(
                          context,
                          value: 'CLIENT',
                          groupValue: selectedRole,
                          onChanged: (v) => setStateDialog(() => selectedRole = v!),
                          icon: Icons.person_outline,
                          color: Colors.blue.shade700,
                        ),
                        _buildRoleRadio(
                          context,
                          value: 'RESTAURATEUR',
                          groupValue: selectedRole,
                          onChanged: (v) => setStateDialog(() => selectedRole = v!),
                          icon: Icons.restaurant_outlined,
                          color: Colors.orange.shade700,
                        ),
                        _buildRoleRadio(
                          context,
                          value: 'ADMIN',
                          groupValue: selectedRole,
                          onChanged: (v) => setStateDialog(() => selectedRole = v!),
                          icon: Icons.admin_panel_settings_outlined,
                          color: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final nom = nomController.text.trim();
                  final telephone = telephoneController.text.trim();

                  if (nom.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez entrer un nom'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (telephone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez entrer un numero de telephone'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  await _saveUserChanges(
                    context,
                    nom: nom,
                    telephone: telephone,
                    role: selectedRole,
                  );
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Radio button pour le role
  Widget _buildRoleRadio(
    BuildContext context, {
    required String value,
    required String groupValue,
    required void Function(String?) onChanged,
    required IconData icon,
    required Color color,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(_getRoleLabel(value)),
        ],
      ),
      activeColor: color,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // Sauvegarde des modifications
  Future<void> _saveUserChanges(
    BuildContext context, {
    required String nom,
    required String telephone,
    required String role,
  }) async {
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(adminRepositoryProvider);
      
      // Mettre a jour le nom et telephone
      await repo.updateUser(
        widget.user.id,
        nom: nom,
        telephone: telephone,
      );
      
      // Mettre a jour le role si different
      if (role != widget.user.role) {
        await repo.updateUserRole(widget.user.id, role);
      }
      
      widget.onUserChanged();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur modifie avec succes'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Changement de role seul
  Future<void> _changeUserRole(BuildContext context, String newRole) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updateUserRole(widget.user.id, newRole);
      widget.onUserChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role change en ${_getRoleLabel(newRole)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Suppression d'utilisateur
  Future<void> _deleteUser(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade400),
            const SizedBox(width: 8),
            const Text('Supprimer l\'utilisateur'),
          ],
        ),
        content: Text(
          'Etes-vous sur de vouloir supprimer "${widget.user.nom}" ?\n\n'
          'Cette action est irreversible.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.deleteUser(widget.user.id);
      widget.onUserDeleted();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur supprime avec succes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}