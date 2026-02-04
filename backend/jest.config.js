module.exports = {
  testEnvironment: 'node',
  coveragePathIgnorePatterns: [
    '/node_modules/'
  ],
  testTimeout: 30000,
  testMatch: [
    '**/__tests__/**/*.test.js'
  ]
};
