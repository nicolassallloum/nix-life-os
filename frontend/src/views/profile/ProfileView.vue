<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1>Profile</h1>
        <p>Manage your profile, level, points, achievements, and activity history.</p>
      </div>

      <div class="header-actions">
        <button class="secondary-btn" type="button" :disabled="loading" @click="loadProfile">
          Refresh
        </button>
        <button class="primary-btn" type="button" :disabled="saving" @click="saveProfile">
          {{ saving ? 'Saving...' : 'Save Profile' }}
        </button>
      </div>
    </div>

    <div v-if="errorMessage" class="alert error-alert">
      {{ errorMessage }}
    </div>

    <div v-if="successMessage" class="alert success-alert">
      {{ successMessage }}
    </div>

    <div v-if="loading" class="loading-card">
      Loading profile level and points...
    </div>

    <div v-else class="profile-layout">
      <aside class="profile-card">
        <div class="avatar-wrap">
          <img
            v-if="profile.user.avatar_url"
            class="avatar-img"
            :src="profile.user.avatar_url"
            :alt="profile.user.name || 'User avatar'"
          />
          <div v-else class="avatar-fallback">
            {{ initials }}
          </div>
        </div>

        <h2>{{ profile.user.name || 'Nix Life OS User' }}</h2>
        <p>{{ profile.user.email || 'Connected User' }}</p>

        <div class="level-badge">
          Level {{ profile.points.level }}
        </div>

        <div class="profile-meta">
          <div>
            <span>Status</span>
            <strong>{{ profile.user.status || 'Active' }}</strong>
          </div>
          <div>
            <span>Plan</span>
            <strong>Personal OS</strong>
          </div>
        </div>

        <div class="points-summary">
          <div>
            <span>Current Points</span>
            <strong>{{ profile.points.points }}</strong>
          </div>
          <div>
            <span>Total Points</span>
            <strong>{{ profile.points.total_points }}</strong>
          </div>
        </div>
      </aside>

      <main class="main-grid">
        <section class="content-card">
          <div class="section-header">
            <div>
              <h2>User Information</h2>
              <p>Basic account details connected to your Nix Life OS profile.</p>
            </div>
          </div>

          <form class="form-grid" @submit.prevent="saveProfile">
            <label>
              <span>Name</span>
              <input v-model.trim="form.name" type="text" placeholder="Full name" />
            </label>

            <label>
              <span>Email</span>
              <input v-model.trim="form.email" type="email" placeholder="Email address" />
            </label>

            <label>
              <span>Phone</span>
              <input v-model.trim="form.phone" type="text" placeholder="Phone number" />
            </label>

            <label>
              <span>Role</span>
              <input value="Application Owner / User" type="text" disabled />
            </label>
          </form>
        </section>

        <section class="content-card">
          <div class="section-header">
            <div>
              <h2>Level Progress</h2>
              <p>
                {{ profile.points.points_to_next_level }}
                points remaining to reach Level {{ profile.points.level + 1 }}.
              </p>
            </div>
            <div class="points-pill">
              {{ profile.points.progress_percent }}%
            </div>
          </div>

          <div class="progress-track">
            <div
              class="progress-fill"
              :style="{ width: `${profile.points.progress_percent}%` }"
            ></div>
          </div>

          <div class="progress-meta">
            <span>Total: {{ profile.points.total_points }}</span>
            <span>Next Level: {{ profile.points.next_level_points }}</span>
          </div>
        </section>

        <section class="content-card">
          <div class="section-header">
            <div>
              <h2>How to Gain Points</h2>
              <p>Complete these actions across Nix Life OS to level up faster.</p>
            </div>
          </div>

          <div class="ideas-grid">
            <div
              v-for="idea in profile.points.earning_ideas"
              :key="`${idea.module}-${idea.action}`"
              class="idea-card"
            >
              <div>
                <span class="idea-module">{{ idea.module }}</span>
                <strong>{{ idea.action }}</strong>
                <p>{{ idea.description }}</p>
              </div>
              <b>+{{ idea.points }}</b>
            </div>

            <div v-if="!profile.points.earning_ideas.length" class="empty-state">
              No level-up ideas available yet.
            </div>
          </div>
        </section>

        <section class="content-card">
          <div class="section-header">
            <div>
              <h2>Achievements</h2>
              <p>Milestones unlocked from your activity across all modules.</p>
            </div>
          </div>

          <div class="achievements-grid">
            <div
              v-for="achievement in profile.points.achievements"
              :key="achievement.key"
              class="achievement-card"
              :class="{ unlocked: achievement.unlocked }"
            >
              <div class="achievement-icon">
                {{ achievement.unlocked ? '🏆' : '🔒' }}
              </div>
              <div>
                <strong>{{ achievement.title }}</strong>
                <span>{{ achievement.description }}</span>
              </div>
            </div>

            <div v-if="!profile.points.achievements.length" class="empty-state">
              No achievements available yet.
            </div>
          </div>
        </section>

        <section class="content-card history-card">
          <div class="section-header">
            <div>
              <h2>Points History</h2>
              <p>Recent points earned from health, finance, productivity, projects, and AI.</p>
            </div>
          </div>

          <div v-if="pointLogs.length" class="history-list">
            <div v-for="log in pointLogs" :key="log.id" class="history-item">
              <div>
                <strong>{{ formatAction(log.action_name) }}</strong>
                <span>{{ log.module }} · {{ formatDate(log.created_at) }}</span>
              </div>
              <b>+{{ log.points }}</b>
            </div>
          </div>

          <div v-else class="empty-state">
            No points history yet. Start using your modules to earn points.
          </div>
        </section>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'

