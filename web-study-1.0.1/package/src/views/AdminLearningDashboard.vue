<template>
  <div class="dashboard-page">
    <div class="dashboard-container">
      <div class="dashboard-header">
        <div>
          <h1>学习进度总览</h1>
          <p>管理员查看所有用户的学习数据统计</p>
        </div>
        <div class="header-actions">
          <el-button type="primary" plain @click="refresh">
            <el-icon><Refresh /></el-icon>
            刷新数据
          </el-button>
        </div>
      </div>

      <div v-if="loading" class="status-panel">
        <el-icon class="is-loading" :size="28"><Loading /></el-icon>
        <p>正在加载学习数据...</p>
      </div>

      <div v-else-if="error" class="status-panel">
        <p>{{ error }}</p>
        <el-button type="primary" @click="fetchDashboard">重试</el-button>
      </div>

      <div v-else class="dashboard-content">
        <!-- 总览统计 -->
        <section class="panel">
          <div class="panel-header">
            <h2>平台统计</h2>
            <span class="panel-sub">整体学习数据概览</span>
          </div>
          <div class="summary-grid">
            <div class="summary-donut">
              <div class="donut-chart">
                <div class="donut-circle">
                  <div class="donut-fill" :style="{ transform: `rotate(${completionRate * 3.6}deg)` }"></div>
                  <div class="donut-center">
                    <span class="rate">{{ completionRate }}%</span>
                    <span>完成率</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="kpi-grid">
              <div class="kpi-card">
                <span>总用户数</span>
                <strong>{{ summary.totalUsers }}</strong>
              </div>
              <div class="kpi-card">
                <span>活跃用户</span>
                <strong>{{ summary.activeUsers }}</strong>
              </div>
              <div class="kpi-card">
                <span>总学习项</span>
                <strong>{{ summary.totalLearningItems }}</strong>
              </div>
              <div class="kpi-card">
                <span>累计学习时长</span>
                <strong>{{ formatDuration(summary.totalLearningSeconds) }}</strong>
              </div>
            </div>
          </div>
        </section>

        <!-- 用户进度表格 -->
        <section class="panel">
          <div class="panel-header">
            <h2>用户学习进度</h2>
            <div class="panel-actions">
              <el-input
                v-model="searchKeyword"
                placeholder="搜索用户名或显示名"
                style="width: 200px"
                clearable
                @input="filterUsers"
              />
            </div>
          </div>

          <div class="users-table-container">
            <el-table :data="filteredUsers" stripe style="width: 100%" :header-cell-style="{background:'#f9fafb',color:'#374151',fontWeight:'600'}">
              <el-table-column prop="username" label="用户名" min-width="100" />
              <el-table-column prop="displayName" label="显示名" min-width="120" />
              <el-table-column label="进度" min-width="180">
                <template #default="scope">
                  <div class="progress-cell">
                    <div class="progress-bar">
                      <div
                        class="progress-fill"
                        :style="{ width: `${scope.row.totalItems > 0 ? (scope.row.completedItems / scope.row.totalItems * 100) : 0}%` }"
                      ></div>
                    </div>
                    <span class="progress-text">{{ scope.row.completedItems }}/{{ scope.row.totalItems }}</span>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="学习时长" min-width="100">
                <template #default="scope">
                  {{ formatDuration(scope.row.learningSeconds) }}
                </template>
              </el-table-column>
              <el-table-column prop="lastActiveTime" label="最后活跃" min-width="140" />
              <el-table-column label="操作" min-width="100" align="center">
                <template #default="scope">
                  <el-button
                    type="primary"
                    size="small"
                    @click="viewUserProgress(scope.row.userId)"
                  >
                    查看详情
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </section>

        <!-- 活跃度统计 -->
        <section class="panel">
          <div class="panel-header">
            <h2>用户活跃度统计</h2>
            <span class="panel-sub">按学习时长排序</span>
          </div>

          <div class="activity-list">
            <div
              v-for="user in topActiveUsers"
              :key="user.userId"
              class="activity-item"
            >
              <div class="activity-user">
                <div class="user-avatar">{{ user.displayName.charAt(0).toUpperCase() }}</div>
                <div class="user-info">
                  <span class="user-name">{{ user.displayName }}</span>
                  <span class="user-username">@{{ user.username }}</span>
                </div>
              </div>
              <div class="activity-stats">
                <div class="stat">
                  <span class="stat-value">{{ user.completedItems }}</span>
                  <span class="stat-label">已完成</span>
                </div>
                <div class="stat">
                  <span class="stat-value">{{ formatDuration(user.learningSeconds) }}</span>
                  <span class="stat-label">学习时长</span>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import request from '@/api/request'
import { ElMessage } from 'element-plus'
import { Refresh, Loading } from '@element-plus/icons-vue'

const router = useRouter()

const loading = ref(false)
const error = ref('')
const summary = ref({
  totalUsers: 0,
  activeUsers: 0,
  totalLearningItems: 0,
  completedItems: 0,
  totalLearningSeconds: 0,
  userSummaries: []
})

const searchKeyword = ref('')
const filteredUsers = ref([])

// 计算完成率
const completionRate = computed(() => {
  if (summary.value.totalLearningItems === 0) return 0
  return Math.round((summary.value.completedItems / (summary.value.totalUsers * summary.value.totalLearningItems)) * 100)
})

// 获取前10个最活跃用户
const topActiveUsers = computed(() => {
  return [...summary.value.userSummaries]
    .sort((a, b) => b.learningSeconds - a.learningSeconds)
    .slice(0, 10)
})

