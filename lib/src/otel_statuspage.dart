// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_statuspage_suppression.dart';

const _tracerName = 'dartastic_otel_libs_statuspage';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class StatuspageResult {
  const StatuspageResult({
    this.pageId,
    this.entityKind,
    this.entityId,
    this.action,
    this.componentName,
    this.componentStatus,
    this.componentGroupId,
    this.incidentName,
    this.incidentStatus,
    this.incidentImpact,
    this.scheduledFor,
    this.affectedComponentCount,
    this.subscriberKind,
    this.subscriberCount,
    this.metricId,
    this.metricDataPointCount,
    this.errorMessage,
    this.statusCode,
  });

  /// Statuspage page id.
  final String? pageId;

  /// `component`, `component_group`, `incident`, `incident_update`,
  /// `incident_template`, `scheduled_maintenance`, `subscriber`,
  /// `metric`, `metric_provider`, `page`.
  final String? entityKind;

  final String? entityId;

  /// `create`, `update`, `delete`, `list`, `get`, `resolve`,
  /// `postmortem`.
  final String? action;

  // ── Component ──────────────────────────────────────────────────
  final String? componentName;

  /// `operational`, `degraded_performance`, `partial_outage`,
  /// `major_outage`, `under_maintenance`.
  final String? componentStatus;
  final String? componentGroupId;

  // ── Incident ───────────────────────────────────────────────────
  final String? incidentName;

  /// `investigating`, `identified`, `monitoring`, `resolved`,
  /// `scheduled`, `in_progress`, `verifying`, `completed`.
  final String? incidentStatus;

  /// `none`, `minor`, `major`, `critical`, `maintenance`.
  final String? incidentImpact;

  /// ISO timestamp for scheduled maintenance.
  final String? scheduledFor;

  final int? affectedComponentCount;

  // ── Subscriber ─────────────────────────────────────────────────
  /// `email`, `sms`, `webhook`, `slack`, `teams`.
  final String? subscriberKind;
  final int? subscriberCount;

  /// Metric data point batch upload.
  final String? metricId;
  final int? metricDataPointCount;

  final String? errorMessage;
  final int? statusCode;
}

class StatuspageCallResult<T> {
  const StatuspageCallResult({required this.value, this.result});
  final T value;
  final StatuspageResult? result;
}

/// Wraps a Statuspage API call in a CLIENT span. [operation] is one of
/// `pages.list`, `pages.get`, `pages.update`,
/// `components.list`, `components.create`, `components.update`,
/// `components.delete`, `componentGroups.list`, `componentGroups.create`,
/// `componentGroups.update`, `componentGroups.delete`,
/// `incidents.list`, `incidents.create`, `incidents.update`,
/// `incidents.delete`, `incidents.postmortem.create`,
/// `incidentUpdates.list`, `incidentUpdates.create`,
/// `scheduledMaintenances.list`, `scheduledMaintenances.create`,
/// `scheduledMaintenances.update`, `subscribers.list`,
/// `subscribers.create`, `subscribers.delete`, `subscribers.resend`,
/// `metrics.list`, `metrics.create`, `metrics.dataPoint.create`,
/// `metricsProviders.list`.
Future<T> tracedStatuspage<T>({
  required String operation,
  required Future<StatuspageCallResult<T>> Function() invoke,
}) async {
  if (statuspageInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'statuspage',
    'rpc.method': operation,
    'statuspage.operation': operation,
  };

  final span = _tracer().startSpan(
    'statuspage $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.pageId != null) {
        extras.add(OTel.attributeString('statuspage.page.id', res.pageId!));
      }
      if (res.entityKind != null) {
        extras.add(OTel.attributeString(
          'statuspage.entity.kind',
          res.entityKind!,
        ));
      }
      if (res.entityId != null) {
        extras.add(OTel.attributeString(
          'statuspage.entity.id',
          res.entityId!,
        ));
      }
      if (res.action != null) {
        extras.add(OTel.attributeString('statuspage.action', res.action!));
      }
      if (res.componentName != null) {
        extras.add(OTel.attributeString(
          'statuspage.component.name',
          res.componentName!,
        ));
      }
      if (res.componentStatus != null) {
        extras.add(OTel.attributeString(
          'statuspage.component.status',
          res.componentStatus!,
        ));
        if (res.componentStatus == 'major_outage') {
          span.setStatus(
            SpanStatusCode.Error,
            'Component major_outage',
          );
        }
      }
      if (res.componentGroupId != null) {
        extras.add(OTel.attributeString(
          'statuspage.component_group.id',
          res.componentGroupId!,
        ));
      }
      if (res.incidentName != null) {
        extras.add(OTel.attributeString(
          'statuspage.incident.name',
          res.incidentName!,
        ));
      }
      if (res.incidentStatus != null) {
        extras.add(OTel.attributeString(
          'statuspage.incident.status',
          res.incidentStatus!,
        ));
      }
      if (res.incidentImpact != null) {
        extras.add(OTel.attributeString(
          'statuspage.incident.impact',
          res.incidentImpact!,
        ));
        if (res.incidentImpact == 'critical') {
          span.setStatus(
            SpanStatusCode.Error,
            'Incident impact critical',
          );
        }
      }
      if (res.scheduledFor != null) {
        extras.add(OTel.attributeString(
          'statuspage.scheduled_for',
          res.scheduledFor!,
        ));
      }
      if (res.affectedComponentCount != null) {
        extras.add(OTel.attributeInt(
          'statuspage.incident.affected_component_count',
          res.affectedComponentCount!,
        ));
      }
      if (res.subscriberKind != null) {
        extras.add(OTel.attributeString(
          'statuspage.subscriber.kind',
          res.subscriberKind!,
        ));
      }
      if (res.subscriberCount != null) {
        extras.add(OTel.attributeInt(
          'statuspage.subscriber.count',
          res.subscriberCount!,
        ));
      }
      if (res.metricId != null) {
        extras.add(OTel.attributeString(
          'statuspage.metric.id',
          res.metricId!,
        ));
      }
      if (res.metricDataPointCount != null) {
        extras.add(OTel.attributeInt(
          'statuspage.metric.data_point_count',
          res.metricDataPointCount!,
        ));
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'statuspage.error.message',
          res.errorMessage!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Statuspage HTTP ${res.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
