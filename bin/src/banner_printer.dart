void printBanner(String title) {
  const border = '╔════════════════════════════════════════════════╗';
  const footer = '╚════════════════════════════════════════════════╝';
  const interiorWidth = 48;
  const leftIndent = 3;

  final trimmedTitle = title.length > (interiorWidth - leftIndent)
      ? title.substring(0, interiorWidth - leftIndent)
      : title;
  final trailingSpaces = interiorWidth - leftIndent - trimmedTitle.length;
  final spacing = ' ' * trailingSpaces;

  print(border);
  print('║   $trimmedTitle$spacing║');
  print(footer);
}
