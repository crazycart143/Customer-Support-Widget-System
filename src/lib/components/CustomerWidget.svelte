<script lang="ts">
  import { onMount, tick } from "svelte";
  import { supabase } from "$lib/supabase";
  import {
    MessageCircle,
    X,
    Send,
    Paperclip,
    ChevronLeft,
    Plus,
    History,
    Clock,
  } from "lucide-svelte";
  import { clsx } from "clsx";
  import { fade, slide, fly } from "svelte/transition";

  let isOpen = false;
  let view: "home" | "new-ticket" | "chat" | "history" = "home";
  let customerId = "";
  let tickets: any[] = [];
  let currentTicketId = "";
  let messages: any[] = [];
  let subject = "";
  let newMessage = "";
  let loading = false;
  let fileInput: HTMLInputElement;
  let uploadingFile = false;
  let currentTicket: any = null;

  onMount(() => {
    // Generate or retrieve customer ID
    let storedId = localStorage.getItem("support_customer_id");
    if (!storedId) {
      storedId = crypto.randomUUID();
      localStorage.setItem("support_customer_id", storedId);
    }
    customerId = storedId;
    fetchHistory();
  });

  async function fetchHistory() {
    const { data } = await supabase
      .from("tickets")
      .select("*")
      .eq("customer_id", customerId)
      .order("updated_at", { ascending: false });
    if (data) tickets = data;
  }

  async function startNewTicket() {
    if (!subject.trim()) return;
    loading = true;
    const { data, error } = await supabase
      .from("tickets")
      .insert([{ customer_id: customerId, subject, status: "open" }])
      .select()
      .single();

    if (error) {
      console.error("Error creating ticket:", error);
      alert(`Failed to create ticket: ${error.message}`);
      loading = false;
      return;
    }

    if (data) {
      currentTicketId = data.id;
      subject = "";
      await fetchMessages(currentTicketId);
      view = "chat";
    }
    loading = false;
    fetchHistory();
  }

  let currentSubscription: any = null;

  async function fetchMessages(ticketId: string) {
    currentTicketId = ticketId;
    const { data } = await supabase
      .from("messages")
      .select("*, attachments(*)")
      .eq("ticket_id", ticketId)
      .order("created_at", { ascending: true });
    if (data) messages = data;
    currentTicket = tickets.find((t) => t.id === ticketId);

    // Also fetch ticket again in case of status changes
    if (!currentTicket) {
      const { data: tData } = await supabase
        .from("tickets")
        .select("*")
        .eq("id", ticketId)
        .single();
      if (tData) currentTicket = tData;
    }

    // Handle subscription
    if (currentSubscription) {
      supabase.removeChannel(currentSubscription);
    }

    currentSubscription = supabase
      .channel(`customer_ticket_${ticketId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "messages",
          filter: `ticket_id=eq.${ticketId}`,
        },
        async (payload) => {
          // Instead of just adding the new message, we refetch to get attachments
          // if any were added. Realtime doesn't support joins content.
          const { data: fullMsg } = await supabase
            .from("messages")
            .select("*, attachments(*)")
            .eq("id", payload.new.id)
            .single();

          if (fullMsg) {
            messages = [...messages, fullMsg];
          } else {
            messages = [...messages, payload.new];
          }
          scrollToBottom();
        },
      )
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "tickets",
          filter: `id=eq.${ticketId}`,
        },
        (payload) => {
          currentTicket = payload.new;
        },
      )
      .subscribe();

    view = "chat";
    scrollToBottom();
  }

  async function sendMessage() {
    if (!newMessage.trim()) return;
    const content = newMessage;
    newMessage = "";

    const { error } = await supabase
      .from("messages")
      .insert([
        { ticket_id: currentTicketId, sender_type: "customer", content },
      ]);

    if (!error) {
      await supabase
        .from("tickets")
        .update({ updated_at: new Date() })
        .eq("id", currentTicketId);
    }
  }

  async function handleFileUpload(event: Event) {
    const target = event.target as HTMLInputElement;
    if (!target.files || target.files.length === 0) return;

    const file = target.files[0];
    uploadingFile = true;

    try {
      const fileExt = file.name.split(".").pop();
      const fileName = `${Math.random()}.${fileExt}`;
      const filePath = `${currentTicketId}/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from("attachments")
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      // Create a message for the attachment
      const { data: msgData, error: msgError } = await supabase
        .from("messages")
        .insert([
          {
            ticket_id: currentTicketId,
            sender_type: "customer",
            content: `Uploaded an attachment: ${file.name}`,
          },
        ])
        .select()
        .single();

      if (msgError) throw msgError;

      const { error: attError } = await supabase.from("attachments").insert([
        {
          message_id: msgData.id,
          file_path: filePath,
          file_name: file.name,
          content_type: file.type,
          size: file.size,
        },
      ]);

      if (attError) throw attError;

      await supabase
        .from("tickets")
        .update({ updated_at: new Date() })
        .eq("id", currentTicketId);

      // No need to manually refetch here if the subscription handles it,
      // but the subscription might be slow, so let's refetch locally for better UX
      const { data: updatedMessages } = await supabase
        .from("messages")
        .select("*, attachments(*)")
        .eq("ticket_id", currentTicketId)
        .order("created_at", { ascending: true });
      if (updatedMessages) messages = updatedMessages;
      scrollToBottom();
    } catch (error: any) {
      console.error("Error uploading file:", error);
      alert(`Failed to upload file: ${error.message || "Unknown error"}`);
    } finally {
      uploadingFile = false;
    }
  }

  function getPublicUrl(path: string) {
    const { data } = supabase.storage.from("attachments").getPublicUrl(path);
    return data.publicUrl;
  }

  function scrollToBottom() {
    setTimeout(() => {
      const el = document.getElementById("widget-chat-messages");
      if (el) el.scrollTop = el.scrollHeight;
    }, 100);
  }

  const statusColors: Record<string, string> = {
    open: "bg-emerald-500",
    pending: "bg-amber-500",
    resolved: "bg-blue-500",
    closed: "bg-slate-500",
  };
