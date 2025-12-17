# TODO – `analytics_gen`

## 🔴 CRITICAL (P0) - Must Fix Before Production

### 1. Refactor God Objects - Break Down Orchestration Classes
**Location**: `lib/src/generator/code_generator.dart:60-122`

**Problem**:
`CodeGenerator.generate()` violates Single Responsibility Principle by handling 7+ concerns:
- Directory preparation
- Domain file generation
- Context file generation
- Stale file cleanup
- Barrel file generation
- Analytics singleton generation
- Test matcher generation

**Impact**:
- Hard to test (need to mock 7 different concerns)
- Can't parallelize generation steps
- Adding new artifacts requires modifying monolith
- 350+ lines of orchestration logic

**Solution**:
```dart
// Introduce task-based architecture
abstract class GenerationTask {
  Future<void> execute(GenerationContext context);
}

class CodeGenerator {
  Future<void> generate(Map<String, AnalyticsDomain> domains) async {
    final context = GenerationContext(domains, config, projectRoot);

    final tasks = [
      PrepareDirectoriesTask(),
      GenerateDomainFilesTask(),
      GenerateContextFilesTask(),
      CleanStaleFilesTask(),
      GenerateBarrelFileTask(),
      GenerateAnalyticsClassTask(),
      if (config.generateTestMatchers) GenerateMatchersTask(),
    ];

    // Can now run in parallel where safe
    await TaskRunner().execute(tasks, context);
  }
}

// Each task is ~50-70 lines, testable in isolation
class GenerateDomainFilesTask extends GenerationTask {
  @override
  Future<void> execute(GenerationContext context) async {
    await Future.wait(context.domains.entries.map((entry) async {
      final content = context.eventRenderer.renderDomainFile(...);
      await context.outputManager.writeFile(...);
    }));
  }
}
```

**Acceptance Criteria**:
- [ ] Split `CodeGenerator` into 7+ single-purpose tasks
- [ ] Each task is <100 lines
- [ ] Add unit tests for each task
- [ ] Parallel execution where safe (domains can generate in parallel)
- [ ] No breaking changes to public API

---

### 2. Fix Type Casting Safety - Add Runtime Type Checks
**Location**: `lib/src/core/analytics_capabilities.dart:74-78`

**Problem**:
178 unsafe type casts in codebase. Most critical in `CapabilityRegistry`:

```dart
T? getCapability<T extends AnalyticsCapability>(CapabilityKey<T> key) {
  final capability = _capabilities[key.name];
  if (capability == null) return null;
  return capability as T;  // ⚠️ Unsafe: assumes type is correct
}
```

**Risk**:
- If someone registers wrong type: `register(userPropertiesKey, WrongCapability())`, crashes at runtime
- Dart can't statically verify type safety
- Silent corruption if cast succeeds but type is wrong

**Solution**:
```dart
T? getCapability<T extends AnalyticsCapability>(CapabilityKey<T> key) {
  final capability = _capabilities[key.name];
  if (capability == null) return null;

  // Defensive check: verify type matches
  if (capability is! T) {
    throw StateError(
      'Capability registry corrupted: "$key" has type '
      '${capability.runtimeType}, expected $T. '
      'This likely means register<T>() was called with wrong type.'
    );
  }

  return capability;  // Safe: type-checked above
}
```

**Acceptance Criteria**:
- [ ] Add type check to `CapabilityRegistry.getCapability()`
- [ ] Add test case for wrong type registration
- [ ] Audit other 177 `as` casts for similar issues
- [ ] Consider using `cast<T>()` with better error messages
- [ ] Document type safety guarantees in comments

---

### 3. Add Integration Tests - Full Pipeline Coverage
**Location**: `test/integration/` (new directory)

**Problem**:
Zero end-to-end tests. Current test suite:
- ✅ 200+ unit tests (isolated components)
- ❌ 0 integration tests (full pipeline)

