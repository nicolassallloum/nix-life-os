/// <reference types="vite/client" />

interface Window {
  __NIX_PWA_UPDATE__?: (reloadPage?: boolean) => Promise<void>
}