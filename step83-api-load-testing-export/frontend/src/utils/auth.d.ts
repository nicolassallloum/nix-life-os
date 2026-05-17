export const AUTH_TOKEN_KEYS: string[]
export const AUTH_USER_KEYS: string[]

export interface AuthUser {
  id?: string | number
  name?: string
  email?: string
  roles?: string[]
  permissions?: string[]
  [key: string]: unknown
}

export function getAuthToken(): string | null
export function getAuthUser(): AuthUser | null
export function clearAuthSession(): void
export function saveAuthSession(token: string, user?: AuthUser | null): void
export function userRoles(user?: AuthUser | null): string[]
export function userPermissions(user?: AuthUser | null): string[]
export function hasRole(role: string, user?: AuthUser | null): boolean
export function hasAnyRole(roles?: string[], user?: AuthUser | null): boolean
export function hasPermission(permission: string, user?: AuthUser | null): boolean
export function hasAllPermissions(permissions?: string[], user?: AuthUser | null): boolean
export function hasAnyPermission(permissions?: string[], user?: AuthUser | null): boolean
export function canAccessRoute(routeMeta?: Record<string, any>, user?: AuthUser | null): boolean