type UserProfile = {
  id: string
  name: string
  email: string
  phone: string | null
  status: string | null
  avatar_url: string
  created_at: string | null
  updated_at: string | null
}

type Achievement = {
  key: string
  title: string
  description: string
  unlocked: boolean
}

type EarningIdea = {
  module: string
  action: string
  points: number
  description: string
}

type PointsSummary = {
  points: number
  level: number
  total_points: number
  next_level_points: number
  points_to_next_level: number
  progress_percent: number
  achievements: Achievement[]
  earning_ideas: EarningIdea[]
}

type PointLog = {
  id: number
  module: string
  action_name: string
  points: number
  reference_id: string | null
  created_at: string
}

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pointLogs = ref<PointLog[]>([])

const profile = reactive<{
  user: UserProfile
  points: PointsSummary
}>({
  user: {
    id: '',
    name: '',
    email: '',
    phone: '',
    status: '',
    avatar_url: '',
    created_at: null,
    updated_at: null,
  },
  points: {
    points: 0,
    level: 1,
    total_points: 0,
    next_level_points: 100,
    points_to_next_level: 100,
    progress_percent: 0,
    achievements: [],
    earning_ideas: [],
  },
})

const form = reactive({
  name: '',
  email: '',
  phone: '',
})

const initials = computed(() => {
  const name = profile.user.name || 'Nix User'
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join('')
})

function authToken(): string {
  return localStorage.getItem('auth_token') || localStorage.getItem('token') || ''
}

async function apiRequest(path: string, options: RequestInit = {}) {
  const token = authToken()

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers || {}),
    },
  })

  const data = await response.json().catch(() => ({}))

  if (!response.ok) {
    throw new Error(data.message || `Request failed with status ${response.status}`)
  }

  return data
}

function applyProfile(data: any) {
  const user = data?.user || {}
  const points = data?.points || {}

  profile.user = {
    id: user.id || '',
    name: user.name || '',
    email: user.email || '',
    phone: user.phone || '',
    status: user.status || '',
    avatar_url: user.avatar_url || '',
    created_at: user.created_at || null,
    updated_at: user.updated_at || null,
  }

  profile.points = {
    points: Number(points.points || 0),
    level: Number(points.level || 1),
    total_points: Number(points.total_points || 0),
    next_level_points: Number(points.next_level_points || 100),
    points_to_next_level: Number(points.points_to_next_level || 100),
    progress_percent: Number(points.progress_percent || 0),
    achievements: Array.isArray(points.achievements) ? points.achievements : [],
    earning_ideas: Array.isArray(points.earning_ideas) ? points.earning_ideas : [],
  }

  form.name = profile.user.name
  form.email = profile.user.email
  form.phone = profile.user.phone || ''
}

async function loadProfile() {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const [profileResponse, logsResponse] = await Promise.all([
      apiRequest('/profile'),
      apiRequest('/profile/point-logs?limit=30'),
    ])

    applyProfile(profileResponse.data)
    pointLogs.value = Array.isArray(logsResponse.data) ? logsResponse.data : []
  } catch (error: any) {
    errorMessage.value = error.message || 'Unable to load profile.'
  } finally {
    loading.value = false
  }
}

async function saveProfile() {
  saving.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const response = await apiRequest('/profile', {
      method: 'PUT',
      body: JSON.stringify({
        name: form.name,
        email: form.email,
        phone: form.phone || null,
      }),
    })

    applyProfile(response.data)
    successMessage.value = 'Profile saved successfully.'
  } catch (error: any) {
    errorMessage.value = error.message || 'Unable to save profile.'
  } finally {
    saving.value = false
  }
}

function formatAction(action: string): string {
  return action
    .replaceAll('_', ' ')
    .replaceAll('.', ' ')
    .replace(/\b\w/g, (char) => char.toUpperCase())
}

function formatDate(value: string): string {
  if (!value) {
    return '-'
  }

  return new Date(value).toLocaleString()
}

onMounted(loadProfile)
</script>

<style scoped>
.page {
  padding: 24px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
  margin-bottom: 24px;
}

.page-header h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 800;
  color: #111827;
}

.page-header p {
  margin: 6px 0 0;
  color: #6b7280;
}

.header-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.primary-btn,
.secondary-btn {
  border: none;
  padding: 11px 18px;
  border-radius: 12px;
  font-weight: 800;
  cursor: pointer;
}

.primary-btn {
  background: #2563eb;
  color: white;
}

.secondary-btn {
  background: #eef2ff;
  color: #1d4ed8;
}

.primary-btn:disabled,
.secondary-btn:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.alert,
.loading-card {
  border-radius: 16px;
  padding: 14px 16px;
  margin-bottom: 18px;
  font-weight: 700;
}

