import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

serve(async (req) => {
  const { record } = await req.json()

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  // Auto-reply for new tickets
  const { data, error } = await supabase
    .from('messages')
    .insert([
      {
        ticket_id: record.id,
        sender_type: 'admin',
        content: `Hi there! Thanks for reaching out. We've received your ticket "${record.subject}" and someone from our team will get back to you soon.`
      },
    ])

  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })

  return new Response(JSON.stringify({ message: "Auto-reply sent" }), {
    headers: { "Content-Type": "application/json" },
  })
})
