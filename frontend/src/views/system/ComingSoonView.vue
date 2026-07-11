<template>
  <main class="system-page" aria-labelledby="coming-soon-title">
    <section class="system-card">
      <div class="logo-mark" aria-hidden="true">N</div>
      <p class="eyebrow">Nix Life OS</p>
      <h1 id="coming-soon-title">Coming soon</h1>
      <p class="message">
        We are preparing the next Nix Life OS experience. Please check back shortly.
      </p>
      <RouterLink to="/" class="primary-action">Back to Home</RouterLink>
    </section>
  </main>
</template>

<script setup lang="ts"></script>

<style scoped>
.system-page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px;
  color: #e2e8f0;
  background:
    radial-gradient(circle at top, rgba(14, 165, 233, 0.22), transparent 42%),
    linear-gradient(145deg, #020617, #0f172a);
}
.system-card {
  width: min(100%, 560px);
  padding: clamp(28px, 6vw, 52px);
  text-align: center;
  border: 1px solid rgba(148, 163, 184, 0.25);
  border-radius: 28px;
  background: rgba(15, 23, 42, 0.78);
  box-shadow: 0 30px 80px rgba(2, 6, 23, 0.5);
  backdrop-filter: blur(18px);
}
.logo-mark {
  width: 72px;
  height: 72px;
  margin: 0 auto 24px;
  display: grid;
  place-items: center;
  border-radius: 22px;
  font-size: 34px;
  font-weight: 900;
  color: #fff;
  background: linear-gradient(135deg, #06b6d4, #7c3aed);
}
.eyebrow {
  margin: 0 0 10px;
  font-weight: 700;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #67e8f9;
}
h1 {
  margin: 0;
  font-size: clamp(42px, 9vw, 72px);
  line-height: 1;
}
.message {
  margin: 24px auto 32px;
  max-width: 440px;
  color: #cbd5e1;
  font-size: 18px;
  line-height: 1.7;
}
.primary-action {
  min-height: 50px;
  padding: 0 24px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 14px;
  color: #fff;
  font-weight: 700;
  text-decoration: none;
  background: linear-gradient(135deg, #0891b2, #7c3aed);
}
.primary-action:hover,
.primary-action:focus-visible { transform: translateY(-2px); }
@media (prefers-color-scheme: light) {
  .system-page { color: #0f172a; background: linear-gradient(145deg, #ecfeff, #eef2ff); }
  .system-card { background: rgba(255, 255, 255, 0.9); box-shadow: 0 30px 80px rgba(51, 65, 85, 0.15); }
  .message { color: #475569; }
  .eyebrow { color: #0e7490; }
}
</style>
