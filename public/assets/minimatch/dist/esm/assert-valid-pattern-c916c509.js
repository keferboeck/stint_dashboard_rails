const MAX_PATTERN_LENGTH = 1024 * 64;
export const assertValidPattern = (pattern) => {
    if (typeof pattern !== 'string') {
        throw new TypeError('invalid pattern');
    }
    if (pattern.length > MAX_PATTERN_LENGTH) {
        throw new TypeError('pattern is too long');
    }
};
//# sourceMappingURL=/assets/minimatch/dist/esm/assert-valid-pattern-4f1503c9.js.map