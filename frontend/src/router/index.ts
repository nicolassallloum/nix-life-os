import { createRouter, createWebHistory } from 'vue-router'

const AIRecommendationsView = () => import('@/views/ai/AIRecommendationsView.vue')

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/ai/recommendations',
    },
    {
      path: '/ai/recommendations',
      name: 'ai-recommendations',
      component: AIRecommendationsView,
      meta: {
        requiresAuth: true,
        title: 'AI Recommendations',
      },
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/ai/recommendations',
    },
  ],
})

router.beforeEach((to, _from, next) => {
  document.title = to.meta?.title
    ? `${String(to.meta.title)} - Nix Life OS`
    : 'Nix Life OS'

  const requiresAuth = Boolean(to.meta?.requiresAuth)

  const token =
    localStorage.getItem('token') ||
    localStorage.getItem('auth_token') ||
    localStorage.getItem('access_token')

  if (requiresAuth && !token) {
    console.warn('No auth token found. AI API requests may return 401.')
  }

  next()
})

export default router