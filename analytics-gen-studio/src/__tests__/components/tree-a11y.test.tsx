import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ItemMenu from '../../components/ItemMenu.tsx';
import ErrorDot from '../../components/ErrorDot.tsx';

describe('tree row controls', () => {
  it('names the row menu button and reports whether its menu is open', async () => {
    render(<ItemMenu actions={[{ label: 'Rename', icon: null, onClick: () => {} }]} />);
    const button = screen.getByRole('button', { name: 'More actions' });
    expect(button).toHaveAttribute('aria-expanded', 'false');

    await userEvent.setup().click(button);

    expect(button).toHaveAttribute('aria-expanded', 'true');
    expect(screen.getByRole('menuitem', { name: 'Rename' })).toBeInTheDocument();
  });

  it('labels the error dot with its validation messages', () => {
    render(<ErrorDot messages={['File has no domains', 'Duplicate file name: a.yaml']} />);
    expect(screen.getByRole('img', { name: 'File has no domains; Duplicate file name: a.yaml' })).toBeInTheDocument();
  });
});
