<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1>Productivity</h1>
        <p>Organize tasks, habits, focus sessions, goals, and daily planning.</p>
      </div>
      <button class="primary-btn">Add Task</button>
    </div>

    <div class="cards-grid">
      <div class="summary-card">
        <h3>Today Tasks</h3>
        <strong>0</strong>
        <span>Tasks planned today</span>
      </div>

      <div class="summary-card">
        <h3>Completed</h3>
        <strong>0</strong>
        <span>Finished today</span>
      </div>

      <div class="summary-card">
        <h3>Focus Time</h3>
        <strong>0h</strong>
        <span>Tracked today</span>
      </div>

      <div class="summary-card">
        <h3>Habits</h3>
        <strong>0</strong>
        <span>Active habits</span>
      </div>
    </div>

    <div class="content-card">
      <h2>Productivity Workspace</h2>

      <div class="task-list">
        <div class="task-row">
          <input type="checkbox" />
          <div>
            <strong>Create first productivity task</strong>
            <p>This screen is ready for task management integration.</p>
          </div>
        </div>

        <div class="task-row">
          <input type="checkbox" />
          <div>
            <strong>Add goals and habits</strong>
            <p>Later this can connect to goals, routines, and focus sessions.</p>
          </div>
        </div>

        <div class="task-row">
          <input type="checkbox" />
          <div>
            <strong>Build daily planning system</strong>
            <p>Can include small tasks, subtasks, priorities, and progress.</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
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

.primary-btn {
  border: none;
  background: #2563eb;
  color: white;
  padding: 11px 18px;
  border-radius: 12px;
  font-weight: 700;
  cursor: pointer;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(160px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.summary-card,
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 20px;
  box-shadow: 0 8px 25px rgba(15, 23, 42, 0.06);
}

.summary-card h3 {
  margin: 0 0 10px;
  color: #374151;
  font-size: 14px;
}

.summary-card strong {
  display: block;
  font-size: 30px;
  color: #111827;
}

.summary-card span {
  color: #6b7280;
  font-size: 13px;
}

.task-list {
  display: grid;
  gap: 12px;
  margin-top: 16px;
}

.task-row {
  display: flex;
  gap: 14px;
  align-items: flex-start;
  padding: 16px;
  background: #f8fafc;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
}

.task-row p {
  margin: 5px 0 0;
  color: #6b7280;
}

@media (max-width: 900px) {
  .cards-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .page-header {
    flex-direction: column;
    align-items: flex-start;
  }
}

@media (max-width: 520px) {
  .cards-grid {
    grid-template-columns: 1fr;
  }
}
</style>
