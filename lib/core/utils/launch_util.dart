import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/common.dart';

/// Opens an external link (tel:, mailto:, https:, WhatsApp) and tells the
/// vendor when the device has nothing that can handle it, instead of the tap
/// silently doing nothing.
Future<void> openExternal(BuildContext context, Uri uri, {String? failMessage}) async {
  final m = Toast.of(context);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) Toast.error(m, failMessage ?? 'Could not open ${uri.scheme == 'mailto' ? 'your email app' : 'that link'}.');
  } catch (_) {
    Toast.error(m, failMessage ?? 'Could not open ${uri.scheme == 'mailto' ? 'your email app' : 'that link'}.');
  }
}

Uri telUri(String phone) => Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));

Uri mailUri(String email, {String subject = '', String body = ''}) => Uri(
      scheme: 'mailto',
      path: email,
      query: [
        if (subject.isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
        if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
      ].join('&'),
    );

/// wa.me needs the number in international form without "+"; a bare
/// 10-digit Indian number gets the 91 country code.
Uri whatsappUri(String phone, {String text = ''}) {
  var d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.length == 10) d = '91$d';
  return Uri.parse('https://wa.me/$d${text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}'}');
}

Future<void> copyToClipboard(BuildContext context, String text, {String label = 'Copied'}) async {
  final m = Toast.of(context);
  await Clipboard.setData(ClipboardData(text: text));
  Toast.ok(m, label);
}
