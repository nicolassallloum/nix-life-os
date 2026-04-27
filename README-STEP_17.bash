🔹 STEP 17 — Unified Dashboard UI
NIX LIFE OS — Main Dashboard Frontend
This step builds the main SaaS-style unified dashboard that combines:


Finance balance


Health steps


Calories / nutrition


Project progress


Charts


Recent activity


Modern SaaS layout using Vue 3 + Tailwind



1. Frontend Files To Create
Inside your frontend project:
cd /u01/nix-life-os/frontend
Create this structure:
mkdir -p src/views/dashboardmkdir -p src/components/dashboardmkdir -p src/services
You will add:
src/views/dashboard/UnifiedDashboardView.vuesrc/components/dashboard/DashboardStatCard.vuesrc/components/dashboard/DashboardProgressCard.vuesrc/components/dashboard/DashboardRecentActivity.vuesrc/components/dashboard/DashboardMiniChart.vuesrc/services/dashboardApi.js

2. Install Chart Package
Run:
npm install chart.js vue-chartjs

3. Create Dashboard API Service
Create:
nano src/services/dashboardApi.js
Paste:
import axios from "axios";const API_BASE_URL = "http://127.0.0.1:8000/api/v1";function getAuthHeaders() {  const token = localStorage.getItem("token");  return {    Accept: "application/json",    Authorization: `Bearer ${token}`,  };}export async function getUnifiedDashboardSummary() {  const response = await axios.get(`${API_BASE_URL}/dashboard/summary`, {    headers: getAuthHeaders(),  });  return response.data;}export async function getUnifiedDashboardKpis() {  const response = await axios.get(`${API_BASE_URL}/dashboard/kpis`, {    headers: getAuthHeaders(),  });  return response.data;}export async function getUnifiedDashboardActivity() {  const response = await axios.get(`${API_BASE_URL}/dashboard/recent-activity`, {    headers: getAuthHeaders(),  });  return response.data;}

4. Dashboard Stat Card Component
Create:
nano src/components/dashboard/DashboardStatCard.vue
Paste:
<script setup>defineProps({  title: {    type: String,    required: true,  },  value: {    type: [String, Number],    required: true,  },  subtitle: {    type: String,    default: "",  },  icon: {    type: String,    default: "📊",  },  tone: {    type: String,    default: "blue",  },});</script><template>  <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm transition hover:-translate-y-1 hover:shadow-md">    <div class="flex items-start justify-between">      <div>        <p class="text-sm font-medium text-gray-500">          {{ title }}        </p>        <h3 class="mt-2 text-2xl font-bold text-gray-900">          {{ value }}        </h3>        <p v-if="subtitle" class="mt-1 text-sm text-gray-500">          {{ subtitle }}        </p>      </div>      <div        class="flex h-12 w-12 items-center justify-center rounded-2xl text-xl"        :class="{          'bg-blue-50 text-blue-600': tone === 'blue',          'bg-green-50 text-green-600': tone === 'green',          'bg-orange-50 text-orange-600': tone === 'orange',          'bg-purple-50 text-purple-600': tone === 'purple',          'bg-red-50 text-red-600': tone === 'red',        }"      >        {{ icon }}      </div>    </div>  </div></template>

5. Dashboard Progress Card Component
Create:
nano src/components/dashboard/DashboardProgressCard.vue
Paste:
<script setup>defineProps({  title: {    type: String,    required: true,  },  value: {    type: Number,    default: 0,  },  subtitle: {    type: String,    default: "",  },});</script><template>  <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">    <div class="mb-4 flex items-center justify-between">      <div>        <h3 class="text-base font-semibold text-gray-900">          {{ title }}        </h3>        <p v-if="subtitle" class="text-sm text-gray-500">          {{ subtitle }}        </p>      </div>      <span class="rounded-full bg-gray-100 px-3 py-1 text-sm font-semibold text-gray-700">        {{ value }}%      </span>    </div>    <div class="h-3 w-full rounded-full bg-gray-100">      <div        class="h-3 rounded-full bg-gray-900 transition-all duration-500"        :style="{ width: `${value}%` }"      ></div>    </div>  </div></template>

