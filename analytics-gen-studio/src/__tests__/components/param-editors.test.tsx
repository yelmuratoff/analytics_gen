import type { ReactNode } from 'react';
import { describe, it, expect, beforeEach } from 'vitest';
import { render as renderWithoutTheme, screen, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider } from '@mui/material/styles';
import type { RJSFSchema } from '@rjsf/utils';
import { useStore } from '../../state/store.ts';
import { applySchemaConstants } from '../../schemas/constants.ts';
import { getTheme } from '../../theme.ts';
import ParameterEditor from '../../components/events/ParameterEditor.tsx';
import SharedParamEditor from '../../components/shared/SharedParamEditor.tsx';
import ContextPropertyEditor from '../../components/contexts/ContextPropertyEditor.tsx';

const parameterSchema: RJSFSchema = {
  type: 'object',
  properties: { description: { type: 'string', title: 'Description' } },
};

const theme = getTheme('light');

function render(ui: ReactNode) {
  return renderWithoutTheme(ui, {
    wrapper: ({ children }) => <ThemeProvider theme={theme}>{children}</ThemeProvider>,
  });
}

async function chooseType(type: string) {
  const user = userEvent.setup();
  await user.click(screen.getByRole('combobox', { name: 'Type' }));
  await user.click(await screen.findByRole('option', { name: type }));
}

describe('parameter editors', () => {
  beforeEach(() => {
    applySchemaConstants({
      defaultEventDescription: 'No description provided',
      snakeCaseDomainPattern: /^[a-z0-9_]+$/,
      snakeCaseParamPattern: /^[a-z][a-z0-9_]*$/,
      parameterTypes: ['string', 'int'],
    });
    useStore.setState({
      eventFiles: [{
        fileName: 'auth.yaml',
        domains: {
          auth: {
            login: {
              description: 'User logs in',
              parameters: {
                flow_id: null,
                method: { type: 'string', description: 'Login method' },
              },
            },
          },
        },
      }],
      sharedParamFiles: [{ fileName: 'shared.yaml', parameters: { user_id: { type: 'string' } } }],
      contextFiles: [{
        fileName: 'user.yaml',
        contextName: 'user',
        properties: { plan: { type: 'string', operations: ['set'] } },
      }],
    });
  });

  it('renders nothing when the selected shared parameter file disappears', () => {
    const { container } = render(
      <SharedParamEditor fileIndex={0} paramName="user_id" parameterSchema={parameterSchema} />,
    );

    act(() => useStore.setState({ sharedParamFiles: [] }));

    expect(container).toBeEmptyDOMElement();
  });

  it('switches from a shared reference to a local parameter', () => {
    const { rerender } = render(
      <ParameterEditor fileIndex={0} domain="auth" eventName="login" paramName="flow_id" parameterSchema={parameterSchema} />,
    );
    expect(screen.getByText('Shared Parameter')).toBeInTheDocument();

    rerender(
      <ParameterEditor fileIndex={0} domain="auth" eventName="login" paramName="method" parameterSchema={parameterSchema} />,
    );

    expect(screen.getByRole('combobox', { name: 'Type' })).toBeInTheDocument();
  });

  it('keeps the other fields of an event parameter when its type changes', async () => {
    render(
      <ParameterEditor fileIndex={0} domain="auth" eventName="login" paramName="method" parameterSchema={parameterSchema} />,
    );

    await chooseType('int');

    expect(useStore.getState().eventFiles[0].domains.auth.login.parameters.method)
      .toEqual({ type: 'int', description: 'Login method' });
  });

  it('keeps the operations of a context property when its type changes', async () => {
    render(
      <ContextPropertyEditor fileIndex={0} propName="plan" parameterSchema={parameterSchema} operations={['set', 'increment']} />,
    );

    await chooseType('int');

    expect(useStore.getState().contextFiles[0].properties.plan)
      .toEqual({ type: 'int', operations: ['set'] });
  });
});
