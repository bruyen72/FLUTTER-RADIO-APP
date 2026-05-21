import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import 'usuario_form_screen.dart';

class UsuarioListaScreen extends StatefulWidget {
  const UsuarioListaScreen({super.key});

  @override
  State<UsuarioListaScreen> createState() => _UsuarioListaScreenState();
}

class _UsuarioListaScreenState extends State<UsuarioListaScreen> {
  List<Usuario> _lista    = [];
  List<Usuario> _filtrada = [];
  bool _loading  = true;
  bool _isAdmin  = false;
  final _buscaCtrl = TextEditingController();

  // ── LÓGICA INTACTA ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      AuthService.getProfile(),
      UsuarioService.listar(),
    ]);
    if (mounted) {
      setState(() {
        _isAdmin = (results[0] as Usuario?)?.isAdmin ?? false;
        _lista   = results[1] as List<Usuario>;
        _loading = false;
      });
      _filtrar();
    }
  }

  void _filtrar() {
    final q = _buscaCtrl.text.toLowerCase();
    setState(() {
      _filtrada = q.isEmpty
          ? List.from(_lista)
          : _lista.where((u) =>
              u.nome.toLowerCase().contains(q) ||
              u.perfil.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _resetarSenha(Usuario u) async {
    final senhaCtrl = TextEditingController();
    bool obscure    = true;
    bool salvando   = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: kCardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.lock_reset, color: kPrimaryLight, size: 22),
            const SizedBox(width: 10),
            Flexible(child: Text('Resetar senha\n${u.nome}',
                style: const TextStyle(color: kTextColor, fontSize: 15, fontWeight: FontWeight.w700))),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Digite a nova senha para este usuário:',
                  style: TextStyle(color: kTextColor3, fontSize: 13)),
              const SizedBox(height: 14),
              TextFormField(
                controller: senhaCtrl,
                obscureText: obscure,
                style: const TextStyle(color: kTextColor, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Nova senha (mín. 6 caracteres)',
                  labelStyle: const TextStyle(color: kTextColor3, fontSize: 13),
                  filled: true,
                  fillColor: kBgColor,
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20, color: kTextColor3),
                    onPressed: () => setSt(() => obscure = !obscure),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: salvando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: kTextColor3)),
            ),
            ElevatedButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (senhaCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('A senha deve ter no mínimo 6 caracteres'),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      setSt(() => salvando = true);
                      try {
                        await UsuarioService.resetarSenha(u.id, senhaCtrl.text);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Senha de ${u.nome} resetada com sucesso!'),
                            backgroundColor: kPrimaryColor,
                          ));
                        }
                      } catch (e) {
                        setSt(() => salvando = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Erro: $e'),
                            backgroundColor: Colors.red.shade700,
                          ));
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: salvando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Resetar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    senhaCtrl.dispose();
  }

  Future<void> _deletarUsuario(Usuario u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.delete_forever, color: kColorCancelado, size: 42),
        title: const Text('Deletar Usuário',
            style: TextStyle(color: kTextColor, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        content: Text(
          'Deletar "${u.nome}" permanentemente?\n\nEsta ação não pode ser desfeita.',
          style: const TextStyle(color: kTextColor2, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: kTextColor3)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kColorCancelado,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Deletar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await UsuarioService.deletarUsuario(u.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${u.nome} foi deletado.'),
          backgroundColor: kColorCancelado,
        ));
        _carregar();
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('internet')) {
        _mostrarDialogInternet('deletar usuários');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _alternarAtivo(Usuario u) async {
    try {
      if (u.ativo) {
        await UsuarioService.desativar(u.id);
      } else {
        await UsuarioService.ativar(u.id);
      }
      _carregar();
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('internet_necessaria')) {
        _mostrarDialogInternet('ativar ou desativar usuários');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  void _mostrarDialogInternet(String acao) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 48),
        title: const Text(
          'Sem Conexão',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Para $acao é necessário estar conectado à internet ou Wi-Fi.\n\nConecte-se e tente novamente.',
          style: const TextStyle(color: kTextColor2, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── VISUAL ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text('Usuários'),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Bloqueia criação offline com dialog claro
                final conn = await Connectivity().checkConnectivity();
                if (conn.contains(ConnectivityResult.none)) {
                  if (mounted) _mostrarDialogInternet('criar usuários');
                  return;
                }
                if (!mounted) return;
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UsuarioFormScreen()));
                _carregar();
              },
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Novo Usuário', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : !_isAdmin
              ? _buildSemAcesso()
              : Column(
                  children: [
                    // ── Stats ──────────────────────────────────
                    _buildStats(),

                    // ── Busca ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: TextField(
                        controller: _buscaCtrl,
                        style: const TextStyle(color: kTextColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nome ou perfil...',
                          hintStyle: const TextStyle(color: kTextDim, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: kTextColor3, size: 20),
                          filled: true,
                          fillColor: kCardColor,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kBorderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                          ),
                        ),
                      ),
                    ),

                    // ── Lista ───────────────────────────────────
                    Expanded(
                      child: _filtrada.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_off_outlined, size: 48, color: kTextDim),
                                  const SizedBox(height: 12),
                                  const Text('Nenhum usuário encontrado',
                                      style: TextStyle(color: kTextColor3)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _carregar,
                              color: kPrimaryColor,
                              backgroundColor: kCardColor,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                                itemCount: _filtrada.length,
                                itemBuilder: (_, i) => _buildCard(_filtrada[i]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  // ── Acesso restrito ───────────────────────────────────────────
  Widget _buildSemAcesso() => Center(
    child: Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kColorCancelado.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lock_outline, size: 36, color: kColorCancelado),
          ),
          const SizedBox(height: 16),
          const Text('Acesso Restrito',
              style: TextStyle(color: kTextColor, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Apenas administradores podem gerenciar usuários.',
              style: TextStyle(color: kTextColor3, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  // ── Stats ─────────────────────────────────────────────────────
  Widget _buildStats() {
    final admins  = _lista.where((u) => u.perfil == 'admin').length;
    final tecnicos = _lista.where((u) => u.perfil == 'tecnico').length;
    final ativos  = _lista.where((u) => u.ativo).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        children: [
          _statCard('Total',    _lista.length, kPrimaryLight,   Icons.people_outline),
          const SizedBox(width: 8),
          _statCard('Admins',   admins,        kColorAndamento, Icons.admin_panel_settings_outlined),
          const SizedBox(width: 8),
          _statCard('Técnicos', tecnicos,      kColorAberto,    Icons.build_outlined),
          const SizedBox(width: 8),
          _statCard('Ativos',   ativos,        kColorConcluido, Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _statCard(String label, int valor, Color cor, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: cor, size: 16),
          const SizedBox(height: 4),
          Text('$valor', style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(
              color: cor.withOpacity(0.85), fontSize: 9, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );

  // ── Card de usuário ───────────────────────────────────────────
  Widget _buildCard(Usuario u) {
    final isAdmin = u.perfil == 'admin';
    final badgeColor = isAdmin ? kColorAndamento : kPrimaryLight;
    final inicial = u.nome.isNotEmpty ? u.nome[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: u.ativo
                    ? kPrimaryColor.withOpacity(0.18)
                    : kTextDim.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: u.ativo
                      ? kPrimaryColor.withOpacity(0.4)
                      : kBorderColor,
                ),
              ),
              child: Center(
                child: Text(inicial,
                    style: TextStyle(
                      color: u.ativo ? kPrimaryLight : kTextDim,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    )),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(u.nome,
                            style: const TextStyle(
                              color: kTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: badgeColor.withOpacity(0.3)),
                        ),
                        child: Text(u.perfil.toUpperCase(),
                            style: TextStyle(
                              color: badgeColor, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (u.email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.email_outlined, size: 11, color: kTextDim),
                      const SizedBox(width: 4),
                      Flexible(child: Text(u.email,
                          style: const TextStyle(color: kTextDim, fontSize: 11),
                          overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                  if (u.especialidade != null && u.especialidade!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(u.especialidade!,
                        style: const TextStyle(color: kTextColor3, fontSize: 12)),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: u.ativo
                          ? kColorConcluido.withOpacity(0.10)
                          : kTextDim.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      u.ativo ? 'Ativo' : 'Inativo',
                      style: TextStyle(
                        color: u.ativo ? kColorConcluido : kTextDim,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ações
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: kPrimaryLight,
                      tooltip: 'Editar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      onPressed: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => UsuarioFormScreen(usuario: u)));
                        _carregar();
                      },
                    ),
                    if (_isAdmin) ...[
                      IconButton(
                        icon: const Icon(Icons.lock_reset, size: 18),
                        color: kColorAndamento,
                        tooltip: 'Resetar senha',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: () => _resetarSenha(u),
                      ),
                      // Admin não pode ser deletado — apenas técnicos e outros perfis
                      if (u.perfil != 'admin')
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: kColorCancelado,
                          tooltip: 'Deletar usuário',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          onPressed: () => _deletarUsuario(u),
                        ),
                    ],
                  ],
                ),
                Switch(
                  value: u.ativo,
                  onChanged: (_) => _alternarAtivo(u),
                  activeColor: kPrimaryColor,
                  activeTrackColor: kPrimaryColor.withOpacity(0.3),
                  inactiveThumbColor: kTextDim,
                  inactiveTrackColor: kBorderColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