.error-alert {
  background: #fef2f2;
  color: #991b1b;
  border: 1px solid #fecaca;
}

.success-alert {
  background: #ecfdf5;
  color: #047857;
  border: 1px solid #bbf7d0;
}

.loading-card {
  background: white;
  border: 1px solid #e5e7eb;
  color: #6b7280;
}

.profile-layout {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 18px;
}

.profile-card,
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 24px;
  box-shadow: 0 8px 25px rgba(15, 23, 42, 0.06);
}

.profile-card {
  text-align: center;
  align-self: start;
}

.avatar-wrap {
  width: 96px;
  height: 96px;
  margin: 0 auto 16px;
}

.avatar-img,
.avatar-fallback {
  width: 96px;
  height: 96px;
  border-radius: 50%;
}

.avatar-img {
  object-fit: cover;
}

.avatar-fallback {
  background: #2563eb;
  color: white;
  display: grid;
  place-items: center;
  font-size: 34px;
  font-weight: 900;
}

.profile-card h2 {
  margin: 0;
  color: #111827;
}

.profile-card p {
  color: #6b7280;
  word-break: break-word;
}

.level-badge {
  display: inline-flex;
  margin-top: 8px;
  padding: 8px 14px;
  border-radius: 999px;
  background: #eff6ff;
  color: #1d4ed8;
  font-weight: 900;
}

.profile-meta,
.points-summary {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-top: 20px;
}

.profile-meta div,
.points-summary div {
  background: #f8fafc;
  border-radius: 14px;
  padding: 14px;
}

.profile-meta span,
.points-summary span,
.form-grid span,
.progress-meta,
.achievement-card span,
.history-item span {
  display: block;
  color: #6b7280;
  font-size: 13px;
}

.profile-meta strong,
.points-summary strong {
  display: block;
  margin-top: 5px;
  color: #111827;
}

.main-grid {
  display: grid;
  gap: 18px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
  margin-bottom: 18px;
}

.section-header h2 {
  margin: 0;
  color: #111827;
}

.section-header p {
  margin: 6px 0 0;
  color: #6b7280;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.form-grid label {
  display: grid;
  gap: 8px;
}

.form-grid input {
  width: 100%;
  border: 1px solid #dbe3ef;
  border-radius: 12px;
  padding: 12px 13px;
  color: #111827;
  outline: none;
}

.form-grid input:focus {
  border-color: #2563eb;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
}

.form-grid input:disabled {
  background: #f8fafc;
  color: #64748b;
}

.points-pill {
  background: #2563eb;
  color: white;
  border-radius: 999px;
  padding: 8px 13px;
  font-weight: 900;
}

.progress-track {
  height: 14px;
  background: #e5e7eb;
  border-radius: 999px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  min-width: 0;
  background: #2563eb;
  border-radius: inherit;
  transition: width 0.25s ease;
}

.progress-meta {
  display: flex;
  justify-content: space-between;
  margin-top: 10px;
}

.achievements-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.achievement-card {
  display: flex;
  gap: 12px;
  align-items: flex-start;
  background: #f8fafc;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 14px;
  opacity: 0.7;
}

.achievement-card.unlocked {
  background: #fffbeb;
  border-color: #fde68a;
  opacity: 1;
}

.achievement-icon {
  font-size: 24px;
}

.achievement-card strong,
.history-item strong {
  display: block;
  color: #111827;
}

.history-list {
  display: grid;
  gap: 10px;
}

.history-item {
  display: flex;
  justify-content: space-between;
  gap: 14px;
  align-items: center;
  border-bottom: 1px solid #f1f5f9;
  padding: 12px 0;
}

.history-item:last-child {
  border-bottom: none;
}

.history-item b {
  color: #047857;
  white-space: nowrap;
}

.empty-state {
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 14px;
  padding: 18px;
  color: #64748b;
  grid-column: 1 / -1;
}

@media (max-width: 980px) {
  .profile-layout {
    grid-template-columns: 1fr;
  }

  .page-header,
  .section-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .form-grid,
  .achievements-grid {
    grid-template-columns: 1fr;
  }
}

.ideas-grid {
  display: grid;
  gap: 1rem;
}

.idea-card {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  border: 1px solid rgba(148, 163, 184, 0.18);
  border-radius: 1rem;
  padding: 1rem;
  background: rgba(15, 23, 42, 0.72);
}

.idea-card strong {
  display: block;
  margin-top: 0.35rem;
  color: #f8fafc;
}

.idea-card p {
  margin: 0.35rem 0 0;
  color: #94a3b8;
  font-size: 0.9rem;
  line-height: 1.45;
}

.idea-card b {
  flex-shrink: 0;
  border-radius: 999px;
  padding: 0.35rem 0.7rem;
  background: rgba(34, 197, 94, 0.14);
  color: #86efac;
  font-size: 0.9rem;
}

.idea-module {
  display: inline-flex;
  border-radius: 999px;
  padding: 0.25rem 0.6rem;
  background: rgba(99, 102, 241, 0.18);
  color: #c7d2fe;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

</style>
