import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../supabase_config.dart';
import '../models/cliente.dart';
import 'offline_service.dart';

class ClienteService {
  static Future<bool> _offline() async {
    final c = await Connectivity().checkConnectivity();
    return c.contains(ConnectivityResult.none);
  }

  static Future<List<Cliente>> listar({bool onlineOnly = false}) async {
    if (await _offline()) {
      try {
        final local = await OfflineService.getClientes();
        return local.map(Cliente.fromLocal).toList();
      } catch (_) {
        return [];
      }
    }
    try {
      final data  = await supabase.from('cliente').select().eq('ativo', true).order('nome');
      final lista = (data as List).map((e) => Cliente.fromJson(e)).toList();
      await OfflineService.salvarClientes(lista.map((c) => c.toLocal()).toList());
      return lista;
    } catch (_) {
      try {
        final local = await OfflineService.getClientes();
        return local.map(Cliente.fromLocal).toList();
      } catch (_) {
        return [];
      }
    }
  }

  static Future<Cliente?> buscarPorId(String id) async {
    if (await _offline()) {
      final todos = await OfflineService.getClientes();
      final found = todos.where((m) => m['id'] == id).toList();
      if (found.isEmpty) return null;
      return Cliente.fromLocal(found.first);
    }
    try {
      final data = await supabase.from('cliente').select().eq('id', id).maybeSingle();
      if (data == null) return null;
      return Cliente.fromJson(data);
    } catch (_) {
      final todos = await OfflineService.getClientes();
      final found = todos.where((m) => m['id'] == id).toList();
      if (found.isEmpty) return null;
      return Cliente.fromLocal(found.first);
    }
  }

  static Future<Cliente> criar(Map<String, dynamic> dados) async {
    final id    = const Uuid().v4();
    final agora = DateTime.now();
    final cliente = Cliente(
      id: id,
      nome: dados['nome'] as String,
      telefone: dados['telefone'] as String?,
      email: dados['email'] as String?,
      endereco: dados['endereco'] as String?,
      logradouro: dados['logradouro'] as String?,
      numeroComplemento: dados['numero_complemento'] as String?,
      bairro: dados['bairro'] as String?,
      cidade: dados['cidade'] as String?,
      uf: dados['uf'] as String?,
      criadoEm: agora,
      atualizadoEm: agora,
    );
    try {
      final res    = await supabase.from('cliente').insert({...dados, 'id': id}).select().single();
      final criado = Cliente.fromJson(res);
      // Salva com synced:1 pois já está no Supabase
      await OfflineService.salvarClientes([criado.toLocal()]);
      return criado;
    } catch (_) {
      await OfflineService.insertCliente(cliente.toLocal());
      await OfflineService.adicionarFila('cliente', 'INSERT', id, {...dados, 'id': id});
      return cliente;
    }
  }

  static Future<void> atualizar(String id, Map<String, dynamic> dados) async {
    final atualizadoEm = DateTime.now().toIso8601String();
    final dadosComData = {...dados, 'atualizado_em': atualizadoEm};
    // Salva localmente como pendente (synced:0)
    await OfflineService.updateCliente(id, dadosComData);
    try {
      await supabase.from('cliente').update(dadosComData).eq('id', id);
      // Sucesso: marca como sincronizado
      await OfflineService.updateCliente(id, {'atualizado_em': atualizadoEm}, synced: 1);
    } catch (_) {
      // Inclui atualizado_em no payload para o sync
      await OfflineService.adicionarFila('cliente', 'UPDATE', id, dadosComData);
    }
  }
}
