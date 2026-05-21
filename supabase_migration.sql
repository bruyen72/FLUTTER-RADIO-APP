-- ============================================================
--  TECPOINT / SURVEY — Gerenciador de OS
--  Migração Supabase (PostgreSQL) — versão 2
--
--  Pode ser executado em banco vazio OU em banco existente:
--  todas as instruções são idempotentes (IF NOT EXISTS /
--  DROP IF EXISTS / ON CONFLICT DO NOTHING).
--
--  Execute no SQL Editor do Supabase Dashboard.
-- ============================================================

-- ── Tabelas extras do projeto web que o Flutter NÃO precisa ──
--
--  usuario / users  → Flutter usa Supabase Auth + profiles
--  tecnico          → profiles já tem especialidade/geo_lat/geo_lng
--  relatorio        → Flutter gera PDF local e compartilha (sem upload)
--  sync_queue(web)  → Flutter usa SQLite local + grava direto no Supabase
--  leads            → não existe no repositório web analisado
--  messages         → não existe no repositório web analisado
--
-- ─────────────────────────────────────────────────────────────


-- ════════════════════════════════════════════════════════════
--  FUNÇÕES AUXILIARES
-- ════════════════════════════════════════════════════════════

-- Verifica se o usuário logado é admin (Security Definer = sem RLS recursivo)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND perfil = 'admin'
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Gera número único de OS no formato OS-YYYYMMDD-0001
CREATE OR REPLACE FUNCTION public.gerar_numero_os()
RETURNS TEXT AS $$
DECLARE
  hoje TEXT := TO_CHAR(NOW(), 'YYYYMMDD');
  seq  INTEGER;
