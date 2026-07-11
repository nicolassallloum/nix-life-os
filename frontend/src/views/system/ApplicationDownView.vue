<template>
  <main class="system-page" aria-labelledby="application-down-title">
    <section class="system-card">
      <div class="status-icon" aria-hidden="true">!</div>
      <p class="eyebrow">Service status</p>
      <h1 id="application-down-title">Temporarily unavailable</h1>
      <p class="message">
        Nix Life OS cannot be reached right now. Your data is safe. Retry the request or return home.
      </p>
      <div class="actions">
        <button type="button" class="primary-action" @click="retryPage">Retry</button>
        <RouterLink to="/" class="secondary-action">Back to Home</RouterLink>
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
const retryPage = (): void => window.location.reload()
</script>

<style scoped>
.system-page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px;
  color: #e2e8f0;
  background:
    radial-gradient(circle at top, rgba(244, 63, 94, 0.2), transparent 42%),
    linear-gradient(145deg, #020617, #0f172a);
}
.system-card {
  width: min(100%, 620px);
  padding: clamp(28px, 6vw, 52px);
  text-align: center;
  border: 1px solid rgba(148, 163, 184, 0.25);
  border-radius: 28px;
  background: rgba(15, 23, 42, 0.8);
  box-shadow: 0 30px 80px rgba(2, 6, 23, 0.5);
  backdrop-filter: blur(18px);
}
.status-icon {
  width: 72px;
  height: 72px;
  margin: 0 auto 24px;
  display: grid;
  place-items: center;
  border-radius: 50%;
  border: 2px solid #fb7185;
  color: #fecdd3;
  font-size: 38px;
  font-weight: 900;
}
.eyebrow { margin: 0 0 10px; color: #fda4af; font-weight: 700; letter-spacing: 0.16em; text-transform: uppercase; }
h1 { margin: 0; font-size: clamp(36px, 8vw, 64px); line-height: 1.05; }
.message { margin: 24px auto 32px; max-width: 500px; color: #cbd5e1; font-size: 18px; line-height: 1.7; }
.actions { display: flex; justify-content: center; gap: 14px; flex-wrap: wrap; }
.primary-action,
.secondary-action {
  min-height: 50px;
  min-width: 150px;
  padding: 0 22px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 14px;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
  text-decoration: none;
}
.primary-action { border: 0; color: #fff; background: linear-gradient(135deg, #e11d48, #7c3aed); }
.secondary-action { border: 1px solid #475569; color: #e2e8f0; background: transparent; }
.primary-action:hover,
.primary-action:focus-visible,
.secondary-action:hover,
.secondary-action:focus-visible { transform: translateY(-2px); }
@media (max-width: 420px) { .actions > * { width: 100%; } }
@media (prefers-color-scheme: light) {
  .system-page { color: #0f172a; background: linear-gradient(145deg, #fff1f2, #eef2ff); }
  .system-card { background: rgba(255, 255, 255, 0.92); box-shadow: 0 30px 80px rgba(51, 65, 85, 0.15); }
  .message { color: #475569; }
  .secondary-action { color: #334155; border-color: #cbd5e1; }
  .eyebrow { color: #be123c; }
}
</style>