**Missing Coverage**:
```
YAML → Parse → Validate → Generate Code → Compile → Execute → Verify Runtime Behavior
```

**Risk**:
- Unit tests can pass while generated code doesn't compile
- No verification that generated methods actually call IAnalytics.logEvent()
- Parser + Generator interaction not tested
- Breaking changes slip through

**Solution**:
```dart
// test/integration/full_pipeline_test.dart
import 'package:test/test.dart';
import 'package:file/memory.dart';

void main() {
  test('full generation pipeline produces compilable, working code', () async {
    // 1. Setup: Create YAML in memory filesystem
    final fs = MemoryFileSystem();
    final yamlContent = '''
auth:
  login:
    description: User logged in
    parameters:
      method:
        type: string
        allowed_values: ['email', 'google', 'apple']
      timestamp: int
''';

    fs.file('events/auth.yaml').writeAsStringSync(yamlContent);

    // 2. Parse YAML
    final config = AnalyticsConfig.fromYaml(fs.file('analytics_gen.yaml'));
    final parser = createParser(config);
    final domains = await parser.parseEvents([...]);

    expect(domains, contains('auth'));
    expect(domains['auth']!.events, hasLength(1));

    // 3. Generate code
    final generator = CodeGenerator(config: config, projectRoot: '/tmp');
    await generator.generate(domains);

    // 4. Verify generated file exists and contains expected content
    final generatedFile = fs.file('lib/analytics/events/auth_events.dart');
    expect(generatedFile.existsSync(), isTrue);

    final content = generatedFile.readAsStringSync();
    expect(content, contains('mixin AnalyticsAuth'));
    expect(content, contains('void logAuthLogin'));
    expect(content, contains('enum AnalyticsAuthLoginMethodEnum'));

    // 5. Verify generated code is valid Dart (compile check)
    final analyzeResult = await Process.run('dart', [
      'analyze',
      '--no-fatal-infos',
      generatedFile.path,
    ]);
    expect(analyzeResult.exitCode, 0, reason: 'Generated code must compile');

    // 6. Runtime test: Execute generated method
    final mock = MockAnalyticsService();
    final analytics = Analytics(mock);

    // This would normally be in generated code:
    analytics.logAuthLogin(
      method: AnalyticsAuthLoginMethodEnum.email,
      timestamp: 1234567890,
    );

    // 7. Verify event was logged correctly
    expect(mock.events, hasLength(1));
    expect(mock.events.first.name, 'auth_login');
    expect(mock.events.first.parameters, {
      'method': 'email',
      'timestamp': 1234567890,
    });
  });

  test('validation errors prevent code generation', () async {
    final invalidYaml = '''
auth:
  Invalid Event Name With Spaces:  # Should fail validation
    parameters:
      foo: string
''';

    expect(
      () => parser.parseEvents([...]),
      throwsA(isA<AnalyticsParseException>()),
    );
  });

  test('dual-write generates correct forwarding logic', () async {
    // Test that dual_write_to actually calls both events
  });

  test('deprecated events generate @Deprecated annotation', () async {
    // Verify generated code has correct deprecation warnings
  });
}
```

**Acceptance Criteria**:
- [ ] Create `test/integration/` directory
- [ ] Add full pipeline test (YAML → Code → Runtime)
- [ ] Add validation failure test
- [ ] Add compile check (dart analyze on generated code)
- [ ] Add runtime execution test
- [ ] Run in CI alongside unit tests
- [ ] Target: 5-10 integration tests covering critical paths

---

## 🟠 HIGH PRIORITY (P1) - Should Fix Soon

### 4. Configuration API Refactoring - Reduce Complexity
**Location**: `lib/src/config/analytics_config.dart`

**Problem**:
15 constructor parameters make API hard to use:

