<template>
  <div class="health-reports-page">
    <div class="page-header">
      <div>
        <h1>Health Reports</h1>
        <p>Health summaries between two selected dates with nutrition, hydration, weight, steps, labs, and medication adherence.</p>
      </div>

      <div class="header-actions">
        <button class="export-button secondary" @click="loadExportPreview">
          Export Preview
        </button>

        <button class="export-button" :disabled="exportingPdf" @click="downloadPdfReport">
          {{ exportingPdf ? 'Generating PDF...' : 'Export PDF' }}
        </button>
      </div>
    </div>

    <div class="filters-card">
      <div class="filter-group">
        <label>From Date</label>
        <input type="date" v-model="fromDate" @change="loadReport" />
      </div>

      <div class="filter-group">
        <label>To Date</label>
        <input type="date" v-model="toDate" @change="loadReport" />
      </div>

      <div class="filter-note">
        Report period: <strong>{{ fromDate }}</strong> to <strong>{{ toDate }}</strong>
      </div>
    </div>

    <div v-if="loading" class="state-card">
      Loading health report...
    </div>

    <div v-else-if="error" class="state-card error">
      {{ error }}
    </div>

    <div v-else-if="!report" class="state-card">
      No report data available.
    </div>

    <template v-else>
      <div class="summary-grid">
        <div class="summary-card">
          <span class="label">Health Status</span>
          <strong>{{ report.summary?.health_status || 'N/A' }}</strong>
        </div>

        <div class="summary-card">
          <span class="label">Calories</span>
          <strong>{{ report.summary?.total_calories || 0 }}</strong>
        </div>

        <div class="summary-card">
          <span class="label">Water</span>
          <strong>{{ report.hydration?.total_water_liters || 0 }} L</strong>
        </div>

        <div class="summary-card">
          <span class="label">Medication Adherence</span>
          <strong>{{ report.medication_adherence?.adherence_percent || 0 }}%</strong>
        </div>
      </div>

      <div class="reports-grid">
        <section class="report-card">
          <h2>Nutrition Totals</h2>

          <div class="metric-list">
            <div>
              <span>Protein</span>
              <strong>{{ report.nutrition?.totals?.protein_g || 0 }} g</strong>
            </div>
            <div>
              <span>Carbs</span>
              <strong>{{ report.nutrition?.totals?.carbs_g || 0 }} g</strong>
            </div>
            <div>
              <span>Fat</span>
              <strong>{{ report.nutrition?.totals?.fat_g || 0 }} g</strong>
            </div>
            <div>
              <span>Sodium</span>
              <strong>{{ report.nutrition?.totals?.sodium_mg || 0 }} mg</strong>
            </div>
            <div>
              <span>Potassium</span>
              <strong>{{ report.nutrition?.totals?.potassium_mg || 0 }} mg</strong>
            </div>
            <div>
              <span>Phosphorus</span>
              <strong>{{ report.nutrition?.totals?.phosphorus_mg || 0 }} mg</strong>
            </div>
          </div>

          <div class="warning-box" v-if="hasCkdWarnings">
            CKD warning: One or more nutrient limits are high.
          </div>
        </section>

        <section class="report-card">
          <h2>Hydration Totals</h2>
          <div class="big-number">{{ report.hydration?.total_water_ml || 0 }} ml</div>
          <p>Total water intake for selected period.</p>
        </section>

        <section class="report-card">
          <h2>Weight Trend</h2>
          <div class="metric-list">
            <div>
              <span>Start Weight</span>
              <strong>{{ report.weight?.start_weight || 'N/A' }} kg</strong>
            </div>
            <div>
              <span>Latest Weight</span>
              <strong>{{ report.weight?.latest_weight || 'N/A' }} kg</strong>
            </div>
            <div>
              <span>Change</span>
              <strong>{{ report.weight?.change_kg ?? 'N/A' }} kg</strong>
            </div>
          </div>
        </section>

        <section class="report-card">
          <h2>Steps Trend</h2>
          <div class="metric-list">
            <div>
              <span>Total Steps</span>
              <strong>{{ report.steps?.total_steps || 0 }}</strong>
            </div>
            <div>
              <span>Average Steps</span>
              <strong>{{ report.steps?.average_steps || 0 }}</strong>
            </div>
          </div>
        </section>

        <section class="report-card">
          <h2>Lab Results Trend</h2>
          <div class="metric-list">
            <div>
              <span>Total Tests</span>
              <strong>{{ report.lab_results?.total_tests || 0 }}</strong>
            </div>
            <div>
              <span>Abnormal Tests</span>
              <strong>{{ report.lab_results?.abnormal_tests || 0 }}</strong>
            </div>
          </div>

          <table v-if="report.lab_results?.items?.length">
            <thead>
              <tr>
                <th>Date</th>
                <th>Test</th>
                <th>Result</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(lab, index) in report.lab_results.items" :key="index">
                <td>{{ lab.test_date }}</td>
                <td>{{ lab.test_name }}</td>
                <td>{{ lab.result_value }} {{ lab.unit }}</td>
                <td>{{ lab.status }}</td>
              </tr>
            </tbody>
          </table>

          <p v-else>No lab results found for this period.</p>
        </section>

        <section class="report-card">
          <h2>Medication Adherence</h2>
          <div class="big-number">
            {{ report.medication_adherence?.adherence_percent || 0 }}%
          </div>

          <div class="metric-list">
            <div>
              <span>Total Doses</span>
              <strong>{{ report.medication_adherence?.total_doses || 0 }}</strong>
            </div>
            <div>
              <span>Taken</span>
              <strong>{{ report.medication_adherence?.taken_doses || 0 }}</strong>
            </div>
            <div>
              <span>Missed</span>
              <strong>{{ report.medication_adherence?.missed_doses || 0 }}</strong>
            </div>
          </div>
        </section>
      </div>

      <section class="export-card">
        <h2>Export-Ready PDF Structure</h2>
        <p>This screen is structured for future PDF export.</p>

        <ul>
          <li>Cover Page</li>
          <li>Health Summary</li>
          <li>Nutrition Summary</li>
          <li>Hydration Summary</li>
          <li>Weight Trend</li>
          <li>Steps Trend</li>
          <li>Lab Results Trend</li>
          <li>Medication Adherence</li>
          <li>Doctor Notes Placeholder</li>
        </ul>
      </section>
    </template>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { healthReportsService } from '@/services/healthReportsService'

