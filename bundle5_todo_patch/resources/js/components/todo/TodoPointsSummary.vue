<template>
  <section class="todo-points-summary">
    <div class="points-card points-card--total">
      <span class="points-label">Total Completed Points</span>
      <strong>{{ number(points.total_completed_points) }}</strong>
    </div>

    <div class="points-grid">
      <div class="points-card">
        <span class="points-label">General</span>
        <strong>{{ number(points.general_points) }}</strong>
      </div>
      <div class="points-card">
        <span class="points-label">Monthly</span>
        <strong>{{ number(points.monthly_points) }}</strong>
      </div>
      <div class="points-card">
        <span class="points-label">Weekly</span>
        <strong>{{ number(points.weekly_points) }}</strong>
      </div>
      <div class="points-card">
        <span class="points-label">Daily</span>
        <strong>{{ number(points.daily_points) }}</strong>
      </div>
    </div>

    <div v-if="points.project_points?.length" class="project-points">
      <h3>Project Points</h3>
      <div v-for="project in points.project_points" :key="project.project_id" class="project-point-row">
        <span>{{ project.project_name || `Project #${project.project_id}` }}</span>
        <strong>{{ number(project.points) }}</strong>
      </div>
    </div>
  </section>
</template>

<script setup>
defineProps({
  points: {
    type: Object,
    default: () => ({
      total_completed_points: 0,
      general_points: 0,
      monthly_points: 0,
      weekly_points: 0,
      daily_points: 0,
      project_points: [],
    }),
  },
})

const number = value => new Intl.NumberFormat().format(Number(value || 0))
</script>

<style scoped>
.todo-points-summary {
  display: grid;
  gap: 1rem;
}

.points-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 0.75rem;
}

.points-card,
.project-points {
  border: 1px solid rgba(148, 163, 184, 0.25);
  border-radius: 16px;
  padding: 1rem;
  background: rgba(15, 23, 42, 0.08);
}

.points-card--total {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.points-label {
  display: block;
  font-size: 0.85rem;
  opacity: 0.75;
  margin-bottom: 0.35rem;
}

.project-point-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
  border-top: 1px solid rgba(148, 163, 184, 0.2);
}
</style>