```dart
final config = AnalyticsConfig(
  outputPath: 'lib/analytics',
  eventPaths: ['events/*.yaml'],
  contextPaths: [],
  sharedParameterPaths: [],
  imports: [],
  naming: NamingStrategy.snakeCase(),
  generateDocs: false,
  generateExports: false,
  generateTestMatchers: false,
  strictEventNames: true,
  enforceCentrallyDefinedParameters: false,
  preventEventParameterDuplicates: false,
  template: '{domain}: {event}',
  casing: 'snake_case',
  planFingerprint: '',
);
```

**Impact**:
- Poor developer experience
- Hard to add new config options
- Constructor changes break all call sites

**Solution Option A - Builder Pattern**:
```dart
final config = AnalyticsConfig.builder()
  .outputPath('lib/analytics')
  .eventPaths(['events/*.yaml'])
  .naming(NamingStrategy.snakeCase())
  .enableDocs()
  .enableExports()
  .build();

// With validation
class AnalyticsConfigBuilder {
  String? _outputPath;
  List<String>? _eventPaths;
  // ...

  AnalyticsConfig build() {
    if (_outputPath == null) {
      throw StateError('outputPath is required');
    }
    return AnalyticsConfig._internal(...);
  }
}
```

**Solution Option B - Grouped Configuration**:
```dart
class AnalyticsConfig {
  final InputConfig input;
  final OutputConfig output;
  final ValidationConfig validation;
  final NamingConfig naming;
}

final config = AnalyticsConfig(
  input: InputConfig(
    eventPaths: ['events/*.yaml'],
    contextPaths: [],
    sharedParameterPaths: [],
    imports: [],
  ),
  output: OutputConfig(
    path: 'lib/analytics',
    generateDocs: true,
    generateExports: false,
    generateTestMatchers: false,
  ),
  validation: ValidationConfig(
    strictEventNames: true,
    enforceCentrallyDefinedParameters: false,
    preventEventParameterDuplicates: false,
  ),
  naming: NamingConfig(
    strategy: NamingStrategy.snakeCase(),
    template: '{domain}: {event}',
    casing: 'snake_case',
  ),
);
```

**Acceptance Criteria**:
- [ ] Choose approach (Builder or Grouped)
- [ ] Implement new API
- [ ] Keep old constructor @Deprecated for migration
- [ ] Update documentation
- [ ] Migrate example/ to new API
- [ ] Add migration guide to MIGRATION_GUIDES.md

---

### 5. PII Metadata Enforcement - Add Runtime Warnings
**Location**: `lib/src/generator/renderers/event_renderer.dart`

**Problem**:
Schema supports PII metadata but generator ignores it:

```yaml
user_id:
  type: string
  meta:
    pii: true  # ✅ Parsed, ❌ Not used
```

**Impact**:
- No compliance warnings in generated code
- Developers don't know which parameters contain PII
- GDPR/CCPA violations risk

**Solution**:
```dart
// In EventRenderer._renderEventMethod()
for (final param in event.parameters) {
  if (param.meta['pii'] == true) {
    buffer.writeln('    // ⚠️ WARNING: "${param.name}" contains PII');
    buffer.writeln('    // Ensure compliance with GDPR/CCPA before logging');
  }
}

// Also add to docs
/// Logs authentication login event.
///
/// ⚠️ **PII WARNING**: This event contains personally identifiable information:
/// - `user_id`: User identifier (PII)
/// - `email`: Email address (PII)
///
/// Ensure your analytics provider is GDPR/CCPA compliant.
void logAuthLogin({...}) { ... }
```

**Bonus**: Add lint rule option
```yaml
analytics_gen:
  rules:
    block_pii_logging: true  # Throw error if PII detected
```

**Acceptance Criteria**:
- [ ] Add PII warnings to generated method docs
- [ ] Add inline comments for PII parameters
- [ ] Add optional `block_pii_logging` rule
- [ ] Update validation tests
- [ ] Document PII handling in doc/SECURITY.md

---

### 6. Add Observability Metrics - Track Generation Performance
**Location**: `lib/src/generator/code_generator.dart`, `lib/src/pipeline/`

**Problem**:
No insights into generation performance:
- How long does parsing take?
- Which domains are slowest to generate?
- Is generation getting slower over time?

