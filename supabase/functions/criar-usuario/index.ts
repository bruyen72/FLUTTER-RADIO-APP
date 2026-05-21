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
    if (!authHeader) {
      return json({ error: 'Não autorizado' }, 401)
    }

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
      return json({ error: 'Apenas administradores podem criar usuários' }, 403)
    }

    const { email, senha, nome, perfil: novoPerfil, especialidade } = await req.json()

    if (!email || !senha || !nome || !novoPerfil) {
      return json({ error: 'email, senha, nome e perfil são obrigatórios' }, 400)
    }
    if (senha.length < 6) {
      return json({ error: 'A senha deve ter no mínimo 6 caracteres' }, 400)
    }

    // Cria o usuário no Auth com email já confirmado (não precisa de e-mail)
    const { data: authData, error: createErr } = await adminClient.auth.admin.createUser({
      email,
      password: senha,
      email_confirm: true,
      user_metadata: { nome, perfil: novoPerfil },
    })
    if (createErr) return json({ error: createErr.message }, 400)

    // Cria o profile
    const { error: profileErr } = await adminClient.from('profiles').upsert({
      id:            authData.user.id,
      nome,
      email,
      perfil:        novoPerfil,
      especialidade: especialidade ?? null,
      ativo:         true,
    })
    if (profileErr) return json({ error: profileErr.message }, 400)

    return json({ id: authData.user.id, nome, email, perfil: novoPerfil }, 200)
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
