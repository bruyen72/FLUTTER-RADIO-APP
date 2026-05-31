import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../supabase_config.dart';
import '../models/equipamento.dart';
import 'offline_service.dart';

class EquipamentoService {
  static Future<bool> _offline() async {
    final c = await Connectivity().checkConnectivity();
    return c.contains(ConnectivityResult.none);
  }

  static Future<List<Equipamento>> listar({String? clienteId}) async {
    // Offline-first: SQLite instantâneo se sem internet
    if (await _offline()) {
      final local = await OfflineService.getEquipamentos(clienteId: clienteId);
      return local.map(Equipamento.fromLocal).toList();
    }
    try {
      var query = supabase.from('equipamento').select('*, cliente(nome)').eq('ativo', true);
      if (clienteId != null) query = query.eq('cliente_id', clienteId);
      final data  = await query.order('marca');
      final lista = (data as List).map((e) => Equipamento.fromJson(e)).toList();
      await OfflineService.salvarEquipamentos(lista.map((e) => e.toLocal()).toList());
      return lista;
    } catch (_) {
      final local = await OfflineService.getEquipamentos(clienteId: clienteId);
      return local.map(Equipamento.fromLocal).toList();
    }
  }

  static Future<Equipamento> criar(Map<String, dynamic> dados) async {
    final id    = const Uuid().v4();
    final agora = DateTime.now();
    final equip = Equipamento(
      id: id,
      tipo: dados['tipo'] as String,
      marca: dados['marca'] as String,
      modelo: dados['modelo'] as String,
      numeroSerie: dados['numero_serie'] as String,
      clienteId: dados['cliente_id'] as String,
      criadoEm: agora,
    );
    try {
      final res   = await supabase.from('equipamento').insert({...dados, 'id': id}).select().single();
      final criado = Equipamento.fromJson(res);
      await OfflineService.insertEquipamento(criado.toLocal());
      return criado;
    } catch (_) {
      await OfflineService.insertEquipamento(equip.toLocal());
      await OfflineService.adicionarFila('equipamento', 'INSERT', id, {...dados, 'id': id});
      return equip;
    }
  }

  static Future<void> atualizar(String id, Map<String, dynamic> dados) async {
    await OfflineService.updateEquipamento(id, dados);
    try {
      await supabase.from('equipamento').update(dados).eq('id', id);
    } catch (_) {
      await OfflineService.adicionarFila('equipamento', 'UPDATE', id, dados);
    }
  }

  static Future<void> desativar(String id) async {
    await OfflineService.updateEquipamento(id, {'ativo': 0});
    try {
      await supabase.from('equipamento').update({'ativo': false}).eq('id', id);
    } catch (_) {
      await OfflineService.adicionarFila('equipamento', 'UPDATE', id, {'ativo': false});
    }
  }

  static Future<void> deletar(String id) async {
    await OfflineService.deleteEquipamento(id);
    try {
      await supabase.from('equipamento').delete().eq('id', id);
    } catch (_) {
      await OfflineService.adicionarFila('equipamento', 'DELETE', id, {});
    }
  }
}