const fetchDashboard = async () => {
  loading.value = true
  error.value = ''

  try {
    const res = await request.get('/learning-progress/admin/summary')
    summary.value = res
    filteredUsers.value = [...res.userSummaries]
  } catch (err) {
    console.error('加载学习统计失败', err)
    error.value = '加载学习统计失败，请重试'
    ElMessage.error('加载学习统计失败')
  } finally {
    loading.value = false
  }
}

const filterUsers = () => {
  const keyword = searchKeyword.value.toLowerCase()
  if (!keyword) {
    filteredUsers.value = [...summary.value.userSummaries]
  } else {
    filteredUsers.value = summary.value.userSummaries.filter(user =>
      user.username.toLowerCase().includes(keyword) ||
      user.displayName.toLowerCase().includes(keyword)
    )
  }
}

const refresh = () => {
  fetchDashboard()
}

const viewUserProgress = (userId) => {
  // 跳转到用户进度详情页面
  router.push(`/users/${userId}/progress`)
}

const formatDuration = (seconds) => {
  if (!seconds) return '0秒'

  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = seconds % 60

  if (hours > 0) {
    return `${hours}时${minutes}分`
  } else if (minutes > 0) {
    return `${minutes}分${secs}秒`
  } else {
    return `${secs}秒`
  }
}

onMounted(() => {
  fetchDashboard()
})
</script>

<style scoped>
.dashboard-page {
  min-height: 100vh;
  background: #f8fafc;
  padding: 20px;
}

.dashboard-container {
  max-width: 1200px;
  margin: 0 auto;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.dashboard-header h1 {
  margin: 0 0 4px 0;
  font-size: 28px;
  font-weight: 700;
  color: #111827;
}

.dashboard-header p {
  margin: 0;
  color: #6b7280;
  font-size: 14px;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.status-panel {
  background: #ffffff;
  border-radius: 16px;
  padding: 40px;
  border: 1px solid #eef2f7;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.04);
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: center;
  color: #6b7280;
}

.dashboard-content {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.panel {
  background: #ffffff;
  border-radius: 16px;
  padding: 24px;
  border: 1px solid #eef2f7;
  box-shadow: 0 4px 12px rgba(15, 23, 42, 0.04);
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.panel-header h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #111827;
}

.panel-sub {
  color: #6b7280;
  font-size: 14px;
}

.panel-actions {
  display: flex;
  gap: 12px;
  align-items: center;
}

.summary-grid {
  display: grid;
  grid-template-columns: 200px 1fr;
  gap: 24px;
  align-items: center;
}

.summary-donut {
  display: flex;
  justify-content: center;
}

.donut-chart {
  width: 120px;
  height: 120px;
}

.donut-circle {
  position: relative;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background: conic-gradient(#3b82f6 0deg, #3b82f6 var(--progress), #e5e7eb var(--progress), #e5e7eb 360deg);
}

.donut-fill {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 80px;
  height: 80px;
  margin: -40px 0 0 -40px;
  border-radius: 50%;
  background: white;
  transform: rotate(0deg);
  transition: transform 0.3s ease;
}

.donut-center {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
}

.donut-center .rate {
  display: block;
  font-size: 20px;
  font-weight: 700;
  color: #111827;
}

.donut-center span:last-child {
  font-size: 12px;
  color: #6b7280;
}

.kpi-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 16px;
}

.kpi-card {
  background: #f8fafc;
  padding: 16px;
  border-radius: 12px;
  border: 1px solid #eef2f7;
  text-align: center;
}

.kpi-card span {
  display: block;
  font-size: 12px;
  color: #6b7280;
  margin-bottom: 4px;
}

.kpi-card strong {
  display: block;
  font-size: 18px;
  font-weight: 700;
  color: #111827;
}

.users-table-container {
  margin-top: 16px;
  width: 100%;
  overflow-x: auto;
}

.users-table-container .el-table {
  min-width: 100%;
  border-radius: 8px;
  overflow: hidden;
}

.users-table-container .el-table th {
  background-color: #f9fafb !important;
  color: #374151 !important;
  font-weight: 600 !important;
  border-bottom: 1px solid #e5e7eb;
}

.users-table-container .el-table td {
  border-bottom: 1px solid #f3f4f6;
}

.progress-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}

.progress-bar {
  flex: 1;
  height: 8px;
  background: #e5e7eb;
  border-radius: 4px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #3b82f6, #06b6d4);
  border-radius: 4px;
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 12px;
  color: #6b7280;
  min-width: 60px;
}

.activity-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.activity-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: #f8fafc;
  border-radius: 12px;
  border: 1px solid #eef2f7;
}

.activity-user {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #3b82f6;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 16px;
}

.user-info {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-weight: 600;
  color: #111827;
  font-size: 14px;
}

.user-username {
  color: #6b7280;
  font-size: 12px;
}

.activity-stats {
  display: flex;
  gap: 24px;
}

.stat {
  text-align: center;
}

.stat-value {
  display: block;
  font-size: 16px;
  font-weight: 700;
  color: #111827;
}

.stat-label {
  font-size: 12px;
  color: #6b7280;
}

@media (max-width: 1024px) {
  .summary-grid {
    grid-template-columns: 1fr;
  }

  .activity-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .activity-stats {
    width: 100%;
    justify-content: space-around;
  }

  .header-actions {
    flex-direction: column;
    align-items: flex-end;
  }
}
</style>
