import 'dart:async';
import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final String name = context.vars['name'];
  final String description = context.vars['description'];
  final String cms = context.vars['cms'];
  final appName = name.snakeCase;

  await _trackOperation(
    context,
    startMessage: 'Setting up the Flutter project @ apps/$appName',
    endMessage: 'Flutter project ready @ apps/$appName',
    operation: () async {
      await Process.run(
        'flutter',
        [
          'create',
          '${name.snakeCase}',
          '--template=app',
          '--platforms=ios,android,web',
          '--description=$description',
        ],
        workingDirectory: '$appName/apps',
      );

      await Process.run(
        'flutter',
        [
          'pub',
          'add',
          ...'sanity_client vyuh_core vyuh_extension_content vyuh_feature_system vyuh_feature_developer mobx flutter_mobx'
              .split(' '),
        ],
        workingDirectory: '$appName/apps/${name.snakeCase}',
      );
    },
  );

  await _trackOperation(
    context,
    startMessage: 'Running `melos bootstrap` on apps/$appName',
    endMessage: 'Melos bootstrap complete for apps/$appName',
    operation: () async {
      await Process.run(
        'melos',
        ['bootstrap'],
        workingDirectory: appName,
      );
    },
  );

  if (cms == 'sanity') {
    final studioName = '${name.paramCase}-studio';

    await _trackOperation(
      context,
      startMessage: 'Setting up the Sanity project @ apps/$studioName',
      endMessage: 'Sanity project ready @ apps/$studioName',
      operation: () async {
        await Process.run(
          'pnpm',
          [
            'create',
            'sanity@latest',
            '--yes',
            '--dataset',
            'production',
            '--template',
            'clean',
            '--visibility',
            'public',
            '--create-project',
            '$studioName',
            '--output-path',
            '$studioName',
          ],
          workingDirectory: '$appName/apps',
        );

        await Process.run(
          'pnpm',
          [
            'add',
            ...('@vyuh/sanity-schema-core @vyuh/sanity-schema-system'
                .split(' ')),
          ],
          workingDirectory: '$appName/apps/$studioName',
        );
      },
    );
  }
}

Future<void> _trackOperation(
  HookContext context, {
  required String startMessage,
  required String endMessage,
  required Future<void> Function() operation,
}) async {
  final progress = context.logger.progress(startMessage);

  await operation();

  progress.complete(endMessage);
}
