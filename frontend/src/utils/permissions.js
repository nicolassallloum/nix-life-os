export function getCurrentUser() {
  const rawUser = localStorage.getItem("nix_user");

  if (!rawUser) {
    return null;
  }

  try {
    return JSON.parse(rawUser);
  } catch {
    return null;
  }
}

export function hasRole(role) {
  const user = getCurrentUser();

  if (!user || !Array.isArray(user.roles)) {
    return false;
  }

  return user.roles.includes(role);
}

export function hasPermission(permission) {
  const user = getCurrentUser();

  if (!user || !Array.isArray(user.permissions)) {
    return false;
  }

  return user.permissions.includes(permission);
}

export function hasAnyPermission(permissions = []) {
  return permissions.some((permission) => hasPermission(permission));
}

export function isAdmin() {
  return hasRole("admin");
}