const fromDate = ref(getStartOfCurrentMonth())
const toDate = ref(getTodayDate())

const report = ref(null)
const loading = ref(false)
const error = ref(null)
const exportPreview = ref(null)
const exportingPdf = ref(false)

const hasCkdWarnings = computed(() => {
  const warnings = report.value?.nutrition?.ckd_warnings

  if (!warnings) {
    return false
  }

  return Object.values(warnings).some(Boolean)
})

onMounted(() => {
  loadReport()
})

async function loadReport() {
  loading.value = true
  error.value = null

  try {
    validateDateRange()

    const response = await healthReportsService.getDateRangeReport(fromDate.value, toDate.value)

    report.value = response.data.data
  } catch (err) {
    console.error(err)
    error.value = 'Failed to load health report.'
  } finally {
    loading.value = false
  }
}

async function loadExportPreview() {
  try {
    const context = reportRequestContext()
    const response = await healthReportsService.getExportPreview(
      context.period,
      context.date,
      context.month,
      context.startDate,
      context.endDate
    )

    exportPreview.value = response.data.data
    alert('Export preview loaded successfully.')
  } catch (err) {
    console.error(err)
    alert(errorMessageFromResponse(err, 'Failed to load export preview.'))
  }
}

async function downloadPdfReport() {
  exportingPdf.value = true

  try {
    const context = reportRequestContext()
    const response = await healthReportsService.downloadPdfReport(
      context.period,
      context.date,
      context.month,
      context.startDate,
      context.endDate
    )

    const contentType = String(response.headers?.['content-type'] || '')

    if (contentType.includes('application/json')) {
      const text = await response.data.text()
      const payload = JSON.parse(text)
      throw new Error(payload.message || 'PDF export returned an error.')
    }

    const blob = new Blob([response.data], { type: 'application/pdf' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    const timestamp = new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-')

    link.href = url
    link.download = `nix-life-os-health-report-${fromDate.value}-to-${toDate.value}-${timestamp}.pdf`
    document.body.appendChild(link)
    link.click()
    link.remove()
    window.URL.revokeObjectURL(url)
  } catch (err) {
    console.error(err)
    alert(err?.message || 'Failed to export PDF report.')
  } finally {
    exportingPdf.value = false
  }
}

function reportRequestContext() {
  validateDateRange()

  return {
    period: 'date_range',
    date: fromDate.value,
    month: '',
    startDate: fromDate.value,
    endDate: toDate.value,
  }
}

function validateDateRange() {
  if (!fromDate.value) {
    fromDate.value = getStartOfCurrentMonth()
  }

  if (!toDate.value) {
    toDate.value = getTodayDate()
  }

  if (fromDate.value > toDate.value) {
    const originalFrom = fromDate.value
    fromDate.value = toDate.value
    toDate.value = originalFrom
  }
}

function errorMessageFromResponse(err, fallback) {
  return err?.response?.data?.message || err?.message || fallback
}

function getTodayDate() {
  return formatDateValue(new Date())
}

function getStartOfCurrentMonth() {
  const date = new Date()

  return formatDateValue(new Date(date.getFullYear(), date.getMonth(), 1))
}

function formatDateValue(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')

  return `${year}-${month}-${day}`
}
</script>

<style scoped>
.health-reports-page {
  padding: 24px;
  background: #f8fafc;
  min-height: 100vh;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 24px;
}

.header-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 800;
  color: #0f172a;
  margin: 0 0 8px;
}

.page-header p {
  color: #64748b;
  margin: 0;
}

.export-button {
  background: #0f172a;
  color: white;
  border: none;
  border-radius: 10px;
  padding: 10px 16px;
  cursor: pointer;
  font-weight: 700;
}

.export-button.secondary {
  background: #e2e8f0;
  color: #0f172a;
}

.export-button:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.filters-card,
.state-card,
.report-card,
.export-card,
.summary-card {
  background: white;
  border-radius: 16px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.04);
}

