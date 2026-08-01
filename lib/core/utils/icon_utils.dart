import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconUtils {
  static Widget buildIcon(dynamic iconData, {Color? color, double? size}) {
    if (iconData is FaIconData) {
      return FaIcon(iconData, color: color, size: size);
    }
    if (iconData is IconData) {
      return Icon(iconData, color: color, size: size);
    }
    return Icon(Icons.help_outline, color: color, size: size);
  }
}
