import 'package:flutter/material.dart';

class TextData {
  Offset position;
  String text;
  double fontSize;
  Color color;
  TextAlign textAlign;
  FontWeight fontWeight;
  String fontFamily;
  List<bool> alignmentSelections;
  double lineHeight;
  String? imageUrl;

  TextData({
    required this.position,
    required this.text,
    required this.fontSize,
    required this.color,
    required this.textAlign,
    required this.fontWeight,
    required this.fontFamily,
    required this.alignmentSelections,
    required this.lineHeight,
    this.imageUrl,
  });

  factory TextData.fromJson(Map<String, dynamic> json) {
    return TextData(
      position: Offset(json['dx'], json['dy']),
      text: json['text'],
      fontSize: json['fontSize'],
      color: Color(json['color']),
      textAlign: TextAlign.values[json['textAlign']],
      fontWeight: FontWeight.values[json['fontWeight']],
      fontFamily: json['fontFamily'],
      alignmentSelections: List<bool>.from(json['alignmentSelections']),
      lineHeight: json['lineHeight'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dx': position.dx,
      'dy': position.dy,
      'text': text,
      'fontSize': fontSize,
      'color': color.value,
      'textAlign': textAlign.index,
      'fontWeight': fontWeight.index,
      'fontFamily': fontFamily,
      'alignmentSelections': alignmentSelections,
      'lineHeight': lineHeight,
      'imageUrl': imageUrl,
    };
  }
}
