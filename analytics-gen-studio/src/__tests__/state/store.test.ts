import { describe, it, expect, beforeEach } from 'vitest';
import { useStore } from '../../state/store.ts';

describe('store', () => {
  beforeEach(() => {
    useStore.getState().resetState();
  });

  describe('config', () => {
    it('has correct defaults', () => {
      const { config } = useStore.getState();
      expect(config.inputs.events).toBe('events');
      expect(config.outputs.dart).toBe('lib/src/analytics/generated');
      expect(config.targets.plan).toBe(true);
      expect(config.targets.csv).toBe(false);
      expect(config.rules.strict_event_names).toBe(true);
      expect(config.naming.casing).toBe('snake_case');
      expect(config.meta.auto_tracking_creation_date).toBe(false);
    });

    it('setConfig replaces config', () => {
      const { setConfig, config } = useStore.getState();
      setConfig({ ...config, outputs: { dart: 'custom/path' } });
      expect(useStore.getState().config.outputs.dart).toBe('custom/path');
    });

    it('updateConfig mutates in place', () => {
      useStore.getState().updateConfig((c) => { c.targets.csv = true; });
      expect(useStore.getState().config.targets.csv).toBe(true);
    });
  });

  describe('event files', () => {
    it('addEventFile creates empty file', () => {
      useStore.getState().addEventFile('auth.yaml');
      const { eventFiles } = useStore.getState();
      expect(eventFiles).toHaveLength(1);
      expect(eventFiles[0].fileName).toBe('auth.yaml');
      expect(eventFiles[0].domains).toEqual({});
    });

    it('removeEventFile removes and clears selection', () => {
      const s = useStore.getState();
      s.addEventFile('a.yaml');
      s.addEventFile('b.yaml');
      s.setSelectedPath({ tab: 'events', fileIndex: 0 });
      s.removeEventFile(0);
      const state = useStore.getState();
      expect(state.eventFiles).toHaveLength(1);
      expect(state.eventFiles[0].fileName).toBe('b.yaml');
      expect(state.selectedPath).toBeNull();
    });

    it('addDomain creates empty domain', () => {
      const s = useStore.getState();
      s.addEventFile('auth.yaml');
      s.addDomain(0, 'auth');
      expect(useStore.getState().eventFiles[0].domains.auth).toEqual({});
    });

    it('addEvent creates event with default description', () => {
      const s = useStore.getState();
      s.addEventFile('auth.yaml');
      s.addDomain(0, 'auth');
      s.addEvent(0, 'auth', 'login');
      const event = useStore.getState().eventFiles[0].domains.auth.login;
      expect(event.description).toBe('No description provided');
      expect(event.parameters).toEqual({});
    });

    it('updateEvent preserves parameters', () => {
      const s = useStore.getState();
      s.addEventFile('auth.yaml');
      s.addDomain(0, 'auth');
      s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'method', 'string');
      s.updateEvent(0, 'auth', 'login', { deprecated: true, parameters: {} });
      const event = useStore.getState().eventFiles[0].domains.auth.login;
      expect(event.deprecated).toBe(true);
      // Parameters preserved even though empty obj was passed
      expect(event.parameters.method).toBe('string');
    });

    it('addParameter with null creates shared ref', () => {
      const s = useStore.getState();
      s.addEventFile('auth.yaml');
      s.addDomain(0, 'auth');
      s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'session_id', null);
      expect(useStore.getState().eventFiles[0].domains.auth.login.parameters.session_id).toBeNull();
    });

    it('removeParameter deletes parameter', () => {
      const s = useStore.getState();
      s.addEventFile('auth.yaml');
      s.addDomain(0, 'auth');
      s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'method', 'string');
      s.removeParameter(0, 'auth', 'login', 'method');
      expect(useStore.getState().eventFiles[0].domains.auth.login.parameters).toEqual({});
    });

    it('removeDomain clears selection', () => {
      const s = useStore.getState();
      s.addEventFile('auth.yaml');
      s.addDomain(0, 'auth');
      s.setSelectedPath({ tab: 'events', fileIndex: 0, domain: 'auth' });
      s.removeDomain(0, 'auth');
      expect(useStore.getState().selectedPath).toBeNull();
    });

    it('removeEvent clears selection', () => {
      const s = useStore.getState();
      s.addEventFile('auth.yaml');
      s.addDomain(0, 'auth');
      s.addEvent(0, 'auth', 'login');
      s.setSelectedPath({ tab: 'events', fileIndex: 0, domain: 'auth', event: 'login' });
      s.removeEvent(0, 'auth', 'login');
      expect(useStore.getState().selectedPath).toBeNull();
    });
  });

  describe('shared param files', () => {
    it('add/remove shared param file', () => {
      const s = useStore.getState();
      s.addSharedParamFile('shared.yaml');
      expect(useStore.getState().sharedParamFiles).toHaveLength(1);
      s.removeSharedParamFile(0);
      expect(useStore.getState().sharedParamFiles).toHaveLength(0);
    });

    it('add/update/remove shared param', () => {
      const s = useStore.getState();
      s.addSharedParamFile('shared.yaml');
      s.addSharedParam(0, 'sid', { type: 'string' });
      expect(useStore.getState().sharedParamFiles[0].parameters.sid).toEqual({ type: 'string' });

      s.updateSharedParam(0, 'sid', { type: 'string', description: 'Session' });
      expect((useStore.getState().sharedParamFiles[0].parameters.sid as any).description).toBe('Session');

      s.removeSharedParam(0, 'sid');
      expect(useStore.getState().sharedParamFiles[0].parameters).toEqual({});
    });
  });

  describe('context files', () => {
    it('add/remove context file', () => {
      const s = useStore.getState();
      s.addContextFile('user.yaml', 'user_props');
      const file = useStore.getState().contextFiles[0];
      expect(file.fileName).toBe('user.yaml');
      expect(file.contextName).toBe('user_props');
      expect(file.properties).toEqual({});

      s.removeContextFile(0);
      expect(useStore.getState().contextFiles).toHaveLength(0);
    });

    it('add/update/remove context property', () => {
      const s = useStore.getState();
      s.addContextFile('user.yaml', 'user_props');
      s.addContextProperty(0, 'count', { type: 'int', operations: ['set'] });
      expect(useStore.getState().contextFiles[0].properties.count).toEqual({ type: 'int', operations: ['set'] });

      s.updateContextProperty(0, 'count', { type: 'int', operations: ['set', 'increment'] });
      expect((useStore.getState().contextFiles[0].properties.count as any).operations).toEqual(['set', 'increment']);

      s.removeContextProperty(0, 'count');
      expect(useStore.getState().contextFiles[0].properties).toEqual({});
    });
  });

  describe('project load/reset', () => {
    it('resetState restores defaults', () => {
      const s = useStore.getState();
      s.addEventFile('test.yaml');
      s.setActiveTab('events');
      s.resetState();
      const state = useStore.getState();
      expect(state.eventFiles).toHaveLength(0);
      expect(state.activeTab).toBe('config');
    });

    it('loadProject hydrates only known keys', () => {
      useStore.getState().loadProject({
        activeTab: 'events',
        config: { ...useStore.getState().config, outputs: { dart: 'custom' } },
        eventFiles: [{ fileName: 'a.yaml', domains: {} }],
      } as any);
      const state = useStore.getState();
      expect(state.activeTab).toBe('events');
      expect(state.config.outputs.dart).toBe('custom');
      expect(state.eventFiles).toHaveLength(1);
      // Unknown keys like 'version' should NOT be in state
      expect((state as any).version).toBeUndefined();
    });

    it('loadProject does not break with empty data', () => {
      useStore.getState().loadProject({});
      const state = useStore.getState();
      expect(state.activeTab).toBe('config');
      expect(state.eventFiles).toHaveLength(0);
    });
  });

  describe('tab navigation', () => {
    it('setActiveTab changes tab', () => {
      useStore.getState().setActiveTab('shared');
      expect(useStore.getState().activeTab).toBe('shared');
    });
  });

  describe('selection', () => {
    it('setSelectedPath stores and clears', () => {
      const path = { tab: 'events' as const, fileIndex: 0, domain: 'auth' };
      useStore.getState().setSelectedPath(path);
      expect(useStore.getState().selectedPath).toEqual(path);
      useStore.getState().setSelectedPath(null);
      expect(useStore.getState().selectedPath).toBeNull();
    });
  });
});
