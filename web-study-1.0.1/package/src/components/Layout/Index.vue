<template>
  <div class="layout-container">
    <header class="header">
      <div class="system-logo">
        <el-icon class="logo-icon"><Reading /></el-icon>
        <div class="system-logo-text">大数据智能处理团队研究生学习平台</div>
      </div>

      <div class="user-info-container">
        <el-dropdown trigger="click" @command="handleUserCommand">
          <div class="user-avatar">
            {{ authStore.displayName.charAt(0).toUpperCase() }}
          </div>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="profile">个人中心</el-dropdown-item>
              <el-dropdown-item v-if="authStore.isAdmin" command="users">用户管理</el-dropdown-item>
              <el-dropdown-item v-if="authStore.isAdmin" command="content">学习内容管理</el-dropdown-item>
              <el-dropdown-item v-if="authStore.isAdmin" command="dashboard">平台学习总览</el-dropdown-item>
              <el-dropdown-item divided command="logout">退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>

        <div class="user-welcome">
          欢迎，<span class="user-name">{{ authStore.displayName }}</span>
        </div>
      </div>
    </header>

    <div class="main-wrapper">
      <aside class="sidebar">
        <div class="side-menu-title">
          <el-icon><Menu /></el-icon>
          <span>学习导航</span>
        </div>

        <div class="menu-section">
          <router-link to="/knowledge" class="menu-item" :class="{ active: isKnowledgeRoute }">
            <el-icon><Reading /></el-icon>
            <span>知识学习</span>
          </router-link>

          <router-link
            to="/learn-dashboard"
            class="menu-item"
            :class="{ active: route.path === '/learn-dashboard' }"
          >
            <el-icon><DataAnalysis /></el-icon>
            <span>学习数据面板</span>
          </router-link>
        </div>
      </aside>

      <main class="main-content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessageBox } from 'element-plus'
import { DataAnalysis, Menu, Reading } from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const isKnowledgeRoute = computed(() => {
  return route.path.startsWith('/knowledge') || route.path.startsWith('/learning/item/')
})

const handleLogout = async () => {
  try {
    await ElMessageBox.confirm('确定要退出登录吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    authStore.logout()
    router.push('/login')
  } catch (error) {
    // user cancelled
  }
}

const handleUserCommand = command => {
  if (command === 'profile') {
    router.push('/profile').catch(() => {})
    return
  }
  if (command === 'users') {
    router.push('/users').catch(() => {})
    return
  }
  if (command === 'content') {
    router.push('/content-library').catch(() => {})
    return
  }
  if (command === 'dashboard') {
    router.push('/admin-dashboard').catch(() => {})
    return
  }
  if (command === 'logout') {
    handleLogout()
  }
}
</script>

<style scoped>
.layout-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: #f0f2f5;
}

.header {
  height: 60px;
  background: linear-gradient(135deg, #1e88e5 0%, #1976d2 100%);
  color: #ffffff;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  box-shadow: 0 4px 12px rgba(30, 136, 229, 0.25);
  z-index: 1002;
}

.system-logo {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logo-icon {
  font-size: 28px;
}

.system-logo-text {
  font-size: 18px;
  font-weight: 600;
  color: #ffffff;
}

.user-info-container {
  display: flex;
  align-items: center;
  gap: 15px;
}

.user-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.2) 0%, rgba(255, 255, 255, 0.3) 100%);
  display: flex;
  justify-content: center;
  align-items: center;
  font-weight: bold;
  font-size: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  cursor: pointer;
}

.user-welcome {
  font-size: 14px;
  color: #ffffff;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.15);
}

.user-name {
  font-weight: 600;
}

.main-wrapper {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.sidebar {
  width: 250px;
  background: linear-gradient(180deg, #ffffff 0%, #f0f4f8 100%);
  box-shadow: 2px 0 16px rgba(0, 0, 0, 0.1);
  border-right: 1px solid #e2e8f0;
  overflow-y: auto;
  padding: 20px 0;
}

.side-menu-title {
  font-size: 14px;
  color: #1e88e5;
  padding: 15px 20px 10px 20px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 8px;
}

.menu-section {
  margin-bottom: 15px;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 22px;
  color: #374151;
  text-decoration: none;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  font-size: 14px;
  font-weight: 500;
  border-radius: 12px;
  margin: 0 10px 8px 10px;
  border: 1px solid transparent;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.8) 0%, rgba(249, 250, 251, 0.8) 100%);
  backdrop-filter: blur(10px);
}

.menu-item:hover {
  background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
  color: #1d4ed8;
  transform: translateX(4px) translateY(-1px);
  border-color: #93c5fd;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2);
}

.menu-item.active {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: #ffffff;
  font-weight: 600;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2);
  border-color: #3b82f6;
  transform: translateX(4px) translateY(-1px);
}

.main-content {
  flex: 1;
  background-color: #f8fafc;
  overflow-y: auto;
  overflow-x: hidden;
  position: relative;
}
</style>
