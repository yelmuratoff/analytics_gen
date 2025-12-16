import 'package:analytics_gen/src/config/parser_config.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:analytics_gen/src/util/logger.dart';

/// Factory for creating [EventLoader] instances.
abstract interface class EventLoaderFactory {
  /// Creates a new [EventLoader].
  EventLoader create({
    required String eventsPath,
    List<String> contextFiles = const [],
    List<String> sharedParameterFiles = const [],
    Logger log = const NoOpLogger(),
  });
}

/// Default implementation of [EventLoaderFactory].
class DefaultEventLoaderFactory implements EventLoaderFactory {
  /// Constant constructor.
  const DefaultEventLoaderFactory();

  @override
  EventLoader create({
    required String eventsPath,
    List<String> contextFiles = const [],
    List<String> sharedParameterFiles = const [],
    Logger log = const NoOpLogger(),
  }) {
    return EventLoader(
      eventsPath: eventsPath,
      contextFiles: contextFiles,
      sharedParameterFiles: sharedParameterFiles,
      log: log,
    );
  }
}

/// Factory for creating [YamlParser] instances.
abstract interface class YamlParserFactory {
  /// Creates a new [YamlParser].
  YamlParser create({
    Logger log = const NoOpLogger(),
    ParserConfig config = const ParserConfig(),
  });
}

/// Default implementation of [YamlParserFactory].
class DefaultYamlParserFactory implements YamlParserFactory {
  /// Constant constructor.
  const DefaultYamlParserFactory();

  @override
  YamlParser create({
    Logger log = const NoOpLogger(),
    ParserConfig config = const ParserConfig(),
  }) {
    return YamlParser(
      log: log,
      config: config,
    );
  }
}
