
module.exports = {
  entry: './src/abp-filter-parser.js',
  output: {
    filename: 'abp-filter-parser-packed.js',
    library: "ABP",
    libraryTarget: "var",
    path: __dirname + '/build'
  },
  node: {
    fs: 'empty'
  }
};