</script>

<div class="fixed bottom-6 right-6 z-[9999] font-sans">
  {#if isOpen}
    <div
      transition:fly={{ y: 20, duration: 300 }}
      class="bg-white w-[380px] h-[600px] rounded-3xl shadow-2xl flex flex-col overflow-hidden border border-slate-100 mb-4"
    >
      <!-- Header -->
      <div class="bg-indigo-600 p-6 text-white shrink-0">
        <div class="flex justify-between items-start mb-4">
          <div>
            {#if view !== "home"}
              <button
                on:click={() => (view = "home")}
                class="p-1 -ml-1 hover:bg-white/20 rounded-lg transition-colors mb-2"
              >
                <ChevronLeft class="w-5 h-5" />
              </button>
            {/if}
            <h2 class="text-xl font-bold tracking-tight">
              {#if view === "home"}How can we help?{/if}
              {#if view === "new-ticket"}New Support Ticket{/if}
              {#if view === "chat"}Support Session{/if}
              {#if view === "history"}Your Conversations{/if}
            </h2>
          </div>
          <button
            on:click={() => (isOpen = false)}
            class="p-2 hover:bg-white/20 rounded-full transition-colors"
          >
            <X class="w-5 h-5" />
          </button>
        </div>
        {#if view === "home"}
          <p class="text-indigo-100 text-sm">
            We're here to help you with any questions or issues you might have.
          </p>
        {/if}
      </div>

      <!-- Content -->
      <div class="flex-1 overflow-y-auto bg-slate-50 relative">
        {#if view === "home"}
          <div class="p-6 space-y-4" transition:fade>
            <button
              on:click={() => (view = "new-ticket")}
              class="w-full bg-white p-6 rounded-2xl shadow-sm border border-slate-100 text-left flex items-center gap-4 hover:border-indigo-200 hover:bg-indigo-50/50 transition-all group"
            >
              <div
                class="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center text-indigo-600 group-hover:scale-110 transition-transform"
              >
                <Plus class="w-6 h-6" />
              </div>
              <div>
                <h3 class="font-bold text-slate-900">Start new conversation</h3>
                <p class="text-xs text-slate-500 mt-0.5">
                  We'll get back to you shortly
                </p>
              </div>
            </button>

            <button
              on:click={() => {
                view = "history";
                fetchHistory();
              }}
              class="w-full bg-white p-6 rounded-2xl shadow-sm border border-slate-100 text-left flex items-center gap-4 hover:border-indigo-200 hover:bg-indigo-50/50 transition-all group"
            >
              <div
                class="w-12 h-12 bg-slate-100 rounded-xl flex items-center justify-center text-slate-600 group-hover:scale-110 transition-transform"
              >
                <History class="w-6 h-6" />
              </div>
              <div>
                <h3 class="font-bold text-slate-900">See previous tickets</h3>
                <p class="text-xs text-slate-500 mt-0.5">
                  View your conversation history
                </p>
              </div>
            </button>
          </div>
        {:else if view === "new-ticket"}
          <div class="p-6 space-y-6" transition:fade>
            <div class="space-y-2">
              <label for="subject" class="text-sm font-semibold text-slate-700"
                >What do you need help with?</label
              >
              <input
                id="subject"
                type="text"
                bind:value={subject}
                placeholder="e.g. Issue with my order #123"
                class="w-full p-4 bg-white border border-slate-200 rounded-2xl focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <button
              on:click={startNewTicket}
              disabled={!subject.trim() || loading}
              class="w-full bg-indigo-600 text-white font-bold py-4 rounded-2xl hover:bg-indigo-700 transition-colors shadow-lg shadow-indigo-200 disabled:opacity-50"
            >
              {loading ? "Creating..." : "Start Conversation"}
            </button>
          </div>
        {:else if view === "history"}
          <div class="p-4 space-y-3" transition:fade>
            {#each tickets as t}
              <button
                on:click={() => fetchMessages(t.id)}
                class="w-full bg-white p-4 rounded-xl border border-slate-100 text-left hover:border-indigo-100 hover:bg-indigo-50 transition-all"
              >
                <div class="flex justify-between items-start mb-2">
                  <h4 class="font-bold text-slate-900 text-sm line-clamp-1">
                    {t.subject}
                  </h4>
                  <span
                    class={clsx(
                      "w-2 h-2 rounded-full mt-1.5",
                      statusColors[t.status],
                    )}
                  ></span>
                </div>
                <div class="flex items-center gap-2 text-[10px] text-slate-400">
                  <Clock class="w-3 h-3" />
                  <span>{new Date(t.updated_at).toLocaleDateString()}</span>
                  <span
                    class="uppercase font-bold tracking-tighter text-slate-300 ml-auto"
                    >{t.status}</span
                  >
                </div>
              </button>
            {/each}
          </div>
        {:else if view === "chat"}
          <div
            id="widget-chat-messages"
            class="h-full overflow-y-auto p-4 space-y-4 pb-20"
          >
            {#each messages as msg}
              <div
                class={clsx(
                  "flex flex-col max-w-[85%]",
                  msg.sender_type === "customer"
                    ? "ml-auto items-end"
                    : "mr-auto items-start",
                )}
              >
                <div
                  class={clsx(
                    "px-4 py-2.5 rounded-2xl text-sm",
                    msg.sender_type === "customer"
                      ? "bg-indigo-600 text-white rounded-tr-none"
                      : "bg-white text-slate-800 rounded-tl-none shadow-sm border border-slate-200",
                  )}
                >
                  {msg.content}

                  {#if msg.attachments && msg.attachments.length > 0}
                    <div class="mt-2 space-y-2">
                      {#each msg.attachments as att}
                        {#if att.content_type?.startsWith("image/")}
                          <div
                            class="rounded-lg overflow-hidden border border-black/5"
                          >
                            <img
                              src={getPublicUrl(att.file_path)}
                              alt={att.file_name}
                              class="max-w-full h-auto block"
                            />
                          </div>
                        {:else}
                          <a
                            href={getPublicUrl(att.file_path)}
                            target="_blank"
                            class="flex items-center gap-2 bg-black/10 p-2 rounded-lg text-xs hover:bg-black/20 transition-colors"
                          >
                            <Paperclip class="w-3 h-3" />
                            <span class="truncate max-w-[120px]"
                              >{att.file_name}</span
                            >
                          </a>
                        {/if}
                      {/each}
                    </div>
                  {/if}
                </div>
              </div>
            {/each}
          </div>

          <div
            class="absolute bottom-0 left-0 right-0 p-4 bg-white border-t border-slate-100"
          >
            {#if currentTicket?.status === "resolved" || currentTicket?.status === "closed"}
              <div class="text-center py-2 bg-slate-50 rounded-xl">
                <p
                  class="text-[10px] font-bold uppercase tracking-widest text-slate-400"
                >
                  This ticket is {currentTicket?.status} and cannot be replied to.
                </p>
              </div>
            {:else}
              <form
                on:submit|preventDefault={sendMessage}
                class="flex items-center gap-2"
              >
                <input
                  type="file"
                  class="hidden"
                  bind:this={fileInput}
                  on:change={handleFileUpload}
                />
                <button
                  type="button"
                  on:click={() => fileInput.click()}
                  disabled={uploadingFile}
                  class="p-2 text-slate-400 hover:bg-slate-100 rounded-xl transition-colors disabled:opacity-50"
                >
                  <Paperclip
                    class={clsx("w-5 h-5", uploadingFile && "animate-pulse")}
                  />
                </button>
                <input
                  type="text"
                  bind:value={newMessage}
                  placeholder={uploadingFile ? "Uploading..." : "Message..."}
                  disabled={uploadingFile}
                  class="flex-1 p-2.5 bg-slate-50 border-none rounded-xl focus:ring-0 focus:outline-none text-sm disabled:opacity-50"
                />
                <button
                  type="submit"
                  disabled={!newMessage.trim()}
                  class="p-2.5 bg-indigo-600 text-white rounded-xl hover:bg-indigo-700 transition-colors disabled:opacity-50"
                >
                  <Send class="w-5 h-5" />
                </button>
              </form>
            {/if}
          </div>
        {/if}
      </div>
    </div>
  {/if}

  <button
    on:click={() => (isOpen = !isOpen)}
    class="w-16 h-16 bg-indigo-600 text-white rounded-full shadow-2xl flex items-center justify-center hover:scale-110 active:scale-95 transition-all group"
  >
    {#if isOpen}
      <X class="w-8 h-8" />
    {:else}
      <MessageCircle class="w-8 h-8" />
    {/if}
    <div
      class="absolute -top-1 -right-1 w-5 h-5 bg-red-500 rounded-full border-2 border-white scale-0 group-hover:scale-100 transition-transform"
    ></div>
  </button>
</div>
