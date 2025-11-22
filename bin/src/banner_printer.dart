import 'package:analytics_gen/src/util/logger.dart';

void printBanner(String title, {Logger? logger}) {
  final log = logger ?? const ConsoleLogger();
  const border = '╔════════════════════════════════════════════════╗';
  const footer = '╚════════════════════════════════════════════════╝';
  const interiorWidth = 48;
  const leftIndent = 3;

  final trimmedTitle = title.length > (interiorWidth - leftIndent)
      ? title.substring(0, interiorWidth - leftIndent)
      : title;
  final trailingSpaces = interiorWidth - leftIndent - trimmedTitle.length;
  final spacing = ' ' * trailingSpaces;

  log.info(border);
  log.info('║   $trimmedTitle$spacing║');
  log.info(footer);
}
