// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_statuspage/otel_statuspage.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_statuspage-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('components.update records status', () async {
    await tracedStatuspage<String>(
      operation: 'components.update',
      invoke: () async => const StatuspageCallResult(
        value: 'ok',
        result: StatuspageResult(
          pageId: 'p_1',
          entityKind: 'component',
          entityId: 'c_1',
          action: 'update',
          componentName: 'API',
          componentStatus: 'degraded_performance',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('statuspage components.update')!);
    expect(a['statuspage.component.status'], 'degraded_performance');
  });

  test('major_outage component sets span error', () async {
    await tracedStatuspage<String>(
      operation: 'components.update',
      invoke: () async => const StatuspageCallResult(
        value: 'ok',
        result: StatuspageResult(componentStatus: 'major_outage'),
      ),
    );
    expect(
      spans.findSpanByName('statuspage components.update')!.status,
      SpanStatusCode.Error,
    );
  });

  test('critical incident impact sets span error', () async {
    await tracedStatuspage<String>(
      operation: 'incidents.create',
      invoke: () async => const StatuspageCallResult(
        value: 'ok',
        result: StatuspageResult(
          incidentName: 'API down',
          incidentStatus: 'investigating',
          incidentImpact: 'critical',
          affectedComponentCount: 3,
        ),
      ),
    );
    final s = spans.findSpanByName('statuspage incidents.create')!;
    expect(s.status, SpanStatusCode.Error);
    expect(attrsOf(s)['statuspage.incident.affected_component_count'], 3);
  });

  test('resolved incident is non-error', () async {
    await tracedStatuspage<String>(
      operation: 'incidents.update',
      invoke: () async => const StatuspageCallResult(
        value: 'ok',
        result: StatuspageResult(
          incidentStatus: 'resolved',
          incidentImpact: 'minor',
        ),
      ),
    );
    expect(
      spans.findSpanByName('statuspage incidents.update')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutStatuspageInstrumentationAsync(() async {
      await tracedStatuspage<String>(
        operation: 'pages.list',
        invoke: () async => const StatuspageCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('statuspage '), isEmpty);
  });
}