**Solution**:
```dart
abstract class Metrics {
  void recordParsing(Duration elapsed, int domainCount, int eventCount);
  void recordGeneration(Duration elapsed, int fileCount);
  void recordValidation(Duration elapsed, int errorCount);
}

class CodeGenerator {
  final Metrics? metrics;

  Future<void> generate(Map<String, AnalyticsDomain> domains) async {
    final sw = Stopwatch()..start();

    // ... generation logic

    metrics?.recordGeneration(
      sw.elapsed,
      domains.length,
      totalEvents: domains.values.fold(0, (sum, d) => sum + d.events.length),
    );
  }
}

// Console implementation
class ConsoleMetrics implements Metrics {
  @override
  void recordGeneration(Duration elapsed, int fileCount) {
    print('[Metrics] Generated $fileCount files in ${elapsed.inMilliseconds}ms');
    if (elapsed.inSeconds > 5) {
      print('[Metrics] ⚠️ Slow generation detected');
    }
  }
}

// Optional: Export to JSON for CI tracking
class JsonMetrics implements Metrics {
  final File output;
  final List<Map<String, dynamic>> _entries = [];

  @override
  void recordGeneration(Duration elapsed, int fileCount) {
    _entries.add({
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'generation',
      'duration_ms': elapsed.inMilliseconds,
      'file_count': fileCount,
    });
  }

  Future<void> flush() async {
    await output.writeAsString(jsonEncode(_entries));
  }
}
```

**Acceptance Criteria**:
- [ ] Add Metrics interface
- [ ] Instrument CodeGenerator, DomainParser, SchemaValidator
- [ ] Add ConsoleMetrics implementation
- [ ] Add optional JsonMetrics for CI tracking
- [ ] Add `--metrics` flag to CLI
- [ ] Track metrics over time in CI (optional)

---

## 🟡 MEDIUM PRIORITY (P2) - Nice to Have

### 7. Renderer Decomposition - Split EventRenderer
**Location**: `lib/src/generator/renderers/event_renderer.dart:40-107`

**Problem**:
`EventRenderer.renderDomainMixin()` does 4 things:
- Collects regex patterns
- Generates mixin declaration
- Generates cached RegExp fields
- Generates event methods

**Solution**:
```dart
// Split into focused sub-renderers
class EventRenderer {
  final RegexCacheRenderer regexRenderer;
  final MixinDeclarationRenderer mixinRenderer;
  final EventMethodRenderer methodRenderer;

  String renderDomainMixin(...) {
    final buffer = StringBuffer();

    buffer.write(mixinRenderer.renderDeclaration(domainName));
    buffer.write(regexRenderer.renderCachedPatterns(domain));

    for (final event in domain.events) {
      buffer.write(methodRenderer.renderMethod(event));
    }

    buffer.write(mixinRenderer.renderClosing());
    return buffer.toString();
  }
}
```

**Acceptance Criteria**:
- [ ] Split EventRenderer into 3-4 sub-renderers
- [ ] Each renderer <100 lines
- [ ] Add unit tests for each
- [ ] No changes to generated output

---

### 8. Consistent Interface Declaration - Standardize Syntax
**Location**: `lib/src/core/*.dart`

**Problem**:
Mixed interface declarations:
```dart
abstract interface class IAnalytics {}
abstract interface class AnalyticsCapabilityResolver {}
abstract class AnalyticsBase {}  // Why not interface?
```

**Solution**:
Pick one style and document reasoning:

**Option A**: Use `abstract interface class` everywhere
```dart
abstract interface class IAnalytics {}
abstract interface class AnalyticsBase {}
```

**Option B**: Use `abstract class` everywhere (simpler)
```dart
abstract class IAnalytics {}
abstract class AnalyticsBase {}
```

**Rationale**: In Dart 3, `interface` prevents external implementations. Only use if you need that guarantee. For internal libraries, `abstract class` is clearer.