.filters-card {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  padding: 18px;
  margin-bottom: 24px;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.filter-group label {
  font-size: 13px;
  font-weight: 700;
  color: #475569;
}

.filter-group input,
.filter-group select {
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  padding: 10px;
  min-width: 180px;
}

.state-card {
  padding: 24px;
  color: #475569;
}

.state-card.error {
  color: #b91c1c;
  background: #fef2f2;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(160px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.summary-card {
  padding: 18px;
}

.summary-card .label {
  display: block;
  font-size: 13px;
  color: #64748b;
  margin-bottom: 8px;
}

.summary-card strong {
  font-size: 24px;
  color: #0f172a;
}

.reports-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(280px, 1fr));
  gap: 20px;
}

.report-card {
  padding: 20px;
}

.report-card h2,
.export-card h2 {
  margin: 0 0 16px;
  font-size: 20px;
  color: #0f172a;
}

.metric-list {
  display: grid;
  gap: 12px;
}

.metric-list div {
  display: flex;
  justify-content: space-between;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 8px;
}

.metric-list span {
  color: #64748b;
}

.metric-list strong {
  color: #0f172a;
}

.big-number {
  font-size: 36px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 8px;
}

.warning-box {
  margin-top: 16px;
  padding: 12px;
  border-radius: 10px;
  background: #fff7ed;
  color: #c2410c;
  font-weight: 700;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 12px;
}

th,
td {
  text-align: left;
  padding: 10px;
  border-bottom: 1px solid #e2e8f0;
  font-size: 14px;
}

th {
  color: #475569;
  background: #f8fafc;
}

.export-card {
  margin-top: 24px;
  padding: 20px;
}

.export-card ul {
  margin: 12px 0 0;
  padding-left: 20px;
  color: #475569;
}

@media (max-width: 900px) {
  .summary-grid,
  .reports-grid {
    grid-template-columns: 1fr;
  }

  .page-header {
    flex-direction: column;
  }
}

/* Health report date range readability fix */
.health-reports-page input,
.health-reports-page select,
.health-reports-page textarea,
.health-reports-page input:disabled,
.health-reports-page select:disabled,
.health-reports-page textarea:disabled {
  background-color: #ffffff !important;
  color: #020617 !important;
  -webkit-text-fill-color: #020617 !important;
  caret-color: #2563eb !important;
  opacity: 1 !important;
  color-scheme: light !important;
}

.health-reports-page input::placeholder,
.health-reports-page textarea::placeholder {
  color: #64748b !important;
  -webkit-text-fill-color: #64748b !important;
  opacity: 1 !important;
}

.health-reports-page input[type="date"]::-webkit-calendar-picker-indicator {
  opacity: 1 !important;
  cursor: pointer;
}

.filter-note {
  align-self: flex-end;
  color: #475569;
  font-size: 14px;
  padding: 10px 0;
}

.filter-note strong {
  color: #0f172a;
}

</style>
