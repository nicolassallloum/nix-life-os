export const AUTH_TOKEN_KEYS = ['token', 'auth_token', 'access_token', 'nix_token']
export const AUTH_USER_KEYS = ['user', 'auth_user', 'nix_user']

export function getAuthToken() {
  for (const key of AUTH_TOKEN_KEYS) {
    const value = localStorage.getItem(key)
    if (value) return value
  }

  return null
}

export function getAuthUser() {
  for (const key of AUTH_USER_KEYS) {
    const rawValue = localStorage.getItem(key)

    if (!rawValue) continue

    try {
      return JSON.parse(rawValue)
    } catch (_error) {
      return null
    }
  }

  return null
}

export function clearAuthSession() {
  for (const key of AUTH_TOKEN_KEYS) {
    localStorage.removeItem(key)
  }

  for (const key of AUTH_USER_KEYS) {
    localStorage.removeItem(key)
  }
}

export function saveAuthSession(token, user = null) {
  if (!token) return

  for (const key of AUTH_TOKEN_KEYS) {
    localStorage.setItem(key, token)
  }

  if (user) {
    const serializedUser = JSON.stringify(user)

    for (const key of AUTH_USER_KEYS) {
      localStorage.setItem(key, serializedUser)
    }
  }
}

export function userRoles(user = getAuthUser()) {
  return Array.isArray(user?.roles) ? user.roles : []
}

export function userPermissions(user = getAuthUser()) {
  return Array.isArray(user?.permissions) ? user.permissions : []
}

export function hasRole(role, user = getAuthUser()) {
  return userRoles(user).includes(role)
}

export function hasAnyRole(roles = [], user = getAuthUser()) {
  if (!Array.isArray(roles) || roles.length === 0) return true
  return roles.some((role) => hasRole(role, user))
}

export function hasPermission(permission, user = getAuthUser()) {
  return userPermissions(user).includes(permission)
}

export function hasAllPermissions(permissions = [], user = getAuthUser()) {
  if (!Array.isArray(permissions) || permissions.length === 0) return true
  return permissions.every((permission) => hasPermission(permission, user))
}

export function hasAnyPermission(permissions = [], user = getAuthUser()) {
  if (!Array.isArray(permissions) || permissions.length === 0) return true
  return permissions.some((permission) => hasPermission(permission, user))
}

export function canAccessRoute(routeMeta = {}, user = getAuthUser()) {
  if (routeMeta.requiresRole && !hasRole(routeMeta.requiresRole, user)) return false
  if (routeMeta.roles && !hasAnyRole(routeMeta.roles, user)) return false
  if (routeMeta.permissions && !hasAllPermissions(routeMeta.permissions, user)) return false
  if (routeMeta.anyPermissions && !hasAnyPermission(routeMeta.anyPermissions, user)) return false

  return true
}
