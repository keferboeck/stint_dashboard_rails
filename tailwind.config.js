/** @type {import('tailwindcss').Config} */
module.exports = {
  // Ensure JIT sees your classes (views, JS, and the tailwind input itself)
  content: [
    "./app/views/**/*.{erb,haml,html,slim}",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.{js,ts}",
    "./app/assets/**/*.{css,scss}"
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          green:  "#16E990",
          purple: "#A49EF2",
          black:  "#121212",
          grey:   "#C4C4C4",
          white:  "#FFFFFF",
        },
      },
      keyframes: {
        'slide-in': { '0%': { transform: 'translateY(-10px)', opacity: '0' }, '100%': { transform: 'translateY(0)', opacity: '1' } },
        'fade-out': { '0%': { opacity: '1' }, '100%': { opacity: '0' } },
        spin: { to: { transform: 'rotate(360deg)' } },
        ping: { '75%, 100%': { transform: 'scale(2)', opacity: '0' } },
        pulse: { '50%': { opacity: '.5' } },
        bounce: {
          '0%, 100%': { transform: 'translateY(-25%)', animationTimingFunction: 'cubic-bezier(0.8,0,1,1)' },
          '50%': { transform: 'none', animationTimingFunction: 'cubic-bezier(0,0,0.2,1)' },
        },
      },
      animation: {
        'slide-in': 'slide-in 0.3s ease-out',
        'fade-out': 'fade-out 0.5s ease-in forwards',
        none: 'none',
        spin: 'spin 1s linear infinite',
        ping: 'ping 1s cubic-bezier(0, 0, 0.2, 1) infinite',
        pulse: 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        bounce: 'bounce 1s infinite',
      },
      container: { center: true, padding: '0rem' },
      boxShadow: {
        sm: '0 1px 2px 0 rgba(0,0,0,0.05)',
        DEFAULT: '0 1px 3px 0 rgba(0,0,0,0.1), 0 1px 2px 0 rgba(0,0,0,0.06)',
        md: '0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06)',
        lg: '0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05)',
        xl: '0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04)',
        '2xl': '0 25px 50px -12px rgba(0,0,0,0.25)',
        inner: 'inset 0 2px 4px 0 rgba(0,0,0,0.06)',
        none: 'none',
        'custom-shadow': '0 0 0.6rem rgba(0, 0, 0, 0.5)',
      },
      borderRadius: { '2xl': '1rem', '3xl': '1.5rem' },
      fontFamily: {
        sans: ['"Mabry Pro"', 'ui-sans-serif', 'system-ui', '-apple-system', 'BlinkMacSystemFont', '"Segoe UI"', 'Roboto', '"Helvetica Neue"', 'Arial', '"Noto Sans"', 'sans-serif'],
        rustico: ['Rustico'],
      },
      fontSize: {
        h1: ['3.75rem', { lineHeight: '4.125rem', letterSpacing: '0rem' }],
        h2: ['2.875rem', { lineHeight: '3.375rem' }],
        h3: ['2rem', { lineHeight: '2.25rem' }],
        h4: ['1.75rem', { lineHeight: '2.25rem' }],
        h5: ['1.35rem', { lineHeight: '2rem' }],
        h6: ['1.125rem', { lineHeight: '1.625rem' }],
        '80px': ['4.4rem',  { lineHeight: '1', letterSpacing: '-.028em' }],
        '64px': '3.2rem',
        '56px': '2.8rem',
        '50px': ['2.5rem', { lineHeight: '1.05', letterSpacing: '-.028em' }],
        '48px': ['2.4rem', { lineHeight: '1.05', letterSpacing: '-.028em' }],
        '45px': ['2.25rem', { lineHeight: '1.05', letterSpacing: '-.028em' }],
        '40px': ['1.9rem', { lineHeight: '1.25', letterSpacing: '-.02em' }],
        '32px': ['1.6rem', { lineHeight: '1.18', letterSpacing: '-.02em' }],
        '28px': ['1.4rem', { lineHeight: '1.2', letterSpacing: '-.01em' }],
        '25px': ['1.25rem', { lineHeight: '1.3', letterSpacing: '-.01em' }],
        '26px': '1.3rem',
        '22px': '1.1rem',
        '21px': '1.05rem',
        '20px': '1rem',
        '18px': '.9rem',
        '17px': '.85rem',
        '16px': '.8rem',
        '15px': '0.75rem',
        '14px': '.7rem',
        '11px': '11px',
      },
      // If you actually use @tailwindcss/typography, keep this. Otherwise delete it.
      // typography: ({ theme }) => ({
      //   DEFAULT: {
      //     css: {
      //       a: { color: theme('colors.brand.purple'), textDecoration: 'underline' },
      //       '.text-blue': { color: theme('colors.brand.green') },
      //     },
      //   },
      // }),
    },
  },
  plugins: [
    // require('@tailwindcss/typography'), // uncomment only if you installed it
  ],
};