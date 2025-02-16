module.exports = {
  content: [
    './app/views/**/*.{erb,haml,html,slim}',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.{js,jsx}',
    './app/assets/stylesheets/**/*.css',
    './app/components/**/*.{erb,haml,html,slim,rb}'
  ],
  plugins: [],
  theme: {
    fontFamily: {
      serif: ['Times New Roman', 'serif'],
      sans: ['Times New Roman', 'serif'], // This makes Times New Roman the default font
    },
  },
}