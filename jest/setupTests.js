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