import { defineConfig } from 'vite';

export default defineConfig({
  server: { host: 'localhost' },
  build: {
    rolldownOptions: {
      output: {
        codeSplitting: {
          groups: [{
            name: 'firebase-firestore',
            test: /node_modules[\\/]@firebase[\\/]firestore[\\/]/,
            includeDependenciesRecursively: true,
            maxSize: 350_000,
          }],
        },
      },
    },
  },
});
