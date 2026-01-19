<script>
  import CustomerWidget from "$lib/components/CustomerWidget.svelte";
  import {
    ArrowRight,
    LayoutDashboard,
    MessageSquare,
    Zap,
    Shield,
    Globe,
  } from "lucide-svelte";
</script>

<div
  class="min-h-screen bg-white text-slate-900 selection:bg-indigo-100 selection:text-indigo-900"
>
  <!-- Hero Section -->
  <nav class="max-w-7xl mx-auto px-6 py-8 flex justify-between items-center">
    <div class="flex items-center gap-2">
      <div
        class="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center shadow-lg shadow-indigo-200"
      >
        <span class="text-white font-bold text-2xl leading-none">S</span>
      </div>
      <span class="text-xl font-bold tracking-tight">ShipBee Support</span>
    </div>
    <div class="flex items-center gap-6">
      <a
        href="/admin"
        class="text-sm font-semibold text-slate-600 hover:text-indigo-600 transition-colors flex items-center gap-2"
      >
        <LayoutDashboard class="w-4 h-4" />
        Admin Portal
      </a>
      <a
        href="/admin"
        class="bg-indigo-600 text-white px-5 py-2.5 rounded-full text-sm font-bold shadow-lg shadow-indigo-100 hover:bg-indigo-700 transition-all hover:scale-105 active:scale-95"
      >
        Get Started
      </a>
    </div>
  </nav>

  <main>
    <section
      class="max-w-7xl mx-auto px-6 py-20 lg:py-32 flex flex-col lg:flex-row items-center gap-20"
    >
      <div class="flex-1 space-y-8">
        <div
          class="inline-flex items-center gap-2 px-4 py-2 bg-indigo-50 text-indigo-700 rounded-full text-xs font-bold uppercase tracking-widest border border-indigo-100"
        >
          <Zap class="w-3 h-3" />
          Real-time Support Infrastructure
        </div>
        <h1
          class="text-6xl lg:text-7xl font-extrabold tracking-tight leading-[1.1]"
        >
          The only support tool your <span class="text-indigo-600"
            >customers</span
          > will love.
        </h1>
        <p class="text-xl text-slate-500 leading-relaxed max-w-2xl">
          Beautifully designed widgets, real-time ticket management, and
          high-performance fulfillment support. All in one place.
        </p>
        <div class="flex flex-wrap gap-4 pt-4">
          <a
            href="/admin"
            class="bg-indigo-600 text-white px-8 py-4 rounded-2xl font-bold text-lg shadow-xl shadow-indigo-200 hover:bg-indigo-700 transition-all hover:shadow-2xl flex items-center gap-3 group"
          >
            Explore Admin Dashboard
            <ArrowRight
              class="w-5 h-5 group-hover:translate-x-1 transition-transform"
            />
          </a>
          <div class="flex -space-x-3 items-center ml-4">
            {#each [1, 2, 3, 4] as i}
              <div
                class="w-10 h-10 rounded-full border-4 border-white bg-slate-100 flex items-center justify-center overflow-hidden"
              >
                <img
                  src="https://api.dicebear.com/7.x/avataaars/svg?seed={i}"
                  alt="avatar"
                />
              </div>
            {/each}
            <span class="ml-6 text-sm font-medium text-slate-500"
              >Trusted by 500+ developers</span
            >
          </div>
        </div>
      </div>

      <div class="flex-1 relative">
        <div
          class="absolute -inset-20 bg-indigo-100/50 rounded-full blur-[120px] -z-10"
        ></div>
        <div
          class="bg-white rounded-[32px] shadow-2xl border border-slate-100 p-8 rotate-2 hover:rotate-0 transition-transform duration-700"
        >
          <div class="flex gap-4 mb-8">
            <div class="w-3 h-3 rounded-full bg-red-400"></div>
            <div class="w-3 h-3 rounded-full bg-amber-400"></div>
            <div class="w-3 h-3 rounded-full bg-emerald-400"></div>
          </div>
          <div class="space-y-6">
            <div class="h-4 w-1/3 bg-slate-100 rounded-full"></div>
            <div class="h-4 w-full bg-slate-50 rounded-full"></div>
            <div class="h-4 w-5/6 bg-slate-50 rounded-full"></div>
            <div
              class="h-32 w-full bg-indigo-50/50 rounded-2xl border border-indigo-100 flex items-center justify-center"
            >
              <MessageSquare class="w-12 h-12 text-indigo-300" />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div class="h-20 bg-slate-50 rounded-2xl"></div>
              <div class="h-20 bg-slate-50 rounded-2xl"></div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section class="bg-slate-50 py-32">
      <div class="max-w-7xl mx-auto px-6">
        <div class="text-center space-y-4 mb-20">
          <h2 class="text-4xl font-bold tracking-tight">
            Everything you need to scale
          </h2>
          <p class="text-slate-500 max-w-xl mx-auto">
            ShipBee provides the building blocks for enterprise-grade customer
            communication.
          </p>
        </div>
        <div class="grid md:grid-cols-3 gap-8">
          {#each [{ title: "Real-time Sync", desc: "Messages and statuses update instantly across all sessions.", icon: Zap }, { title: "Secure Attachments", desc: "Securely upload and share documents, images, and videos.", icon: Shield }, { title: "Global Edge Functions", desc: "Powered by Supabase Edge Functions for fast processing.", icon: Globe }] as feature}
            <div
              class="bg-white p-8 rounded-3xl border border-slate-200 hover:shadow-xl transition-all hover:-translate-y-1"
            >
              <div
                class="w-12 h-12 bg-indigo-50 text-indigo-600 rounded-xl flex items-center justify-center mb-6"
              >
                <svelte:component this={feature.icon} class="w-6 h-6" />
              </div>
              <h3 class="text-xl font-bold mb-3">{feature.title}</h3>
              <p class="text-slate-500 leading-relaxed">{feature.desc}</p>
            </div>
          {/each}
        </div>
      </div>
    </section>
  </main>

  <footer class="py-12 border-t border-slate-100">
    <div class="max-w-7xl mx-auto px-6 text-center text-slate-400 text-sm">
      &copy; 2024 ShipBee Fulfillment Support System. All rights reserved.
    </div>
  </footer>

  <!-- The Widget -->
  <CustomerWidget />
</div>

<style>
  :global(body) {
    font-family: "Inter", sans-serif;
  }
</style>
