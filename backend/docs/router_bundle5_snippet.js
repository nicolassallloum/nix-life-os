// Add this route to your Vue router if there is not already a To-Do board route.
// Adjust the import path if your router uses a different alias.
{
  path: '/todo/board',
  name: 'TodoBoard',
  component: () => import('@/pages/todo/TodoBoard.vue'),
  meta: { requiresAuth: true, title: 'Task Organization' },
}
