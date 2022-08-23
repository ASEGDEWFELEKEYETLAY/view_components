module.exports = {
  map: {
    annotation: false
  },
  plugins: [
    require('postcss-import'),
    require('postcss-preset-env')({
      stage: 3,
      // https://preset-env.cssdb.org/
      features: {
        'nesting-rules': true
      }
    }),
    require('cssnano'),
  ],
};
