<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';
  import { Search, Filter, CheckCircle, Clock, XCircle, MessageSquare } from 'lucide-svelte';
  import { clsx } from 'clsx';

  let tickets: any[] = [];
  let loading = true;
  let statusFilter = 'all';
  let searchQuery = '';

  onMount(async () => {
    await fetchTickets();
    
    // Subscribe to changes
    const subscription = supabase
      .channel('tickets_changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tickets' }, () => {
        fetchTickets();
      })
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  });

  async function fetchTickets() {
    loading = true;
    let query = supabase
      .from('tickets')
      .select('*')
      .order('updated_at', { ascending: false });

    if (statusFilter !== 'all') {
      query = query.eq('status', statusFilter);
    }

    if (searchQuery) {
      query = query.ilike('subject', `%${searchQuery}%`);
    }

    const { data, error } = await query;
    if (data) tickets = data;
    loading = false;
  }

  async function updateStatus(id: string, newStatus: string) {
    let rpcName = '';
    if (newStatus === 'closed') rpcName = 'close_ticket';
    else if (newStatus === 'resolved') rpcName = 'resolve_ticket';
    
    if (rpcName) {
      await supabase.rpc(rpcName, { ticket_id: id });
    } else {
      await supabase.from('tickets').update({ status: newStatus, updated_at: new Date() }).eq('id', id);
    }
    await fetchTickets();
  }

  const statusColors: Record<string, string> = {
    open: 'bg-emerald-100 text-emerald-700 border-emerald-200',
    pending: 'bg-amber-100 text-amber-700 border-amber-200',
    resolved: 'bg-blue-100 text-blue-700 border-blue-200',
    closed: 'bg-slate-100 text-slate-700 border-slate-200',
  };

  $: filteredTickets = tickets;
</script>

<div class="space-y-6">
  <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
    <div>
      <h2 class="text-2xl font-bold text-slate-900">Support Tickets</h2>
      <p class="text-slate-500">Manage and respond to customer inquiries</p>
    </div>
    
    <div class="flex flex-wrap gap-2">
      <div class="relative">
        <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
        <input 
          type="text" 
          placeholder="Search tickets..." 
          bind:value={searchQuery}
          on:input={fetchTickets}
          class="pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 w-64"
        />
      </div>
      <select 
        bind:value={statusFilter} 
        on:change={fetchTickets}
        class="px-4 py-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
      >
        <option value="all">All Status</option>
        <option value="open">Open</option>
        <option value="pending">Pending</option>
        <option value="resolved">Resolved</option>
        <option value="closed">Closed</option>
      </select>
    </div>
  </div>

  {#if loading}
    <div class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
    </div>
  {:else if tickets.length === 0}
    <div class="bg-white border border-slate-200 rounded-xl p-12 text-center">
      <MessageSquare class="w-12 h-12 text-slate-300 mx-auto mb-4" />
      <h3 class="text-lg font-medium text-slate-900">No tickets found</h3>
      <p class="text-slate-500">Try adjusting your filters or search query.</p>
    </div>
  {:else}
    <div class="bg-white border border-slate-200 rounded-xl overflow-hidden shadow-sm">
      <table class="w-full text-left">
        <thead class="bg-slate-50 border-b border-slate-200">
          <tr>
            <th class="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Subject</th>
            <th class="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Customer ID</th>
            <th class="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Status</th>
            <th class="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Last Updated</th>
            <th class="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          {#each tickets as ticket}
            <tr class="hover:bg-slate-50 transition-colors">
              <td class="px-6 py-4">
                <a href="/admin/tickets/{ticket.id}" class="font-medium text-slate-900 hover:text-indigo-600">
                  {ticket.subject}
                </a>
              </td>
              <td class="px-6 py-4 text-sm text-slate-500 font-mono">
                {ticket.customer_id.slice(0, 8)}...
              </td>
              <td class="px-6 py-4">
                <span class={clsx("px-2.5 py-1 rounded-full text-xs font-medium border", statusColors[ticket.status])}>
                  {ticket.status.charAt(0) + ticket.status.slice(1)}
                </span>
              </td>
              <td class="px-6 py-4 text-sm text-slate-500">
                {new Date(ticket.updated_at).toLocaleString()}
              </td>
              <td class="px-6 py-4 text-right">
                <div class="flex justify-end gap-2">
                  <select 
                    value={ticket.status}
                    on:change={(e) => updateStatus(ticket.id, e.currentTarget.value)}
                    class="text-xs border-slate-200 rounded px-2 py-1"
                  >
                    <option value="open">Open</option>
                    <option value="pending">Pending</option>
                    <option value="resolved">Resolved</option>
                    <option value="closed">Closed</option>
                  </select>
                  <a 
                    href="/admin/tickets/{ticket.id}" 
                    class="p-1.5 text-slate-400 hover:text-indigo-600 border border-slate-200 rounded-lg hover:border-indigo-100 hover:bg-indigo-50 transition-all"
                  >
                    <MessageSquare class="w-4 h-4" />
                  </a>
                </div>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
</div>