6. Dashboard Recent Activity Component
Create:
nano src/components/dashboard/DashboardRecentActivity.vue
Paste:
<script setup>defineProps({  activities: {    type: Array,    default: () => [],  },});function getActivityIcon(type) {  if (type === "finance") return "💰";  if (type === "health") return "❤️";  if (type === "project") return "📌";  if (type === "nutrition") return "🍽️";  if (type === "hydration") return "💧";  return "🔔";}</script><template>  <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">    <div class="mb-5 flex items-center justify-between">      <div>        <h3 class="text-lg font-bold text-gray-900">          Recent Activity        </h3>        <p class="text-sm text-gray-500">          Latest finance, health, and project updates        </p>      </div>    </div>    <div v-if="activities.length" class="space-y-4">      <div        v-for="activity in activities"        :key="activity.id"        class="flex items-start gap-3 rounded-xl border border-gray-100 p-3"      >        <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-50 text-lg">          {{ getActivityIcon(activity.type) }}        </div>        <div class="flex-1">          <p class="text-sm font-semibold text-gray-900">            {{ activity.title }}          </p>          <p class="text-sm text-gray-500">            {{ activity.description }}          </p>          <p class="mt-1 text-xs text-gray-400">            {{ activity.activity_date }}          </p>        </div>      </div>    </div>    <div v-else class="rounded-xl bg-gray-50 p-6 text-center">      <p class="text-sm text-gray-500">        No recent activity yet.      </p>    </div>  </div></template>

7. Dashboard Mini Chart Component
Create:
nano src/components/dashboard/DashboardMiniChart.vue
Paste:
<script setup>import {  Chart as ChartJS,  Title,  Tooltip,  Legend,  LineElement,  BarElement,  CategoryScale,  LinearScale,  PointElement,  ArcElement,} from "chart.js";import { Line, Bar, Doughnut } from "vue-chartjs";import { computed } from "vue";ChartJS.register(  Title,  Tooltip,  Legend,  LineElement,  BarElement,  CategoryScale,  LinearScale,  PointElement,  ArcElement);const props = defineProps({  title: {    type: String,    required: true,  },  type: {    type: String,    default: "line",  },  labels: {    type: Array,    default: () => [],  },  values: {    type: Array,    default: () => [],  },});const chartData = computed(() => ({  labels: props.labels,  datasets: [    {      label: props.title,      data: props.values,      borderWidth: 2,      tension: 0.4,      fill: false,    },  ],}));const chartOptions = {  responsive: true,  maintainAspectRatio: false,  plugins: {    legend: {      display: false,    },  },  scales: {    y: {      beginAtZero: true,    },  },};</script><template>  <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">    <div class="mb-4">      <h3 class="text-lg font-bold text-gray-900">        {{ title }}      </h3>    </div>    <div class="h-64">      <Line        v-if="type === 'line'"        :data="chartData"        :options="chartOptions"      />      <Bar        v-else-if="type === 'bar'"        :data="chartData"        :options="chartOptions"      />      <Doughnut        v-else        :data="chartData"        :options="{          responsive: true,          maintainAspectRatio: false,          plugins: {            legend: {              position: 'bottom',            },          },        }"      />    </div>  </div></template>

