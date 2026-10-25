const isMac = typeof navigator !== 'undefined' && /Mac/.test(navigator.platform);

/** Label of the shortcut modifier key (Cmd on macOS, Ctrl elsewhere), ready to prefix a key name. */
export const modKeyLabel = isMac ? '⌘' : 'Ctrl+';
