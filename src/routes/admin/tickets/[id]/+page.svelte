<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { supabase } from '$lib/supabase';
  import { ArrowLeft, Send, Paperclip, FileText, Image as ImageIcon, Video, User, ShieldCheck } from 'lucide-svelte';
  import { clsx } from 'clsx';

  const ticketId = $page.params.id;
  let ticket: any = null;
  let messages: any[] = [];
  let newMessage = '';
  let loading = true;
  let sending = false;

  onMount(async () => {
    await Promise.all([fetchTicket(), fetchMessages()]);
    scrollToBottom();

    const subscription = supabase
      .channel(`ticket_${ticketId}`)
      .on('postgres_changes', { 
        event: 'INSERT', 
        schema: 'public', 
        table: 'messages',
        filter: `ticket_id=eq.${ticketId}`
      }, (payload) => {
        messages = [...messages, payload.new];
        scrollToBottom();
      })
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'tickets',
        filter: `id=eq.${ticketId}`
      }, (payload) => {
        ticket = { ...ticket, ...payload.new };
      })
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  });

  async function fetchTicket() {
    const { data } = await supabase.from('tickets').select('*').eq('id', ticketId).single();
    if (data) ticket = data;
  }

  async function fetchMessages() {
    const { data } = await supabase
      .from('messages')
      .select('*, attachments(*)')
      .eq('ticket_id', ticketId)
      .order('created_at', { ascending: true });
    
    if (data) messages = data;
    loading = false;
  }

  async function sendMessage() {
    if (!newMessage.trim() || sending) return;

    sending = true;
    const { error } = await supabase.from('messages').insert([
      {
        ticket_id: ticketId,
        sender_type: 'admin',
        content: newMessage
      }
    ]);

    if (!error) {
      newMessage = '';
      await supabase.from('tickets').update({ updated_at: new Date() }).eq('id', ticketId);
    }
    sending = false;
  }

  function scrollToBottom() {
    setTimeout(() => {
      const chatContainer = document.getElementById('chat-messages');
      if (chatContainer) {
        chatContainer.scrollTop = chatContainer.scrollHeight;
      }
    }, 100);
  }

  function getPublicUrl(path: string) {
    const { data } = supabase.storage.from('attachments').getPublicUrl(path);
    return data.publicUrl;
  }

  const statusColors: Record<string, string> = {
    open: 'bg-emerald-100 text-emerald-700 border-emerald-200',
    pending: 'bg-amber-100 text-amber-700 border-amber-200',
    resolved: 'bg-blue-100 text-blue-700 border-blue-200',
    closed: 'bg-slate-100 text-slate-700 border-slate-200',
  };
</script>

<div class="h-[calc(100vh-140px)] flex flex-col gap-4">
  <div class="flex items-center justify-between">
    <div class="flex items-center gap-4">
      <a href="/admin/tickets" class="p-2 hover:bg-slate-200 rounded-full transition-colors">
        <ArrowLeft class="w-5 h-5 text-slate-600" />
      </a>
      <div>
        <h2 class="text-xl font-bold text-slate-900">{ticket?.subject ?? 'Loading...'}</h2>
        {#if ticket}
          <div class="flex items-center gap-2 mt-1">
            <span class={clsx("px-2 py-0.5 rounded-full text-[10px] uppercase font-bold border tracking-wider", statusColors[ticket.status])}>
              {ticket.status}
            </span>
            <span class="text-xs text-slate-500">ID: {ticket.id}</span>
          </div>
        {/if}
      </div>
    </div>
  </div>

  <div class="flex-1 bg-white border border-slate-200 rounded-2xl shadow-sm flex flex-col overflow-hidden">
    <div id="chat-messages" class="flex-1 overflow-y-auto p-6 space-y-6">
      {#if loading}
        <div class="flex justify-center py-12">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      {:else}
        {#each messages as msg}
          <div class={clsx("flex flex-col max-w-[80%]", msg.sender_type === 'admin' ? "ml-auto items-end" : "mr-auto items-start")}>
            <div class="flex items-center gap-2 mb-1">
              {#if msg.sender_type === 'admin'}
                <ShieldCheck class="w-3 h-3 text-indigo-600" />
                <span class="text-[10px] font-bold text-indigo-600 uppercase tracking-tight">Support Agent</span>
              {:else}
                <User class="w-3 h-3 text-slate-400" />
                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-tight">Customer</span>
              {/if}
              <span class="text-[10px] text-slate-400">{new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
            </div>
            
            <div class={clsx(
              "px-4 py-3 rounded-2xl text-sm leading-relaxed",
              msg.sender_type === 'admin' 
                ? "bg-indigo-600 text-white rounded-tr-none" 
                : "bg-slate-100 text-slate-800 rounded-tl-none"
            )}>
              {msg.content}
              
              {#if msg.attachments && msg.attachments.length > 0}
                <div class="mt-3 space-y-2">
                  {#each msg.attachments as att}
                    <a 
                      href={getPublicUrl(att.file_path)} 
                      target="_blank"
                      class="flex items-center gap-2 bg-black/5 p-2 rounded-lg border border-black/5 hover:bg-black/10 transition-colors cursor-pointer"
                    >
                      {#if att.content_type.startsWith('image/')}
                        <ImageIcon class="w-4 h-4" />
                      {:else if att.content_type.startsWith('video/')}
                        <Video class="w-4 h-4" />
                      {:else}
                        <FileText class="w-4 h-4" />
                      {/if}
                      <span class="text-xs truncate max-w-[150px]">{att.file_name}</span>
                    </a>
                  {/each}
                </div>
              {/if}
            </div>
          </div>
        {/each}
      {/if}
    </div>

    <div class="p-4 bg-slate-50 border-t border-slate-200">
      <form on:submit|preventDefault={sendMessage} class="relative">
        <textarea 
          bind:value={newMessage}
          placeholder="Write your message..."
          rows="1"
          class="w-full pl-4 pr-24 py-3 bg-white border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
          on:keydown={(e) => e.key === 'Enter' && !e.shiftKey && (e.preventDefault(), sendMessage())}
        ></textarea>
        <div class="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1">
          <button type="button" class="p-2 text-slate-400 hover:text-indigo-600 rounded-lg hover:bg-slate-100 transition-colors">
            <Paperclip class="w-5 h-5" />
          </button>
          <button 
            type="submit" 
            disabled={!newMessage.trim() || sending}
            class="p-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Send class="w-5 h-5" />
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
