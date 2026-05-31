import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class OfflineService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'survey_offline.db');
    return openDatabase(
      path,
      version: 12,
      onCreate: (db, v) async {
        await _criarTabelas(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute('CREATE TABLE IF NOT EXISTS profiles (id TEXT PRIMARY KEY, nome TEXT NOT NULL, perfil TEXT NOT NULL DEFAULT \'tecnico\', especialidade TEXT, ativo INTEGER NOT NULL DEFAULT 1)');
          await db.execute('CREATE TABLE IF NOT EXISTS fotos_pendentes (id INTEGER PRIMARY KEY AUTOINCREMENT, os_id TEXT NOT NULL, file_path TEXT NOT NULL, criado_em INTEGER NOT NULL)');
        }
        if (oldV < 3) {
          await db.execute('CREATE TABLE IF NOT EXISTS os_checklist_local (id INTEGER PRIMARY KEY AUTOINCREMENT, os_id TEXT NOT NULL, item_id TEXT NOT NULL, item_nome TEXT NOT NULL, feito INTEGER NOT NULL DEFAULT 0, data_verificacao TEXT, tecnico_verificador TEXT)');
          await db.execute('CREATE TABLE IF NOT EXISTS os_acessorio_local (id INTEGER PRIMARY KEY AUTOINCREMENT, os_id TEXT NOT NULL, nome TEXT NOT NULL)');
        }
        if (oldV < 4) {
          await db.execute('CREATE TABLE IF NOT EXISTS os_assinatura_local (os_id TEXT PRIMARY KEY, sig_cliente TEXT, sig_tecnico TEXT)');
        }
        if (oldV < 5) {
          await db.execute('CREATE TABLE IF NOT EXISTS os_equipamento_local (os_id TEXT NOT NULL, equipamento_id TEXT NOT NULL, PRIMARY KEY (os_id, equipamento_id))');
        }
        if (oldV < 6) {
          await db.execute('ALTER TABLE clientes ADD COLUMN logradouro TEXT');
          await db.execute('ALTER TABLE clientes ADD COLUMN numero_complemento TEXT');
          await db.execute('ALTER TABLE clientes ADD COLUMN bairro TEXT');
          await db.execute('ALTER TABLE clientes ADD COLUMN cidade TEXT');
          await db.execute('ALTER TABLE clientes ADD COLUMN uf TEXT');
        }
        if (oldV < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notificacoes_local (
              id TEXT PRIMARY KEY,
              usuario_id TEXT NOT NULL,
              os_id TEXT,
              mensagem TEXT NOT NULL,
              tipo TEXT NOT NULL DEFAULT 'info',
              lida INTEGER NOT NULL DEFAULT 0,
              criado_em TEXT NOT NULL
            )
          ''');
        }
        if (oldV < 8) {
          await db.execute('ALTER TABLE profiles ADD COLUMN email TEXT');
        }
        if (oldV < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS os_analise_equipamento (
              id TEXT PRIMARY KEY,
              os_id TEXT NOT NULL,
              tipo_equipamento TEXT NOT NULL DEFAULT '',
              id_nome TEXT NOT NULL DEFAULT '',
              modelo TEXT NOT NULL DEFAULT '',
              numero_serie TEXT NOT NULL DEFAULT '',
              tipo_antena TEXT NOT NULL DEFAULT '',
              altura_antena REAL NOT NULL DEFAULT 30.0,
              tipo_cabo TEXT NOT NULL DEFAULT '',
              compr_cabo REAL NOT NULL DEFAULT 40.0,
              freq_tx REAL NOT NULL DEFAULT 0.0,
              freq_rx REAL NOT NULL DEFAULT 0.0,
              potencia REAL NOT NULL DEFAULT 45.0,
              potencia_refletida REAL NOT NULL DEFAULT 0.5,
              roe_vswr TEXT NOT NULL DEFAULT '',
              possui_fonte_dedicada INTEGER NOT NULL DEFAULT 0,
              voltagem_fonte TEXT NOT NULL DEFAULT '',
              observacoes TEXT NOT NULL DEFAULT '',
              fotos TEXT NOT NULL DEFAULT '[]'
            )
          ''');
        }
        if (oldV < 10) {
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN criado_em TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN atualizado_em TEXT NOT NULL DEFAULT ''"); } catch (_) {}
        }
        // ── v11: Fotos por seção na OS + campos de rádio na análise ──
        if (oldV < 11) {
          // Fotos por seção na tabela de OS
          try { await db.execute("ALTER TABLE ordens_servico ADD COLUMN fotos_visita TEXT NOT NULL DEFAULT '[]'"); } catch (_) {}
          try { await db.execute("ALTER TABLE ordens_servico ADD COLUMN fotos_equipamento TEXT NOT NULL DEFAULT '[]'"); } catch (_) {}
          try { await db.execute("ALTER TABLE ordens_servico ADD COLUMN fotos_testes TEXT NOT NULL DEFAULT '[]'"); } catch (_) {}
          // Campos específicos de rádio na análise de equipamento
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN tipo_radio TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN marca_radio TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN faixa TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN firmware TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN condicoes_fisicas_radio TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN defeitos_relatados TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN acessorios_radio TEXT NOT NULL DEFAULT '[]'"); } catch (_) {}
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN solucao_proposta TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN laudo_tecnico_radio TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          try { await db.execute("ALTER TABLE os_analise_equipamento ADD COLUMN termos_garantia TEXT NOT NULL DEFAULT ''"); } catch (_) {}
        }
        // ── v12: Testes e Visita Técnica ─────────────────────────────
        if (oldV < 12) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS os_testes_local (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              os_id TEXT NOT NULL,
              item_id TEXT NOT NULL,
              item_nome TEXT NOT NULL,
              feito INTEGER NOT NULL DEFAULT 0,
              observacao TEXT NOT NULL DEFAULT '',
              data_verificacao TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS os_visita_local (
              id TEXT PRIMARY KEY,
              os_id TEXT NOT NULL,
              local_visita TEXT NOT NULL DEFAULT '',
              tecnico_responsavel TEXT NOT NULL DEFAULT '',
              data_hora TEXT NOT NULL DEFAULT '',
              descricao_problema TEXT NOT NULL DEFAULT '',
              equipamentos_encontrados TEXT NOT NULL DEFAULT '',
              fotos TEXT NOT NULL DEFAULT '[]',
              observacoes_campo TEXT NOT NULL DEFAULT '',
              status TEXT NOT NULL DEFAULT 'Em andamento',
              criado_em TEXT NOT NULL,
              atualizado_em TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
      },
    );
  }

  static Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE clientes (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        telefone TEXT,
        email TEXT,
        endereco TEXT,
        logradouro TEXT,
        numero_complemento TEXT,
        bairro TEXT,
        cidade TEXT,
        uf TEXT,
        ativo INTEGER NOT NULL DEFAULT 1,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE equipamentos (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        marca TEXT NOT NULL,
        modelo TEXT NOT NULL,
        numero_serie TEXT NOT NULL,
        cliente_id TEXT NOT NULL,
        cliente_nome TEXT,
        cor_identificacao TEXT,
        canal_frequencia TEXT,
        ativo INTEGER NOT NULL DEFAULT 1,
        criado_em TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE ordens_servico (
        id TEXT PRIMARY KEY,
        numero_os TEXT NOT NULL,
        descricao TEXT,
        status TEXT NOT NULL DEFAULT 'Aberto',
        prioridade TEXT NOT NULL DEFAULT 'Baixa',
        tipo_ocorrencia TEXT,
        data_entrada TEXT NOT NULL,
        hora_entrada TEXT,
        data_saida TEXT,
        acompanhante TEXT,
        condicoes_fisicas TEXT,
        defeito_relatado TEXT,
        status_equipamento TEXT,
        laudo_tecnico TEXT,
        solucao_aplicada TEXT,
        pecas_utilizadas TEXT,
        termos_observacoes TEXT,
        geo_lat REAL,
        geo_lng REAL,
        geo_endereco TEXT,
        ativo INTEGER NOT NULL DEFAULT 1,
        cliente_id TEXT NOT NULL,
        cliente_nome TEXT,
        tecnico_id TEXT,
        tecnico_nome TEXT,
        criado_por TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1,
        fotos_visita TEXT NOT NULL DEFAULT '[]',
        fotos_equipamento TEXT NOT NULL DEFAULT '[]',
        fotos_testes TEXT NOT NULL DEFAULT '[]'
      )
    ''');
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        email TEXT,
        perfil TEXT NOT NULL DEFAULT 'tecnico',
        especialidade TEXT,
        ativo INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE fotos_pendentes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        os_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        criado_em INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE os_assinatura_local (
        os_id TEXT PRIMARY KEY,
        sig_cliente TEXT,
        sig_tecnico TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE os_checklist_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        os_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_nome TEXT NOT NULL,
        feito INTEGER NOT NULL DEFAULT 0,
        data_verificacao TEXT,
        tecnico_verificador TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE os_acessorio_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        os_id TEXT NOT NULL,
        nome TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE os_equipamento_local (
        os_id TEXT NOT NULL,
        equipamento_id TEXT NOT NULL,
        PRIMARY KEY (os_id, equipamento_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE notificacoes_local (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        os_id TEXT,
        mensagem TEXT NOT NULL,
        tipo TEXT NOT NULL DEFAULT 'info',
        lida INTEGER NOT NULL DEFAULT 0,
        criado_em TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tabela TEXT NOT NULL,
        operacao TEXT NOT NULL,
        registro_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        criado_em INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE os_analise_equipamento (
        id TEXT PRIMARY KEY,
        os_id TEXT NOT NULL,
        tipo_equipamento TEXT NOT NULL DEFAULT '',
        id_nome TEXT NOT NULL DEFAULT '',
        modelo TEXT NOT NULL DEFAULT '',
        numero_serie TEXT NOT NULL DEFAULT '',
        tipo_radio TEXT NOT NULL DEFAULT '',
        marca_radio TEXT NOT NULL DEFAULT '',
        faixa TEXT NOT NULL DEFAULT '',
        firmware TEXT NOT NULL DEFAULT '',
        condicoes_fisicas_radio TEXT NOT NULL DEFAULT '',
        defeitos_relatados TEXT NOT NULL DEFAULT '',
        acessorios_radio TEXT NOT NULL DEFAULT '[]',
        solucao_proposta TEXT NOT NULL DEFAULT '',
        laudo_tecnico_radio TEXT NOT NULL DEFAULT '',
        termos_garantia TEXT NOT NULL DEFAULT '',
        tipo_antena TEXT NOT NULL DEFAULT '',
        altura_antena REAL NOT NULL DEFAULT 30.0,
        tipo_cabo TEXT NOT NULL DEFAULT '',
        compr_cabo REAL NOT NULL DEFAULT 40.0,
        freq_tx REAL NOT NULL DEFAULT 0.0,
        freq_rx REAL NOT NULL DEFAULT 0.0,
        potencia REAL NOT NULL DEFAULT 45.0,
        potencia_refletida REAL NOT NULL DEFAULT 0.5,
        roe_vswr TEXT NOT NULL DEFAULT '',
        possui_fonte_dedicada INTEGER NOT NULL DEFAULT 0,
        voltagem_fonte TEXT NOT NULL DEFAULT '',
        observacoes TEXT NOT NULL DEFAULT '',
        fotos TEXT NOT NULL DEFAULT '[]',
        criado_em TEXT NOT NULL DEFAULT '',
        atualizado_em TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE os_testes_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        os_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_nome TEXT NOT NULL,
        feito INTEGER NOT NULL DEFAULT 0,
        observacao TEXT NOT NULL DEFAULT '',
        data_verificacao TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE os_visita_local (
        id TEXT PRIMARY KEY,
        os_id TEXT NOT NULL,
        local_visita TEXT NOT NULL DEFAULT '',
        tecnico_responsavel TEXT NOT NULL DEFAULT '',
        data_hora TEXT NOT NULL DEFAULT '',
        descricao_problema TEXT NOT NULL DEFAULT '',
        equipamentos_encontrados TEXT NOT NULL DEFAULT '',
        fotos TEXT NOT NULL DEFAULT '[]',
        observacoes_campo TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'Em andamento',
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ── Notificações local ───────────────────────────────────
  static Future<void> salvarNotificacoes(List<Map<String, dynamic>> lista) async {
    final database = await db;
    final batch = database.batch();
    for (final n in lista) {
      batch.insert('notificacoes_local', {
        'id':         n['id'],
        'usuario_id': n['usuario_id'],
        'os_id':      n['os_id'],
        'mensagem':   n['mensagem'],
        'tipo':       n['tipo'] ?? 'info',
        'lida':       (n['lida'] == true || n['lida'] == 1) ? 1 : 0,
        'criado_em':  n['criado_em'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getNotificacoes(String usuarioId) async {
    final database = await db;
    return database.query('notificacoes_local',
        where: 'usuario_id = ?',
        whereArgs: [usuarioId],
        orderBy: 'criado_em DESC',
        limit: 50);
  }

  static Future<int> contarNaoLidasLocal(String usuarioId) async {
    final database = await db;
    final rows = await database.query('notificacoes_local',
        where: 'usuario_id = ? AND lida = 0', whereArgs: [usuarioId]);
    return rows.length;
  }

  static Future<void> marcarNotificacaoLidaLocal(String id) async {
    final database = await db;
    await database.update('notificacoes_local', {'lida': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> marcarTodasLidasLocal(String usuarioId) async {
    final database = await db;
    await database.update('notificacoes_local', {'lida': 1},
        where: 'usuario_id = ? AND lida = 0', whereArgs: [usuarioId]);
  }

  // ── Clientes ─────────────────────────────────────────────
  static Future<void> salvarClientes(List<Map<String, dynamic>> lista) async {
    if (lista.isEmpty) return;
    final database = await db;
    final pendingRows = await database.query('clientes', columns: ['id'], where: 'synced = 0');
    final pendingIds = pendingRows.map((r) => r['id'] as String).toSet();
    final batch = database.batch();
    for (final c in lista) {
      if (!pendingIds.contains(c['id'] as String)) {
        batch.insert('clientes', c, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getClientes() async {
    final database = await db;
    return database.query('clientes', where: 'ativo = 1', orderBy: 'nome');
  }

  static Future<void> insertCliente(Map<String, dynamic> c) async {
    final database = await db;
    await database.insert('clientes', {...c, 'synced': 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateCliente(String id, Map<String, dynamic> dados, {int synced = 0}) async {
    final database = await db;
    await database.update('clientes', {...dados, 'synced': synced},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteCliente(String id) async {
    final database = await db;
    await database.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> marcarSynced(String tabela, String id) async {
    final database = await db;
    await database.update(tabela, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ── Equipamentos ─────────────────────────────────────────
  static Future<void> salvarEquipamentos(List<Map<String, dynamic>> lista) async {
    final database = await db;
    final batch = database.batch();
    for (final e in lista) {
      batch.insert('equipamentos', e, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getEquipamentos({String? clienteId}) async {
    final database = await db;
    if (clienteId != null) {
      return database.query('equipamentos',
          where: 'ativo = 1 AND cliente_id = ?',
          whereArgs: [clienteId],
          orderBy: 'marca');
    }
    return database.query('equipamentos', where: 'ativo = 1', orderBy: 'marca');
  }

  static Future<void> insertEquipamento(Map<String, dynamic> e) async {
    final database = await db;
    await database.insert('equipamentos', {...e, 'synced': 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateEquipamento(String id, Map<String, dynamic> dados) async {
    final database = await db;
    await database.update('equipamentos', {...dados, 'synced': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteEquipamento(String id) async {
    final database = await db;
    await database.delete('equipamentos', where: 'id = ?', whereArgs: [id]);
  }

  // ── Ordens de Serviço ─────────────────────────────────────
  static Future<void> salvarOS(List<Map<String, dynamic>> lista) async {
    final database = await db;
    final batch = database.batch();
    for (final os in lista) {
      batch.insert('ordens_servico', os, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getOS() async {
    final database = await db;
    return database.query('ordens_servico',
        where: 'ativo = 1', orderBy: 'data_entrada DESC');
  }

  static Future<Map<String, dynamic>?> getOSById(String id) async {
    final database = await db;
    final result = await database.query('ordens_servico',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  static Future<void> insertOS(Map<String, dynamic> os) async {
    final database = await db;
    await database.insert('ordens_servico', {...os, 'synced': 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateOS(String id, Map<String, dynamic> dados) async {
    final database = await db;
    await database.update('ordens_servico', {...dados, 'synced': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Atualiza apenas as fotos de uma seção específica da OS
  static Future<void> atualizarFotosSecaoOS(
      String osId, String coluna, List<String> fotos) async {
    final database = await db;
    await database.update(
      'ordens_servico',
      {coluna: jsonEncode(fotos), 'synced': 0},
      where: 'id = ?',
      whereArgs: [osId],
    );
  }

  // ── Assinaturas local ────────────────────────────────────
  static Future<void> salvarAssinaturaLocal(
      String osId, String? sigCliente, String? sigTecnico) async {
    final database = await db;
    await database.insert(
      'os_assinatura_local',
      {'os_id': osId, 'sig_cliente': sigCliente, 'sig_tecnico': sigTecnico},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getAssinaturaLocal(String osId) async {
    final database = await db;
    final rows = await database.query(
      'os_assinatura_local',
      where: 'os_id = ?',
      whereArgs: [osId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  // ── Checklist local ──────────────────────────────────────
  static Future<void> salvarChecklistLocal(String osId, List<Map<String, dynamic>> itens) async {
    final database = await db;
    await database.delete('os_checklist_local', where: 'os_id = ?', whereArgs: [osId]);
    final batch = database.batch();
    for (final item in itens) {
      batch.insert('os_checklist_local', {
        'os_id': osId,
        'item_id': item['item_id'],
        'item_nome': item['item_nome'],
        'feito': (item['feito'] == true || item['feito'] == 1) ? 1 : 0,
        'data_verificacao': item['data_verificacao'],
        'tecnico_verificador': item['tecnico_verificador'],
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getChecklistLocal(String osId) async {
    final database = await db;
    return database.query('os_checklist_local',
        where: 'os_id = ?', whereArgs: [osId], orderBy: 'item_id');
  }

  // ── Acessórios local ──────────────────────────────────────
  static Future<void> salvarAcessoriosLocal(String osId, List<String> nomes) async {
    final database = await db;
    await database.delete('os_acessorio_local', where: 'os_id = ?', whereArgs: [osId]);
    final batch = database.batch();
    for (final nome in nomes) {
      batch.insert('os_acessorio_local', {'os_id': osId, 'nome': nome});
    }
    await batch.commit(noResult: true);
  }

  static Future<List<String>> getAcessoriosLocal(String osId) async {
    final database = await db;
    final rows = await database.query('os_acessorio_local',
        where: 'os_id = ?', whereArgs: [osId]);
    return rows.map((r) => r['nome'] as String).toList();
  }

  // ── Profiles / Técnicos ───────────────────────────────────
  static Future<void> salvarProfiles(List<Map<String, dynamic>> lista) async {
    final database = await db;
    final batch = database.batch();
    for (final p in lista) {
      batch.insert('profiles', p, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getProfiles() async {
    final database = await db;
    return database.query('profiles', where: 'ativo = 1', orderBy: 'nome');
  }

  static Future<Map<String, dynamic>?> getProfileById(String id) async {
    final database = await db;
    final rows = await database.query('profiles',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> atualizarAtivoProfile(String id, int ativo) async {
    final database = await db;
    await database.update('profiles', {'ativo': ativo},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deletarProfile(String id) async {
    final database = await db;
    await database.delete('profiles', where: 'id = ?', whereArgs: [id]);
  }

  // ── Fotos Pendentes (offline) ────────────────────────────
  static Future<void> salvarFotoPendente(String osId, String filePath) async {
    final database = await db;
    await database.insert('fotos_pendentes', {
      'os_id': osId,
      'file_path': filePath,
      'criado_em': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<Map<String, dynamic>>> getFotosPendentes() async {
    final database = await db;
    return database.query('fotos_pendentes', orderBy: 'criado_em ASC');
  }

  static Future<List<Map<String, dynamic>>> getFotosPendentesPorOs(String osId) async {
    final database = await db;
    return database.query('fotos_pendentes',
        where: 'os_id = ?', whereArgs: [osId]);
  }

  static Future<void> removerFotoPendente(int id) async {
    final database = await db;
    await database.delete('fotos_pendentes', where: 'id = ?', whereArgs: [id]);
  }

  // ── Sync Queue ────────────────────────────────────────────
  static Future<void> adicionarFila(
      String tabela, String operacao, String registroId, Map<String, dynamic> payload) async {
    final database = await db;
    await database.insert('sync_queue', {
      'tabela': tabela,
      'operacao': operacao,
      'registro_id': registroId,
      'payload': jsonEncode(payload),
      'criado_em': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<Map<String, dynamic>>> getPendentes() async {
    final database = await db;
    return database.query('sync_queue', orderBy: 'criado_em ASC');
  }

  static Future<void> removerDaFila(int id) async {
    final database = await db;
    await database.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // ── Equipamentos por OS ──────────────────────────────────
  static Future<void> salvarEquipamentosOs(String osId, List<String> equipIds) async {
    final database = await db;
    await database.delete('os_equipamento_local', where: 'os_id = ?', whereArgs: [osId]);
    if (equipIds.isEmpty) return;
    final batch = database.batch();
    for (final eid in equipIds) {
      batch.insert('os_equipamento_local',
          {'os_id': osId, 'equipamento_id': eid},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<String>> getEquipamentosOs(String osId) async {
    final database = await db;
    final rows = await database.query('os_equipamento_local',
        columns: ['equipamento_id'],
        where: 'os_id = ?',
        whereArgs: [osId]);
    return rows.map((r) => r['equipamento_id'] as String).toList();
  }

  static Future<Map<String, List<String>>> getEquipamentosOsMap(
      List<String> osIds) async {
    if (osIds.isEmpty) return {};
    final database = await db;
    final placeholders = List.filled(osIds.length, '?').join(',');
    final rows = await database.rawQuery(
      'SELECT os_id, equipamento_id FROM os_equipamento_local WHERE os_id IN ($placeholders)',
      osIds,
    );
    final map = <String, List<String>>{};
    for (final row in rows) {
      final osId = row['os_id'] as String;
      final equipId = row['equipamento_id'] as String;
      map.putIfAbsent(osId, () => []).add(equipId);
    }
    return map;
  }

  // ── Análise de Equipamento ────────────────────────────────
  static Future<void> salvarAnaliseEquipamento(Map<String, dynamic> dados) async {
    final database = await db;
    await database.delete(
      'os_analise_equipamento',
      where: 'os_id = ? AND id != ?',
      whereArgs: [dados['os_id'], dados['id']],
    );
    await database.insert('os_analise_equipamento', dados,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getAnaliseEquipamento(String osId) async {
    final database = await db;
    final rows = await database.query('os_analise_equipamento',
        where: 'os_id = ?',
        whereArgs: [osId],
        orderBy: 'atualizado_em DESC',
        limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final vazio = (row['tipo_equipamento'] as String? ?? '').isEmpty &&
        (row['id_nome'] as String? ?? '').isEmpty &&
        (row['modelo'] as String? ?? '').isEmpty &&
        (row['numero_serie'] as String? ?? '').isEmpty &&
        (row['tipo_antena'] as String? ?? '').isEmpty &&
        (row['tipo_cabo'] as String? ?? '').isEmpty &&
        (row['roe_vswr'] as String? ?? '').isEmpty &&
        (row['voltagem_fonte'] as String? ?? '').isEmpty &&
        (row['observacoes'] as String? ?? '').isEmpty &&
        (row['possui_fonte_dedicada'] as int? ?? 0) == 0 &&
        (row['tipo_radio'] as String? ?? '').isEmpty &&
        (row['marca_radio'] as String? ?? '').isEmpty;
    return vazio ? null : row;
  }

  static Future<void> deleteAnaliseEquipamento(String osId) async {
    final database = await db;
    await database.delete('os_analise_equipamento',
        where: 'os_id = ?', whereArgs: [osId]);
  }

  // ── Testes Local (Melhoria 4) ─────────────────────────────
  static Future<void> salvarTestesLocal(
      String osId, List<Map<String, dynamic>> itens) async {
    final database = await db;
    await database.delete('os_testes_local', where: 'os_id = ?', whereArgs: [osId]);
    final batch = database.batch();
    for (final item in itens) {
      batch.insert('os_testes_local', {
        'os_id': osId,
        'item_id': item['item_id'],
        'item_nome': item['item_nome'],
        'feito': (item['feito'] == true || item['feito'] == 1) ? 1 : 0,
        'observacao': item['observacao'] ?? '',
        'data_verificacao': item['data_verificacao'],
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getTestesLocal(String osId) async {
    final database = await db;
    return database.query('os_testes_local',
        where: 'os_id = ?', whereArgs: [osId], orderBy: 'id ASC');
  }

  // ── Visita Técnica Local (Melhoria 2) ─────────────────────
  static Future<void> salvarVisitaLocal(Map<String, dynamic> dados) async {
    final database = await db;
    await database.insert('os_visita_local', dados,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getVisitaLocal(String osId) async {
    final database = await db;
    final rows = await database.query('os_visita_local',
        where: 'os_id = ?', whereArgs: [osId], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  static Future<List<Map<String, dynamic>>> getTodasVisitasLocal() async {
    final database = await db;
    return database.query('os_visita_local', orderBy: 'atualizado_em DESC');
  }
}
