import type { ReactNode } from 'react';
import { describe, it, expect, beforeEach } from 'vitest';
import { render as renderWithoutTheme, screen, act } from '@testing-library/react';
import { ThemeProvider } from '@mui/material/styles';
import { useStore } from '../../state/store.ts';
import { getTheme } from '../../theme.ts';
import FileTree from '../../components/events/FileTree.tsx';
import YamlPreview from '../../components/YamlPreview.tsx';

const theme = getTheme('light');

function render(ui: ReactNode) {
  return renderWithoutTheme(ui, {
    wrapper: ({ children }) => <ThemeProvider theme={theme}>{children}</ThemeProvider>,
  });
}

describe('selection sync', () => {
  beforeEach(() => {
    useStore.getState().resetState();
    useStore.setState({
      activeTab: 'events',
      eventFiles: [
        { fileName: 'auth.yaml', domains: { auth: { login: { description: 'Login', parameters: { method: 'string' } } } } },
        { fileName: 'shop.yaml', domains: { shop: { purchase: { description: 'Purchase', parameters: {} } } } },
      ],
    });
  });

  it('expands the events tree down to a newly selected event', () => {
    render(<FileTree />);
    expect(screen.queryByText('method')).not.toBeInTheDocument();

    act(() => useStore.getState().setSelectedPath({ tab: 'events', fileIndex: 0, domain: 'auth', event: 'login' }));

    expect(screen.getByText('login')).toBeInTheDocument();
    expect(screen.getByText('method')).toBeInTheDocument();
  });

  it('shows the file of the selected item in the YAML preview', () => {
    render(<YamlPreview />);
    expect(screen.getByRole('tab', { name: 'auth.yaml' })).toHaveAttribute('aria-selected', 'true');

    act(() => useStore.getState().setSelectedPath({ tab: 'events', fileIndex: 1, domain: 'shop' }));

    expect(screen.getByRole('tab', { name: 'shop.yaml' })).toHaveAttribute('aria-selected', 'true');
  });
});