8. Main Unified Dashboard View
Create:
nano src/views/dashboard/UnifiedDashboardView.vue
Paste:
<script setup>import { onMounted, ref, computed } from "vue";import DashboardStatCard from "@/components/dashboard/DashboardStatCard.vue";import DashboardProgressCard from "@/components/dashboard/DashboardProgressCard.vue";import DashboardRecentActivity from "@/components/dashboard/DashboardRecentActivity.vue";import DashboardMiniChart from "@/components/dashboard/DashboardMiniChart.vue";import {  getUnifiedDashboardSummary,  getUnifiedDashboardKpis,  getUnifiedDashboardActivity,} from "@/services/dashboardApi";const loading = ref(true);const errorMessage = ref("");const summary = ref({  finance: {    total_balance: 0,    monthly_income: 0,    monthly_expense: 0,    savings_rate: 0,  },  health: {    today_steps: 0,    today_calories: 0,    today_water_ml: 0,    weight_kg: 0,  },  projects: {    total_projects: 0,    active_projects: 0,    completed_projects: 0,    average_progress: 0,  },});const kpis = ref({  finance_chart: {    labels: [],    values: [],  },  steps_chart: {    labels: [],    values: [],  },  calories_chart: {    labels: [],    values: [],  },  projects_chart: {    labels: [],    values: [],  },});const activities = ref([]);const formattedBalance = computed(() => {  const value = Number(summary.value.finance?.total_balance || 0);  return new Intl.NumberFormat("en-US", {    style: "currency",    currency: "USD",  }).format(value);});const formattedIncome = computed(() => {  const value = Number(summary.value.finance?.monthly_income || 0);  return new Intl.NumberFormat("en-US", {    style: "currency",    currency: "USD",  }).format(value);});const formattedExpense = computed(() => {  const value = Number(summary.value.finance?.monthly_expense || 0);  return new Intl.NumberFormat("en-US", {    style: "currency",    currency: "USD",  }).format(value);});async function loadDashboard() {  loading.value = true;  errorMessage.value = "";  try {    const [summaryResponse, kpisResponse, activityResponse] = await Promise.all([      getUnifiedDashboardSummary(),      getUnifiedDashboardKpis(),      getUnifiedDashboardActivity(),    ]);    summary.value = summaryResponse.data || summaryResponse;    kpis.value = kpisResponse.data || kpisResponse;    activities.value = activityResponse.data || activityResponse || [];  } catch (error) {    console.error(error);    errorMessage.value =      error.response?.data?.message ||      "Unable to load dashboard data. Please check backend API and token.";  } finally {    loading.value = false;  }}onMounted(() => {  loadDashboard();});</script><template>  <main class="min-h-screen bg-gray-50 p-6">    <div class="mx-auto max-w-7xl space-y-6">      <!-- Header -->      <section class="flex flex-col justify-between gap-4 md:flex-row md:items-center">        <div>          <p class="text-sm font-semibold uppercase tracking-wide text-gray-500">            NIX LIFE OS          </p>          <h1 class="mt-1 text-3xl font-bold tracking-tight text-gray-950">            Unified Dashboard          </h1>          <p class="mt-2 text-gray-500">            Your finance, health, projects, and daily activity in one operating view.          </p>        </div>        <button          @click="loadDashboard"          class="rounded-xl bg-gray-900 px-5 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-gray-800"        >          Refresh Dashboard        </button>      </section>      <!-- Error -->      <section        v-if="errorMessage"        class="rounded-2xl border border-red-100 bg-red-50 p-4 text-sm font-medium text-red-700"      >        {{ errorMessage }}      </section>      <!-- Loading -->      <section        v-if="loading"        class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-4"      >        <div          v-for="item in 4"          :key="item"          class="h-32 animate-pulse rounded-2xl bg-white shadow-sm"        ></div>      </section>      <template v-else>        <!-- Main Cards -->        <section class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-4">          <DashboardStatCard            title="Total Balance"            :value="formattedBalance"            :subtitle="`Income: ${formattedIncome}`"            icon="💰"            tone="green"          />          <DashboardStatCard            title="Today Steps"            :value="summary.health.today_steps || 0"            subtitle="Daily movement progress"            icon="👟"            tone="blue"          />          <DashboardStatCard            title="Today Calories"            :value="summary.health.today_calories || 0"            subtitle="Calories logged today"            icon="🔥"            tone="orange"          />          <DashboardStatCard            title="Active Projects"            :value="summary.projects.active_projects || 0"            :subtitle="`${summary.projects.total_projects || 0} total projects`"            icon="📌"            tone="purple"          />        </section>        <!-- Secondary KPI Cards -->        <section class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-4">          <DashboardStatCard            title="Monthly Expense"            :value="formattedExpense"            subtitle="Current month spending"            icon="💸"            tone="red"          />          <DashboardStatCard            title="Savings Rate"            :value="`${summary.finance.savings_rate || 0}%`"            subtitle="Pay-yourself performance"            icon="🏦"            tone="green"          />          <DashboardStatCard            title="Water Intake"            :value="`${summary.health.today_water_ml || 0} ml`"            subtitle="Today hydration"            icon="💧"            tone="blue"          />          <DashboardStatCard            title="Current Weight"            :value="`${summary.health.weight_kg || 0} kg`"            subtitle="Latest health record"            icon="⚖️"            tone="purple"          />        </section>        <!-- Progress Section -->        <section class="grid grid-cols-1 gap-5 lg:grid-cols-3">          <DashboardProgressCard            title="Average Project Progress"            :value="summary.projects.average_progress || 0"            subtitle="Across all active projects"          />          <DashboardProgressCard            title="Completed Projects"            :value="              summary.projects.total_projects                ? Math.round((summary.projects.completed_projects / summary.projects.total_projects) * 100)                : 0            "            :subtitle="`${summary.projects.completed_projects || 0} completed projects`"          />          <DashboardProgressCard            title="Finance Savings Goal"            :value="summary.finance.savings_rate || 0"            subtitle="Monthly saving performance"          />        </section>        <!-- Charts -->        <section class="grid grid-cols-1 gap-5 xl:grid-cols-2">          <DashboardMiniChart            title="Finance Trend"            type="line"            :labels="kpis.finance_chart.labels"            :values="kpis.finance_chart.values"          />          <DashboardMiniChart            title="Steps Trend"            type="bar"            :labels="kpis.steps_chart.labels"            :values="kpis.steps_chart.values"          />          <DashboardMiniChart            title="Calories Trend"            type="line"            :labels="kpis.calories_chart.labels"            :values="kpis.calories_chart.values"          />          <DashboardMiniChart            title="Project Progress"            type="bar"            :labels="kpis.projects_chart.labels"            :values="kpis.projects_chart.values"          />        </section>        <!-- Recent Activity -->        <section class="grid grid-cols-1 gap-5 xl:grid-cols-3">          <div class="xl:col-span-2">            <DashboardRecentActivity :activities="activities" />          </div>          <div class="rounded-2xl border border-gray-100 bg-gray-900 p-6 text-white shadow-sm">            <p class="text-sm font-semibold uppercase tracking-wide text-gray-400">              AI Insight            </p>            <h3 class="mt-3 text-2xl font-bold">              Your operating system is active.            </h3>            <p class="mt-3 text-sm leading-6 text-gray-300">              Finance, health, and project data are now connected into one unified              decision dashboard. The next step can add AI recommendations,              alerts, and smart daily planning.            </p>            <div class="mt-6 rounded-xl bg-white/10 p-4">              <p class="text-sm text-gray-300">                Suggested next module:              </p>              <p class="mt-1 font-semibold">                STEP 18 — AI Insights Engine              </p>            </div>          </div>        </section>      </template>    </div>  </main></template>

