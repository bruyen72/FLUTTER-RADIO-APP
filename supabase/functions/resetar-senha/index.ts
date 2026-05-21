import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const anonKey     = Deno.env.get('SUPABASE_ANON_KEY')!

    // Verifica JWT do chamador
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Não autorizado' }, 401)

    const clienteChamador = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: authErr } = await clienteChamador.auth.getUser()
    if (authErr || !user) return json({ error: 'Não autorizado' }, 401)

    // Verifica se é admin
    const adminClient = createClient(supabaseUrl, serviceKey)
    const { data: perfil } = await adminClient
      .from('profiles').select('perfil').eq('id', user.id).single()
    if (!perfil || perfil.perfil !== 'admin') {
      return json({ error: 'Apenas administradores podem resetar senhas' }, 403)
    }

    const { usuario_id, nova_senha } = await req.json()

    if (!usuario_id || !nova_senha) {
      return json({ error: 'usuario_id e nova_senha são obrigatórios' }, 400)
    }
    if (nova_senha.length < 6) {
      return json({ error: 'A senha deve ter no mínimo 6 caracteres' }, 400)
    }

    const { error } = await adminClient.auth.admin.updateUserById(usuario_id, {
      password: nova_senha,
    })
    if (error) return json({ error: error.message }, 400)

    return json({ ok: true }, 200)
  } catch (err) {
    return json({ error: String(err) }, 500)
  }
})

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })
}
