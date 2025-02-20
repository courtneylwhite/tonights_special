module.exports = {
    testEnvironment: 'jsdom',
    roots: ['<rootDir>/jest'],
    moduleNameMapper: {
        '^@/(.*)$': '<rootDir>/app/javascript/$1'
    },
    setupFilesAfterEnv: ['<rootDir>/jest/setupTests.js'],
    transform: {
        '^.+\\.(js|jsx)$': 'babel-jest'
    },
    transformIgnorePatterns: ['node_modules/(?!(@babel/runtime|lucide-react)/)']
};
