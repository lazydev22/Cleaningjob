import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Builds the NUI page straight into ../ui, alongside the existing ui/assets/
// folder (fonts + background art). base: './' is required — RedM's NUI (CEF)
// loads index.html from a local file root, so asset URLs must be relative.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: '../ui',
    emptyOutDir: false,
    assetsDir: 'bundle',
  },
});
