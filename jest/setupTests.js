//setupTests.js
import '@testing-library/jest-dom';
import 'whatwg-fetch';
import { TextEncoder, TextDecoder } from 'util';

global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder;

// Mock all Lucide icons
jest.mock('lucide-react', () => ({
    ChevronDown: () => 'ChevronDown',
    ChevronUp: () => 'ChevronUp',
    Minimize2: () => 'Minimize2',
    Maximize2: () => 'Maximize2',
    Search: () => 'Search',
    Plus: () => 'Plus',
    X: () => 'X'
}));

// ===== Add the following code to silence console output =====

// 1. Store original console methods
const originalLog = console.log;
const originalError = console.error;
const originalWarn = console.warn;

// 2. Create a filter function to determine which logs to keep
const shouldKeepLog = (args) => {
    // Keep logs that have [TEST] prefix or specifically flagged logs you want to see
    return args.length > 0 &&
        typeof args[0] === 'string' &&
        (args[0].includes('[TEST]') || args[0].includes('IMPORTANT:'));
};

// 3. Mock console methods
console.log = (...args) => {
    if (shouldKeepLog(args)) {
        originalLog(...args);
    }
    // Otherwise silently drop the log
};

console.error = (...args) => {
    // Always show React testing library errors as they're usually important
    if (shouldKeepLog(args) || (args[0] && args[0].includes('Error:'))) {
        originalError(...args);
    }
    // Filter out the JSDOM "not implemented" errors
    else if (!(args[0] && args[0].toString().includes('Not implemented'))) {
        originalError(...args);
    }
};

console.warn = (...args) => {
    if (shouldKeepLog(args)) {
        originalWarn(...args);
    }
    // Otherwise silently drop the warning
};

// 4. Mock unimplemented browser APIs to prevent JSDOM errors
Object.defineProperty(window, 'scrollTo', {
    value: jest.fn(),
    writable: true
});

// 5. Restore original console methods after tests
afterAll(() => {
    console.log = originalLog;
    console.error = originalError;
    console.warn = originalWarn;
});