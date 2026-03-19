import { describe, it, expect, beforeEach } from 'vitest';
import { useStore } from '../../state/store.ts';

describe('store', () => {
  beforeEach(() => useStore.getState().resetState());

  describe('config', () => {
    it('has correct defaults', () => {
      const { config } = useStore.getState();
      expect(config.inputs.events).toBe('events');
      expect(config.inputs.shared_parameters).toEqual([]);
      expect(config.inputs.contexts).toEqual([]);
      expect(config.inputs.imports).toEqual([]);
      expect(config.outputs.dart).toBe('lib/src/analytics/generated');
      expect(config.outputs.docs).toBeUndefined();
      expect(config.outputs.exports).toBeUndefined();
      expect(config.targets.plan).toBe(true);
      expect(config.targets.csv).toBe(false);
      expect(config.rules.strict_event_names).toBe(true);
      expect(config.rules.enforce_centrally_defined_parameters).toBe(false);
      expect(config.naming.casing).toBe('snake_case');
      expect(config.naming.enforce_snake_case_domains).toBe(true);
      expect(config.naming.domain_aliases).toEqual({});
      expect(config.meta.auto_tracking_creation_date).toBe(false);
    });

    it('setConfig replaces config entirely', () => {
      const { setConfig, config } = useStore.getState();
      setConfig({ ...config, outputs: { dart: 'custom/path' } });
      expect(useStore.getState().config.outputs.dart).toBe('custom/path');
    });

    it('updateConfig mutates in place via immer', () => {
      useStore.getState().updateConfig((c) => { c.targets.csv = true; c.targets.sql = true; });
      const { targets } = useStore.getState().config;
      expect(targets.csv).toBe(true);
      expect(targets.sql).toBe(true);
    });
  });

  describe('event files', () => {
    it('addEventFile creates empty file', () => {
      useStore.getState().addEventFile('auth.yaml');
      const { eventFiles } = useStore.getState();
      expect(eventFiles).toHaveLength(1);
      expect(eventFiles[0]).toEqual({ fileName: 'auth.yaml', domains: {} });
    });

    it('removeEventFile removes and clears selection', () => {
      const s = useStore.getState();
      s.addEventFile('a.yaml');
      s.addEventFile('b.yaml');
      s.setSelectedPath({ tab: 'events', fileIndex: 0 });
      s.removeEventFile(0);
      expect(useStore.getState().eventFiles).toHaveLength(1);
      expect(useStore.getState().eventFiles[0].fileName).toBe('b.yaml');
      expect(useStore.getState().selectedPath).toBeNull();
    });

    it('addDomain creates empty domain', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml');
      s.addDomain(0, 'auth');
      expect(useStore.getState().eventFiles[0].domains.auth).toEqual({});
    });

    it('removeDomain removes domain and clears selection', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml');
      s.addDomain(0, 'auth');
      s.setSelectedPath({ tab: 'events', fileIndex: 0, domain: 'auth' });
      s.removeDomain(0, 'auth');
      expect(useStore.getState().eventFiles[0].domains.auth).toBeUndefined();
      expect(useStore.getState().selectedPath).toBeNull();
    });

    it('addEvent creates with default description and empty params', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml'); s.addDomain(0, 'auth');
      s.addEvent(0, 'auth', 'login');
      const event = useStore.getState().eventFiles[0].domains.auth.login;
      expect(event.description).toBe('No description provided');
      expect(event.parameters).toEqual({});
    });

    it('removeEvent removes and clears selection', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml'); s.addDomain(0, 'auth'); s.addEvent(0, 'auth', 'login');
      s.setSelectedPath({ tab: 'events', fileIndex: 0, domain: 'auth', event: 'login' });
      s.removeEvent(0, 'auth', 'login');
      expect(useStore.getState().eventFiles[0].domains.auth.login).toBeUndefined();
      expect(useStore.getState().selectedPath).toBeNull();
    });

    it('updateEvent preserves existing parameters', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml'); s.addDomain(0, 'auth'); s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'method', 'string');
      s.updateEvent(0, 'auth', 'login', { deprecated: true, parameters: {} });
      const event = useStore.getState().eventFiles[0].domains.auth.login;
      expect(event.deprecated).toBe(true);
      expect(event.parameters.method).toBe('string');
    });

    it('addParameter with string (shorthand)', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml'); s.addDomain(0, 'auth'); s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'method', 'string');
      expect(useStore.getState().eventFiles[0].domains.auth.login.parameters.method).toBe('string');
    });

    it('addParameter with null (shared ref)', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml'); s.addDomain(0, 'auth'); s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'session_id', null);
      expect(useStore.getState().eventFiles[0].domains.auth.login.parameters.session_id).toBeNull();
    });

    it('addParameter with full object', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml'); s.addDomain(0, 'auth'); s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'method', { type: 'string', allowed_values: ['email'] });
      const p = useStore.getState().eventFiles[0].domains.auth.login.parameters.method;
      expect(p).toEqual({ type: 'string', allowed_values: ['email'] });
    });

    it('updateParameter replaces value', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml'); s.addDomain(0, 'auth'); s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'method', 'string');
      s.updateParameter(0, 'auth', 'login', 'method', { type: 'string', description: 'Updated' });
      const p = useStore.getState().eventFiles[0].domains.auth.login.parameters.method as any;
      expect(p.description).toBe('Updated');
    });

    it('updateParameter from null to object', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml'); s.addDomain(0, 'auth'); s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'sid', null);
      s.updateParameter(0, 'auth', 'login', 'sid', { type: 'string' });
      expect(useStore.getState().eventFiles[0].domains.auth.login.parameters.sid).toEqual({ type: 'string' });
    });

    it('updateParameter from object to string', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml'); s.addDomain(0, 'auth'); s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'method', { type: 'string', description: 'x' });
      s.updateParameter(0, 'auth', 'login', 'method', 'int');
      expect(useStore.getState().eventFiles[0].domains.auth.login.parameters.method).toBe('int');
    });

    it('removeParameter deletes', () => {
      const s = useStore.getState();
      s.addEventFile('f.yaml'); s.addDomain(0, 'auth'); s.addEvent(0, 'auth', 'login');
      s.addParameter(0, 'auth', 'login', 'method', 'string');
      s.removeParameter(0, 'auth', 'login', 'method');
      expect(useStore.getState().eventFiles[0].domains.auth.login.parameters).toEqual({});
    });
  });

  describe('shared param files', () => {
    it('add and remove file', () => {
      useStore.getState().addSharedParamFile('shared.yaml');
      expect(useStore.getState().sharedParamFiles).toHaveLength(1);
      useStore.getState().removeSharedParamFile(0);
      expect(useStore.getState().sharedParamFiles).toHaveLength(0);
    });

    it('removeSharedParamFile clears selection', () => {
      useStore.getState().addSharedParamFile('s.yaml');
      useStore.getState().setSelectedPath({ tab: 'shared', fileIndex: 0, parameter: 'sid' });
      useStore.getState().removeSharedParamFile(0);
      expect(useStore.getState().selectedPath).toBeNull();
    });

    it('add/update/remove param', () => {
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
    it('add with contextName and remove', () => {
      useStore.getState().addContextFile('user.yaml', 'user_props');
      const file = useStore.getState().contextFiles[0];
      expect(file.fileName).toBe('user.yaml');
      expect(file.contextName).toBe('user_props');
      expect(file.properties).toEqual({});
      useStore.getState().removeContextFile(0);
      expect(useStore.getState().contextFiles).toHaveLength(0);
    });

    it('removeContextFile clears selection', () => {
      useStore.getState().addContextFile('c.yaml', 'ctx');
      useStore.getState().setSelectedPath({ tab: 'contexts', fileIndex: 0, contextProperty: 'uid' });
      useStore.getState().removeContextFile(0);
      expect(useStore.getState().selectedPath).toBeNull();
    });

    it('add/update/remove property with operations', () => {
      const s = useStore.getState();
      s.addContextFile('u.yaml', 'user_props');
      s.addContextProperty(0, 'count', { type: 'int', operations: ['set'] });
      expect(useStore.getState().contextFiles[0].properties.count).toEqual({ type: 'int', operations: ['set'] });

      s.updateContextProperty(0, 'count', { type: 'int', operations: ['set', 'increment'] });
      expect((useStore.getState().contextFiles[0].properties.count as any).operations).toEqual(['set', 'increment']);

      s.removeContextProperty(0, 'count');
      expect(useStore.getState().contextFiles[0].properties).toEqual({});
    });
  });

  describe('project load/reset', () => {
    it('resetState restores all defaults', () => {
      const s = useStore.getState();
      s.addEventFile('test.yaml');
      s.addSharedParamFile('s.yaml');
      s.addContextFile('c.yaml', 'ctx');
      s.setActiveTab('events');
      s.resetState();
      const state = useStore.getState();
      expect(state.eventFiles).toHaveLength(0);
      expect(state.sharedParamFiles).toHaveLength(0);
      expect(state.contextFiles).toHaveLength(0);
      expect(state.activeTab).toBe('config');
      expect(state.selectedPath).toBeNull();
    });

    it('loadProject hydrates only known keys', () => {
      useStore.getState().loadProject({
        activeTab: 'events',
        config: { ...useStore.getState().config, outputs: { dart: 'custom' } },
        eventFiles: [{ fileName: 'a.yaml', domains: {} }],
        sharedParamFiles: [{ fileName: 's.yaml', parameters: {} }],
        contextFiles: [{ fileName: 'c.yaml', contextName: 'ctx', properties: {} }],
      } as any);
      const state = useStore.getState();
      expect(state.activeTab).toBe('events');
      expect(state.eventFiles).toHaveLength(1);
      expect(state.sharedParamFiles).toHaveLength(1);
      expect(state.contextFiles).toHaveLength(1);
      expect((state as any).version).toBeUndefined();
    });

    it('loadProject with empty data keeps defaults', () => {
      useStore.getState().loadProject({});
      expect(useStore.getState().activeTab).toBe('config');
      expect(useStore.getState().eventFiles).toHaveLength(0);
    });

    it('loadProject ignores unknown keys like version', () => {
      useStore.getState().loadProject({ version: 1, activeTab: 'shared' } as any);
      expect(useStore.getState().activeTab).toBe('shared');
      expect((useStore.getState() as any).version).toBeUndefined();
    });

    it('loadProject with only config preserves empty arrays for others', () => {
      useStore.getState().loadProject({
        config: { ...useStore.getState().config, outputs: { dart: 'test' } },
      } as any);
      const s = useStore.getState();
      expect(s.config.outputs.dart).toBe('test');
      expect(s.eventFiles).toHaveLength(0);
      expect(s.sharedParamFiles).toHaveLength(0);
      expect(s.contextFiles).toHaveLength(0);
    });

    it('loadProject full roundtrip from studio_export format', () => {
      const projectJson = {
        version: 1,
        activeTab: 'events',
        config: {
          inputs: { events: 'events', shared_parameters: ['s.yaml'], contexts: ['c.yaml'], imports: [] },
          outputs: { dart: 'lib/gen', docs: 'docs/' },
          targets: { csv: true, json: false, sql: false, docs: true, plan: true, test_matchers: false },
          rules: { include_event_description: true, strict_event_names: false, enforce_centrally_defined_parameters: false, prevent_event_parameter_duplicates: false },
          naming: { casing: 'title_case', enforce_snake_case_domains: true, enforce_snake_case_parameters: true, event_name_template: '{domain}: {event}', identifier_template: '{domain}.{event}', domain_aliases: { auth: 'Auth' } },
          meta: { auto_tracking_creation_date: true, include_meta_in_parameters: false },
        },
        eventFiles: [{
          fileName: 'auth.yaml',
          domains: {
            auth: {
              login: {
                description: 'User logs in',
                deprecated: true,
                parameters: { session_id: null, method: 'string' },
              },
            },
          },
        }],
        sharedParamFiles: [{ fileName: 's.yaml', parameters: { session_id: { type: 'string' } } }],
        contextFiles: [{ fileName: 'c.yaml', contextName: 'user_props', properties: { count: { type: 'int', operations: ['set'] } } }],
      };

      useStore.getState().loadProject(projectJson as any);
      const s = useStore.getState();

      expect(s.activeTab).toBe('events');
      expect(s.config.targets.csv).toBe(true);
      expect(s.config.naming.casing).toBe('title_case');
      expect(s.config.naming.domain_aliases.auth).toBe('Auth');
      expect(s.config.meta.auto_tracking_creation_date).toBe(true);
      expect(s.eventFiles[0].domains.auth.login.parameters.session_id).toBeNull();
      expect(s.eventFiles[0].domains.auth.login.parameters.method).toBe('string');
      expect(s.sharedParamFiles[0].parameters.session_id).toEqual({ type: 'string' });
      expect((s.contextFiles[0].properties.count as any).operations).toEqual(['set']);
    });
  });

  describe('navigation & selection', () => {
    it('setActiveTab changes tab', () => {
      useStore.getState().setActiveTab('contexts');
      expect(useStore.getState().activeTab).toBe('contexts');
    });

    it('setSelectedPath stores path', () => {
      const p = { tab: 'events' as const, fileIndex: 0, domain: 'auth', event: 'login', parameter: 'method' };
      useStore.getState().setSelectedPath(p);
      expect(useStore.getState().selectedPath).toEqual(p);
    });

    it('setSelectedPath(null) clears', () => {
      useStore.getState().setSelectedPath({ tab: 'events', fileIndex: 0 });
      useStore.getState().setSelectedPath(null);
      expect(useStore.getState().selectedPath).toBeNull();
    });
  });
});
