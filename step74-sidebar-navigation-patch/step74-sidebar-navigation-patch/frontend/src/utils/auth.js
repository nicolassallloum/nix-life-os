export const AUTH_TOKEN_KEYS = ['nixlifeos_auth_token', 'auth_token', 'token']
export const AUTH_USER_KEYS = ['nixlifeos_auth_user', 'auth_user', 'user']

function readFirstStorageValue(keys) {
  for (const key of keys) {
    const value = localStorage.getItem(key)

    if (value) {
      return value
    }
  }

  return null
}

function normalizeList(value) {
  if (!value) {
    return []
  }

  if (Array.isArray(value)) {
    return value
      .map((item) => {
        if (typeof item === 'string') {
          return item
        }

        return item?.name || item?.slug || item?.code || item?.permission || item?.role || ''
      })
      .filter(Boolean)
  }

  if (typeof value === 'string') {
    return value
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean)
  }

  if (typeof value === 'object') {
    return Object.values(value).flatMap((item) => normalizeList(item))
  }

  return []
}

function unique(values) {
  return [...new Set(values.filter(Boolean))]
}

export function getAuthToken() {
  return readFirstStorageValue(AUTH_TOKEN_KEYS)
}

export function getAuthUser() {
  const rawUser = readFirstStorageValue(AUTH_USER_KEYS)

  if (!rawUser) {
    return null
  }

  try {
    return JSON.parse(rawUser)
  } catch (_error) {
    clearAuthSession()
    return null
  }
}

export function getUserRoles(user = getAuthUser()) {
  return unique([
    ...normalizeList(user?.roles),
    ...normalizeList(user?.role),
    ...normalizeList(user?.data?.roles),
  ])
}

export function getUserPermissions(user = getAuthUser()) {
  return unique([
    ...normalizeList(user?.permissions),
    ...normalizeList(user?.permission_names),
    ...normalizeList(user?.data?.permissions),
  ])
}

export function hasRole(role, user = getAuthUser()) {
  if (!role) {
    return true
  }

  return getUserRoles(user).includes(role)
}

export function hasAnyRole(roles = [], user = getAuthUser()) {
  const requiredRoles = Array.isArray(roles) ? roles : [roles]

  if (requiredRoles.length === 0) {
    return true
  }

  const currentRoles = getUserRoles(user)
  return requiredRoles.some((role) => currentRoles.includes(role))
}

export function hasPermission(permission, user = getAuthUser()) {
  if (!permission) {
    return true
  }

  const permissions = getUserPermissions(user)
  const roles = getUserRoles(user)

  return permissions.includes(permission) || roles.includes('admin')
}

export function hasAllPermissions(permissions = [], user = getAuthUser()) {
  const requiredPermissions = Array.isArray(permissions) ? permissions : [permissions]

  if (requiredPermissions.length === 0) {
    return true
  }

  return requiredPermissions.every((permission) => hasPermission(permission, user))
}

export function canAccessRoute(meta = {}, user = getAuthUser()) {
  if (meta.requiresRole && !hasRole(meta.requiresRole, user)) {
    return false
  }

  if (meta.roles && !hasAnyRole(meta.roles, user)) {
    return false
  }

  if (meta.permissions && !hasAllPermissions(meta.permissions, user)) {
    return false
  }

  if (meta.permission && !hasPermission(meta.permission, user)) {
    return false
  }

  return true
}

export function saveAuthSession(token, user = null) {
  if (token) {
    for (const key of AUTH_TOKEN_KEYS) {
      localStorage.setItem(key, token)
    }
  }

  if (user) {
    const serializedUser = JSON.stringify(user)

    for (const key of AUTH_USER_KEYS) {
      localStorage.setItem(key, serializedUser)
    }
  }
}

export function clearAuthSession() {
  for (const key of [...AUTH_TOKEN_KEYS, ...AUTH_USER_KEYS]) {
    localStorage.removeItem(key)
  }
}
