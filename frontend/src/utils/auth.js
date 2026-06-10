export const AUTH_TOKEN_KEYS = ['token', 'auth_token', 'access_token', 'nixlifeos_token']
export const AUTH_USER_KEYS = ['user', 'auth_user', 'nixlifeos_user']

export const AUTH_TOKEN_KEY = AUTH_TOKEN_KEYS[0]
export const AUTH_USER_KEY = AUTH_USER_KEYS[0]

function safeJsonParse(value, fallback = null) {
  if (!value) return fallback

  try {
    return JSON.parse(value)
  } catch {
    return fallback
  }
}

export function getAuthToken() {
  for (const key of AUTH_TOKEN_KEYS) {
    const token = localStorage.getItem(key)

    if (token) {
      return token
    }
  }

  return null
}

export function getAuthUser() {
  for (const key of AUTH_USER_KEYS) {
    const rawUser = localStorage.getItem(key)

    if (!rawUser) {
      continue
    }

    const parsedUser = safeJsonParse(rawUser, null)

    if (parsedUser) {
      return parsedUser
    }
  }

  return null
}

export function saveAuthSession(token, user = null) {
  if (token) {
    localStorage.setItem(AUTH_TOKEN_KEY, token)

    for (const key of AUTH_TOKEN_KEYS) {
      if (key !== AUTH_TOKEN_KEY) {
        localStorage.removeItem(key)
      }
    }
  }

  if (user) {
    localStorage.setItem(AUTH_USER_KEY, JSON.stringify(user))

    for (const key of AUTH_USER_KEYS) {
      if (key !== AUTH_USER_KEY) {
        localStorage.removeItem(key)
      }
    }
  }
}

export function clearAuthSession() {
  for (const key of AUTH_TOKEN_KEYS) {
    localStorage.removeItem(key)
  }

  for (const key of AUTH_USER_KEYS) {
    localStorage.removeItem(key)
  }
}

export function isAuthenticated() {
  return Boolean(getAuthToken())
}

export function getUserRoles() {
  const user = getAuthUser()

  if (!user) {
    return []
  }

  const roles = []

  if (user.role) {
    roles.push(String(user.role).toLowerCase())
  }

  if (Array.isArray(user.roles)) {
    roles.push(
      ...user.roles
        .map((role) => (typeof role === 'string' ? role : role?.name))
        .filter(Boolean)
        .map((role) => String(role).toLowerCase()),
    )
  }

  return [...new Set(roles)]
}

export function getUserPermissions() {
  const user = getAuthUser()

  if (!user) {
    return []
  }

  if (Array.isArray(user.permissions)) {
    return user.permissions
      .map((permission) => (typeof permission === 'string' ? permission : permission?.name))
      .filter(Boolean)
  }

  return []
}

export function hasRole(roleName) {
  return getUserRoles().includes(roleName)
}

export function hasAnyRole(roleNames = []) {
  return roleNames.some((roleName) => hasRole(roleName))
}

export function hasPermission(permissionName) {
  return getUserPermissions().includes(permissionName)
}

export function hasAnyPermission(permissionNames = []) {
  return permissionNames.some((permissionName) => hasPermission(permissionName))
}

export function canAccessRoute(routeOrMeta, userOverride = null) {
  const meta = routeOrMeta?.meta || routeOrMeta || {}
  const user = userOverride || getAuthUser()

  if (meta.public === true || meta.guest === true) {
    return true
  }

  if (meta.requiresAuth === true && !isAuthenticated()) {
    return false
  }

  const requiredRoles = Array.isArray(meta.roles)
    ? meta.roles.map((role) => String(role).toLowerCase())
    : meta.requiresRole
      ? [String(meta.requiresRole).toLowerCase()]
      : meta.requiresAdmin
        ? ['admin']
        : []
  const requiredPermissions = Array.isArray(meta.permissions)
    ? meta.permissions
    : meta.permission
      ? [meta.permission]
      : []

  const userRoles = [
    ...(user?.role ? [String(user.role).toLowerCase()] : []),
    ...(Array.isArray(user?.roles)
      ? user.roles.map((role) => (typeof role === 'string' ? role : role?.name)).filter(Boolean).map((role) => String(role).toLowerCase())
      : []),
  ]
  const userPermissions = Array.isArray(user?.permissions)
    ? user.permissions.map((permission) => (typeof permission === 'string' ? permission : permission?.name)).filter(Boolean)
    : []

  if (requiredRoles.length > 0 && !requiredRoles.some((roleName) => userRoles.includes(roleName))) {
    return false
  }

  if (requiredPermissions.length > 0 && !requiredPermissions.some((permissionName) => userPermissions.includes(permissionName))) {
    return false
  }

  return true
}
