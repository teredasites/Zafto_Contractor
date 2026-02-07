import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        ops: {
          50: '#f0f4ff',
          100: '#dbe4fe',
          200: '#bfcffc',
          300: '#93aef8',
          400: '#6485f2',
          500: '#3b5eeb',
          600: '#2b46d9',
          700: '#2237b8',
          800: '#1e2f96',
          900: '#1a2671',
          950: '#0f1847',
        },
        accent: '#2b46d9',
      },
    },
  },
  plugins: [],
};

export default config;
