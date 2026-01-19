<script>
</script>

<div class="min-h-screen bg-slate-50 flex flex-col">
  <header
    class="bg-white border-b border-slate-200 py-4 px-6 flex justify-between items-center"
  >
    <div class="flex items-center gap-2">
      <div
        class="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center"
      >
        <span class="text-white font-bold text-xl">S</span>
      </div>
      <h1 class="text-xl font-semibold text-slate-800 tracking-tight">
        ShipBee Admin
      </h1>
    </div>
    <nav class="flex gap-4">
      <a
        href="/admin"
        class="text-sm font-medium text-slate-600 hover:text-indigo-600 transition-colors"
        >Dashboard</a
      >
      <a
        href="/admin/tickets"
        class="text-sm font-medium text-slate-600 hover:text-indigo-600 transition-colors"
        >Tickets</a
      >
      <button
        class="text-sm font-medium bg-slate-100 px-4 py-2 rounded-full hover:bg-slate-200 transition-colors"
        >Logout</button
      >
    </nav>
  </header>

  <main class="flex-1 p-6 max-w-7xl mx-auto w-full">
    <slot />
  </main>
</div>
