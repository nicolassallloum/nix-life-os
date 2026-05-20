# Nix Life OS - STEP 90.10 SSL, Domain, and HTTPS Production Checklist

## Target Domain

Primary domain:
https://nixlifeos.com

Optional redirect domain:
https://www.nixlifeos.com

## DNS Requirements

| Record | Type | Target |
|---|---|---|
| nixlifeos.com | A | Server public IP |
| www.nixlifeos.com | CNAME | nixlifeos.com |

## Public Ports

| Port | Purpose | Status |
|---|---|---|
| 80 | HTTP / Let's Encrypt challenge / redirect | Required |
| 443 | HTTPS | Required |

## Internal Ports

| Service | Port |
|---|---:|
| PostgreSQL | 5432 |
| Backend PHP-FPM | 9000 |
| Backend Nginx | 80 internal |
| Frontend Nginx | 80 internal |
| AI Engine | 5000 |

## Application Routing

| URL | Target |
|---|---|
| / | Vue Frontend |
| /api/v1/* | Laravel API |
| /health | Frontend health |
| /nginx-health | Nginx health |
| /ai/* | Blocked public access |

## Laravel Production Env Required Values

APP_URL=https://nixlifeos.com
FRONTEND_URL=https://nixlifeos.com
CORS_ALLOWED_ORIGINS=https://nixlifeos.com,https://www.nixlifeos.com
SANCTUM_STATEFUL_DOMAINS=nixlifeos.com,www.nixlifeos.com
SESSION_DOMAIN=.nixlifeos.com
SESSION_SECURE_COOKIE=true

## SSL Options

Recommended MVP:

1. Use Cloudflare DNS.
2. Point domain to server public IP.
3. Enable Cloudflare proxy.
4. Use Cloudflare Full Strict SSL after origin certificate or Let's Encrypt.
5. Enable Always Use HTTPS.

Alternative:

Use Certbot directly on the server.

## Validation Commands After DNS Is Ready

curl -I http://nixlifeos.com
curl -I https://nixlifeos.com
curl -i https://nixlifeos.com/api/v1/health
curl -i https://nixlifeos.com/ai/health

## Expected Results

| Test | Expected |
|---|---|
| HTTP | Redirect or 200 during temporary mode |
| HTTPS | 200 OK |
| API health | 200 OK JSON |
| AI public access | 404 Not Found |

## Final Approval Criteria

- Domain resolves to production server.
- SSL certificate is valid.
- Frontend loads over HTTPS.
- API works over HTTPS.
- AI is not publicly accessible.
- PostgreSQL is not publicly accessible.
- Backend direct port is not exposed.
- Health check automation uses HTTPS domain.