9. Update Router
Open your router file:
nano src/router/index.js
Add this import:
import UnifiedDashboardView from "@/views/dashboard/UnifiedDashboardView.vue";
Add this route:
{  path: "/dashboard",  name: "unified-dashboard",  component: UnifiedDashboardView,}
Example full router:
import { createRouter, createWebHistory } from "vue-router";import UnifiedDashboardView from "@/views/dashboard/UnifiedDashboardView.vue";const routes = [  {    path: "/",    redirect: "/dashboard",  },  {    path: "/dashboard",    name: "unified-dashboard",    component: UnifiedDashboardView,  },];const router = createRouter({  history: createWebHistory(),  routes,});export default router;
If you already have existing routes, do not delete them. Just add the dashboard route.

10. Update App.vue Sidebar
Open:
nano src/App.vue
Use this clean version:
<script setup>import { RouterLink, RouterView } from "vue-router";</script><template>  <div class="min-h-screen bg-gray-50">    <div class="flex">      <!-- Sidebar -->      <aside class="hidden min-h-screen w-72 border-r border-gray-100 bg-white p-5 shadow-sm lg:block">        <div class="mb-8">          <h1 class="text-2xl font-black tracking-tight text-gray-950">            NIX LIFE OS          </h1>          <p class="mt-1 text-sm text-gray-500">            Personal Operating System          </p>        </div>        <nav class="space-y-2">          <RouterLink            to="/dashboard"            class="block rounded-xl px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-100"            active-class="bg-gray-900 text-white hover:bg-gray-900"          >            Unified Dashboard          </RouterLink>          <RouterLink            to="/finance/accounts"            class="block rounded-xl px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-100"            active-class="bg-gray-900 text-white hover:bg-gray-900"          >            Finance Accounts          </RouterLink>          <RouterLink            to="/finance/transactions"            class="block rounded-xl px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-100"            active-class="bg-gray-900 text-white hover:bg-gray-900"          >            Transactions          </RouterLink>          <RouterLink            to="/finance/budgets"            class="block rounded-xl px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-100"            active-class="bg-gray-900 text-white hover:bg-gray-900"          >            Budgets          </RouterLink>          <RouterLink            to="/health/steps"            class="block rounded-xl px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-100"            active-class="bg-gray-900 text-white hover:bg-gray-900"          >            Steps Tracking          </RouterLink>          <RouterLink            to="/health/weight"            class="block rounded-xl px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-100"            active-class="bg-gray-900 text-white hover:bg-gray-900"          >            Weight Tracking          </RouterLink>          <RouterLink            to="/health/nutrition"            class="block rounded-xl px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-100"            active-class="bg-gray-900 text-white hover:bg-gray-900"          >            Nutrition          </RouterLink>          <RouterLink            to="/health/hydration"            class="block rounded-xl px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-100"            active-class="bg-gray-900 text-white hover:bg-gray-900"          >            Hydration          </RouterLink>          <RouterLink            to="/projects"            class="block rounded-xl px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-100"            active-class="bg-gray-900 text-white hover:bg-gray-900"          >            Projects          </RouterLink>        </nav>      </aside>      <!-- Main Content -->      <section class="min-h-screen flex-1">        <RouterView />      </section>    </div>  </div></template>