**Acceptance Criteria**:
- [ ] Audit all interface declarations
- [ ] Standardize on one approach
- [ ] Document decision in CONTRIBUTING.md
- [ ] Add lint rule to enforce consistency

---

### 9. Dead Event Audit - Enhanced Reporting
**Location**: `bin/audit.dart`

**Current State**: Basic dead event detection

**Enhancement Ideas**:
- [ ] Show last commit that added the event
- [ ] Show when event was last used (git blame)
- [ ] Generate removal PR automatically
- [ ] Flag events with <10 usages in last 30 days
- [ ] Export to CSV for PM review

```dart
class DeadEventReport {
  final String eventName;
  final String definedIn;
  final int usageCount;
  final DateTime? lastUsed;  // From git log
  final String? addedBy;     // From git blame
  final Duration age;        // Time since added

  bool get shouldRemove => usageCount == 0 && age > Duration(days: 90);
}
```

---

### 10. Documentation Improvements

**Add Missing Docs**:
- [ ] `doc/SECURITY.md` - PII handling, GDPR compliance
- [ ] `doc/PERFORMANCE.md` - Benchmarks, optimization tips
- [ ] `doc/TESTING.md` - How to test analytics integrations
- [ ] `doc/TROUBLESHOOTING.md` - Common errors and fixes

**Improve Existing Docs**:
- [ ] Add mermaid diagrams to README (architecture, data flow)
- [ ] Add video walkthrough (5min quick start)
- [ ] Add comparison table (vs Segment, vs Amplitude SDK)

---

## ✅ STRENGTHS (Keep Doing)

### What's Already Excellent
1. ✅ **Clean Architecture** - Layered design with zero circular deps
2. ✅ **SOLID Principles** - 95% compliance, deliberate trade-offs
3. ✅ **Immutability** - 100% immutable models with value equality
4. ✅ **Error Handling** - Source spans, sealed exceptions, rich context
5. ✅ **Capability Pattern** - Custom heterogeneous container (elegant)
6. ✅ **Multi-Provider Resilience** - Expected vs unexpected error handling
7. ✅ **Analytics Best Practices** - High cardinality prevention, schema evolution
8. ✅ **Test Coverage** - 200+ unit tests, 80%+ coverage
9. ✅ **Documentation** - Comprehensive README, migration guides
10. ✅ **Type Safety** - Sealed classes, enums for allowed values

**Do not change these** - they're industry-leading.

---

## 📊 Progress Tracking

### Critical (P0)
- [ ] 1. Refactor God Objects
- [ ] 2. Fix Type Casting Safety
- [ ] 3. Add Integration Tests

### High Priority (P1)
- [ ] 4. Configuration API Refactoring
- [ ] 5. PII Metadata Enforcement
- [ ] 6. Add Observability Metrics

### Medium Priority (P2)
- [ ] 7. Renderer Decomposition
- [ ] 8. Consistent Interface Declaration
- [ ] 9. Dead Event Audit Enhancement
- [ ] 10. Documentation Improvements

---

## 🎯 Recommended Implementation Order

**Sprint 1 (Week 1-2)**: Critical Fixes
1. Fix type casting (2 days) - Quick win, high safety impact
2. Add integration tests (3 days) - Prevents regressions
3. Start God Object refactoring (5 days) - Biggest architectural debt

**Sprint 2 (Week 3-4)**: High Priority
4. Configuration API (3 days) - Improves DX
5. PII warnings (2 days) - Compliance requirement
6. Metrics (2 days) - Observability for scaling

**Sprint 3 (Week 5+)**: Polish
7-10. Medium priority items as time allows

---

## 📝 Notes

- All tasks maintain backward compatibility unless explicitly marked as breaking
- Test coverage must not drop below 80% during refactoring
- Generated code output must remain deterministic (git diff clean)
- Performance must not regress (benchmark before/after)

**Last Updated**: 2025-12-17
**Next Review**: After P0 tasks completed