BEGIN
  SELECT COALESCE(MAX(CAST(SPLIT_PART(numero_os, '-', 3) AS INTEGER)), 0) + 1
  INTO seq
  FROM public.ordem_servico
  WHERE numero_os LIKE 'OS-' || hoje || '-%';

  RETURN 'OS-' || hoje || '-' || LPAD(seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;


-- ════════════════════════════════════════════════════════════
--  TABELAS
-- ════════════════════════════════════════════════════════════

-- ── 1. Profiles (estende auth.users) ────────────────────────
--  Substitui as tabelas usuario + tecnico do projeto web.
--  geo_lat/geo_lng: localização atual do técnico (campo).
CREATE TABLE IF NOT EXISTS public.profiles (
    id            UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nome          TEXT        NOT NULL,
    email         TEXT,                                   -- cópia de auth.users.email para exibição
    perfil        TEXT        NOT NULL DEFAULT 'tecnico', -- admin | tecnico
    especialidade TEXT,
    geo_lat       NUMERIC(10,8),
    geo_lng       NUMERIC(11,8),
    ativo         BOOLEAN     NOT NULL DEFAULT true,
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 2. Clientes ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cliente (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    nome          TEXT        NOT NULL,
    telefone      TEXT,
    email         TEXT,
    endereco      TEXT,
    ativo         BOOLEAN     NOT NULL DEFAULT true,
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 3. Equipamentos ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.equipamento (
    id                UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo              TEXT    NOT NULL,
    marca             TEXT    NOT NULL,
    modelo            TEXT    NOT NULL,
    numero_serie      TEXT    NOT NULL UNIQUE,
    cliente_id        UUID    NOT NULL REFERENCES public.cliente(id) ON DELETE RESTRICT,
    cor_identificacao TEXT,
    canal_frequencia  TEXT,
    ativo             BOOLEAN     NOT NULL DEFAULT true,
    criado_em         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 4. Ordens de Serviço ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ordem_servico (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_os           TEXT        NOT NULL UNIQUE,
    descricao           TEXT,
    status              TEXT        NOT NULL DEFAULT 'Aberto',        -- Aberto | Em Andamento | Concluído | Cancelado
    prioridade          TEXT        NOT NULL DEFAULT 'Baixa',         -- Baixa | Média | Urgente
    tipo_ocorrencia     TEXT,                                          -- Preventiva | Manutenção | Corretiva
    data_entrada        DATE        NOT NULL,
    hora_entrada        TEXT,
    data_saida          DATE,
    acompanhante        TEXT,
    condicoes_fisicas   TEXT,
    defeito_relatado    TEXT,
    status_equipamento  TEXT,
    laudo_tecnico       TEXT,
    solucao_aplicada    TEXT,
    pecas_utilizadas    TEXT,
    termos_observacoes  TEXT,
    geo_lat             NUMERIC(10,8),
    geo_lng             NUMERIC(11,8),
    geo_endereco        TEXT,                                          -- endereço preenchido via CEP ou GPS
    ativo               BOOLEAN     NOT NULL DEFAULT true,
    criado_em           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    cliente_id          UUID        NOT NULL REFERENCES public.cliente(id)   ON DELETE RESTRICT,
    tecnico_id          UUID                 REFERENCES public.profiles(id)  ON DELETE SET NULL,
    criado_por          UUID        NOT NULL REFERENCES public.profiles(id)  ON DELETE RESTRICT
);

-- ── 5. OS ↔ Equipamento (N:N) ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.os_equipamento (
    os_id          UUID NOT NULL REFERENCES public.ordem_servico(id) ON DELETE CASCADE,
    equipamento_id UUID NOT NULL REFERENCES public.equipamento(id)   ON DELETE RESTRICT,
    PRIMARY KEY (os_id, equipamento_id)
);

-- ── 6. Acessórios da OS ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.os_acessorio (
    id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    os_id UUID NOT NULL REFERENCES public.ordem_servico(id) ON DELETE CASCADE,
    nome  TEXT NOT NULL
);

-- ── 7. Checklist de testes ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.os_checklist (
    id                  UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    os_id               UUID    NOT NULL REFERENCES public.ordem_servico(id) ON DELETE CASCADE,
    item_id             TEXT    NOT NULL,
    item_nome           TEXT    NOT NULL,
    feito               BOOLEAN NOT NULL DEFAULT false,
    data_verificacao    DATE,
    tecnico_verificador TEXT
);

-- ── 8. Fotos da OS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.os_foto (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    os_id         UUID        NOT NULL REFERENCES public.ordem_servico(id) ON DELETE CASCADE,
    nome_arquivo  TEXT        NOT NULL,
    caminho       TEXT        NOT NULL,    -- URL pública do Storage
    tamanho_bytes INTEGER,
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 9. Assinaturas da OS ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.os_assinatura (
    os_id         UUID        PRIMARY KEY REFERENCES public.ordem_servico(id) ON DELETE CASCADE,
    sig_cliente   TEXT,                   -- data:image/png;base64,...
    sig_tecnico   TEXT,
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 10. Notificações ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notificacao (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID        NOT NULL REFERENCES public.profiles(id)      ON DELETE CASCADE,
    os_id      UUID                 REFERENCES public.ordem_servico(id) ON DELETE SET NULL,
    mensagem   TEXT        NOT NULL,
    tipo       TEXT        NOT NULL DEFAULT 'info',   -- info | urgente | aviso
    lida       BOOLEAN     NOT NULL DEFAULT false,
    criado_em  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ════════════════════════════════════════════════════════════
--  ÍNDICES DE PERFORMANCE
-- ════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_os_cliente  ON public.ordem_servico(cliente_id);
CREATE INDEX IF NOT EXISTS idx_os_tecnico  ON public.ordem_servico(tecnico_id);
CREATE INDEX IF NOT EXISTS idx_os_status   ON public.ordem_servico(status);
CREATE INDEX IF NOT EXISTS idx_os_ativo    ON public.ordem_servico(ativo);
CREATE INDEX IF NOT EXISTS idx_os_entrada  ON public.ordem_servico(data_entrada);
CREATE INDEX IF NOT EXISTS idx_equip_cli   ON public.equipamento(cliente_id);
CREATE INDEX IF NOT EXISTS idx_notif_usr   ON public.notificacao(usuario_id);
CREATE INDEX IF NOT EXISTS idx_notif_lida  ON public.notificacao(lida);


-- ════════════════════════════════════════════════════════════
--  ROW LEVEL SECURITY
-- ════════════════════════════════════════════════════════════

ALTER TABLE public.profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cliente        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipamento    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ordem_servico  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.os_equipamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.os_acessorio   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.os_checklist   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.os_foto        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.os_assinatura  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacao    ENABLE ROW LEVEL SECURITY;

-- ── Remover policies antigas (torna o script re-executável) ──
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_delete" ON public.profiles;
DROP POLICY IF EXISTS "cliente_all"     ON public.cliente;
DROP POLICY IF EXISTS "equip_all"       ON public.equipamento;
DROP POLICY IF EXISTS "os_all"          ON public.ordem_servico;
DROP POLICY IF EXISTS "os_equip_all"    ON public.os_equipamento;
DROP POLICY IF EXISTS "os_aces_all"     ON public.os_acessorio;
DROP POLICY IF EXISTS "os_check_all"    ON public.os_checklist;
DROP POLICY IF EXISTS "os_foto_all"     ON public.os_foto;
DROP POLICY IF EXISTS "os_assin_all"    ON public.os_assinatura;
DROP POLICY IF EXISTS "notif_select"    ON public.notificacao;
DROP POLICY IF EXISTS "notif_insert"    ON public.notificacao;
DROP POLICY IF EXISTS "notif_update"    ON public.notificacao;

-- ── Profiles ─────────────────────────────────────────────────
--  SELECT: qualquer autenticado pode ver todos os perfis (necessário
--          para listar técnicos no formulário de OS)
--  INSERT: próprio usuário OU admin (UsuarioService.criarUsuario()
--          faz upsert após signUp; trigger também insere via SECURITY DEFINER)
--  UPDATE: próprio usuário OU admin (necessário para desativar/editar
--          outro usuário via UsuarioService)
--  DELETE: apenas admin (soft-delete via ativo=false é preferido)
CREATE POLICY "profiles_select" ON public.profiles
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "profiles_insert" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id OR public.is_admin());

CREATE POLICY "profiles_update" ON public.profiles
    FOR UPDATE USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "profiles_delete" ON public.profiles
    FOR DELETE USING (public.is_admin());

-- ── Demais tabelas: acesso total para autenticados ────────────
CREATE POLICY "cliente_all"    ON public.cliente        FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "equip_all"      ON public.equipamento    FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "os_all"         ON public.ordem_servico  FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "os_equip_all"   ON public.os_equipamento FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "os_aces_all"    ON public.os_acessorio   FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "os_check_all"   ON public.os_checklist   FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "os_foto_all"    ON public.os_foto        FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "os_assin_all"   ON public.os_assinatura  FOR ALL USING (auth.role() = 'authenticated');

-- ── Notificações: cada usuário vê/edita apenas as suas ────────
CREATE POLICY "notif_select" ON public.notificacao
    FOR SELECT USING (auth.uid() = usuario_id OR public.is_admin());

CREATE POLICY "notif_insert" ON public.notificacao
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "notif_update" ON public.notificacao
    FOR UPDATE USING (auth.uid() = usuario_id OR public.is_admin());


-- ════════════════════════════════════════════════════════════
--  STORAGE — bucket de fotos
-- ════════════════════════════════════════════════════════════

INSERT INTO storage.buckets (id, name, public)
VALUES ('os-fotos', 'os-fotos', true)
ON CONFLICT DO NOTHING;

DROP POLICY IF EXISTS "fotos_upload" ON storage.objects;
DROP POLICY IF EXISTS "fotos_select" ON storage.objects;
DROP POLICY IF EXISTS "fotos_delete" ON storage.objects;

CREATE POLICY "fotos_upload" ON storage.objects
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND bucket_id = 'os-fotos');

CREATE POLICY "fotos_select" ON storage.objects
    FOR SELECT USING (bucket_id = 'os-fotos');

CREATE POLICY "fotos_delete" ON storage.objects
    FOR DELETE USING (auth.role() = 'authenticated' AND bucket_id = 'os-fotos');


-- ════════════════════════════════════════════════════════════
--  TRIGGERS
-- ════════════════════════════════════════════════════════════

-- Cria profile automaticamente ao registrar novo usuário via Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, nome, email, perfil)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
    new.email,
    COALESCE(new.raw_user_meta_data->>'perfil', 'tecnico')
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- ════════════════════════════════════════════════════════════
--  CONFIGURAÇÃO INICIAL — usuário admin padrão
-- ════════════════════════════════════════════════════════════
--
--  Crie o usuário admin manualmente no Supabase Dashboard:
--  Authentication → Users → Add User
--    Email:  admin@tecpoint.com  (ou o e-mail desejado)
--    Senha:  (defina uma senha forte)
--
--  Depois execute o UPDATE abaixo com o UUID gerado:
--
--  UPDATE public.profiles
--  SET nome = 'Administrador', perfil = 'admin'
--  WHERE id = '<UUID-do-usuário-criado>';
--
-- ════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════
--  PATCH PARA BANCO EXISTENTE
--  Execute este bloco se o banco já existia antes desta versão
-- ════════════════════════════════════════════════════════════

-- Adiciona coluna email se ainda não existe
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- Popula email de todos os usuários existentes a partir do auth.users
UPDATE public.profiles p
SET    email = u.email
FROM   auth.users u
WHERE  p.id = u.id
  AND  (p.email IS NULL OR p.email = '');

-- ── Campos de endereço estruturados no cliente ────────────────
ALTER TABLE public.cliente ADD COLUMN IF NOT EXISTS logradouro        TEXT;
ALTER TABLE public.cliente ADD COLUMN IF NOT EXISTS numero_complemento TEXT;
ALTER TABLE public.cliente ADD COLUMN IF NOT EXISTS bairro             TEXT;
ALTER TABLE public.cliente ADD COLUMN IF NOT EXISTS cidade             TEXT;
ALTER TABLE public.cliente ADD COLUMN IF NOT EXISTS uf                 TEXT;

-- ════════════════════════════════════════════════════════════