11. Expected Backend Response Shape
Your Step 16 backend should return data similar to this.
/api/v1/dashboard/summary
{  "success": true,  "data": {    "finance": {      "total_balance": 2500,      "monthly_income": 1800,      "monthly_expense": 650,      "savings_rate": 45    },    "health": {      "today_steps": 6500,      "today_calories": 1450,      "today_water_ml": 1800,      "weight_kg": 64    },    "projects": {      "total_projects": 4,      "active_projects": 3,      "completed_projects": 1,      "average_progress": 55    }  }}
/api/v1/dashboard/kpis
{  "success": true,  "data": {    "finance_chart": {      "labels": ["Mon", "Tue", "Wed", "Thu", "Fri"],      "values": [200, 350, 150, 400, 500]    },    "steps_chart": {      "labels": ["Mon", "Tue", "Wed", "Thu", "Fri"],      "values": [4000, 6000, 7500, 5000, 9000]    },    "calories_chart": {      "labels": ["Mon", "Tue", "Wed", "Thu", "Fri"],      "values": [1400, 1550, 1600, 1450, 1700]    },    "projects_chart": {      "labels": ["Finance", "Health", "Projects", "AI"],      "values": [75, 60, 55, 20]    }  }}
/api/v1/dashboard/recent-activity
{  "success": true,  "data": [    {      "id": 1,      "type": "finance",      "title": "New transaction added",      "description": "Groceries expense recorded",      "activity_date": "2026-04-26"    },    {      "id": 2,      "type": "health",      "title": "Steps updated",      "description": "6500 steps logged today",      "activity_date": "2026-04-26"    },    {      "id": 3,      "type": "project",      "title": "Project progress updated",      "description": "NIX LIFE OS reached 55%",      "activity_date": "2026-04-26"    }  ]}

12. Run Frontend
npm run dev
Open:
http://localhost:5173/dashboard

13. Test Backend APIs First
Before testing the UI, check these:
curl http://127.0.0.1:8000/api/v1/dashboard/summary \  -H "Accept: application/json" \  -H "Authorization: Bearer YOUR_TOKEN"
curl http://127.0.0.1:8000/api/v1/dashboard/kpis \  -H "Accept: application/json" \  -H "Authorization: Bearer YOUR_TOKEN"
curl http://127.0.0.1:8000/api/v1/dashboard/recent-activity \  -H "Accept: application/json" \  -H "Authorization: Bearer YOUR_TOKEN"

14. Save Token In Browser
In browser console:
localStorage.setItem("token", "YOUR_TOKEN_HERE");
Then refresh:
http://localhost:5173/dashboard

15. STEP 17 Completion Checklist
You can consider STEP 17 — Unified Dashboard UI complete when:
[✓] Dashboard route exists: /dashboard[✓] Sidebar has Unified Dashboard link[✓] Finance balance card appears[✓] Steps card appears[✓] Calories card appears[✓] Projects card appears[✓] Finance chart appears[✓] Steps chart appears[✓] Calories chart appears[✓] Project progress chart appears[✓] Recent activity section appears[✓] API token is read from localStorage[✓] Backend Step 16 APIs are connected[✓] UI loads without Vue errors

Next Step
After this, you can continue with:
🔹 STEP 18 — AI Insights EngineBuild intelligent recommendations:- Finance warnings- Health alerts- Project delay detection- Daily AI summary- Smart priority recommendations
This will make the dashboard not only display data, but also explain what the data means.