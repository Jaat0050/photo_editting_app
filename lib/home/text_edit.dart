import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TextEditDialog extends StatefulWidget {
  final double initialFontSize;
  final Color initialColor;
  final String initialText;
  final TextAlign initialTextAlign;
  final FontWeight initialFontWeight;
  final String initialFontFamily;
  final double initialLineHeight;
  final List<bool> initialAlignmentSelections;
  final Function(
    String,
    double,
    Color,
    TextAlign,
    FontWeight,
    double,
    String,
  ) onSubmitted;

  const TextEditDialog({
    Key? key,
    required this.initialFontSize,
    required this.initialColor,
    required this.initialText,
    required this.initialTextAlign,
    required this.initialFontWeight,
    required this.initialFontFamily,
    required this.initialAlignmentSelections,
    required this.initialLineHeight,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<TextEditDialog> {
  late double fontSize;
  late Color color;
  late String text;
  late TextAlign textAlign;
  late FontWeight fontWeight;
  late String fontFamily;
  late List<bool> alignmentSelections;
  late TextEditingController textController;

  List<double> fontSizes = [12, 14, 16, 18, 20, 24, 28, 32, 36, 40];

  late double _lineHeight;
  List<double> lineHeightOptions = [1.0, 1.5, 2.0, 2.5, 3.0];

  // Add more font families as needed
  List<String> fontFamilies = ['Roboto', 'Lora', 'Charm'];

  // Add font weights if needed
  List<FontWeight> fontWeights = [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ];
  String _selectedTextAlign = 'Left'; // Default to left alignment

  Map<String, TextAlign> textAlignOptions = {
    'L': TextAlign.left,
    'C': TextAlign.center,
    'R': TextAlign.right,
  };

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: color,
              onColorChanged: (Color newColor) {
                // Update the color locally within this dialog
                color = newColor;
              },
              // ignore: deprecated_member_use
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                // When the 'Got it' button is pressed, update the color in the TextEditDialog state.
                setState(() {
                  color = color; // Update the color in the main dialog's state
                });
                Navigator.of(context).pop(); // Close the color picker dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fontSize = widget.initialFontSize;
    color = widget.initialColor;
    text = widget.initialText;
    textAlign = widget.initialTextAlign;
    fontWeight = widget.initialFontWeight;
    fontFamily = widget.initialFontFamily;
    alignmentSelections = List.from(widget.initialAlignmentSelections);
    textController = TextEditingController(text: text);
    _lineHeight = widget.initialLineHeight;
    textAlign = widget.initialTextAlign;
    _selectedTextAlign = textAlignOptions.entries
        .firstWhere((entry) => entry.value == textAlign,
            orElse: () => const MapEntry('Left', TextAlign.left))
        .key;
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(left: 10, right: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextField(
                  maxLines: 3,
                  controller: textController,
                  decoration: const InputDecoration(
                    focusedBorder: InputBorder.none,
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    text = value;
                  },
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              //------------------------------------------------------------------------------//
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //--------------------------------------------------------------------------------//
                  Container(
                    width: 130,
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: fontFamily, // Use the state variable
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        setState(() {
                          fontFamily = newValue!; // Update the state variable
                        });
                      },
                      items: fontFamilies
                          .map<DropdownMenuItem<String>>((String family) {
                        return DropdownMenuItem<String>(
                          value: family,
                          child: Text(family),
                        );
                      }).toList(),
                    ),
                  ),
                  //------------------------------------------------------------------------------//
                  Container(
                    width: 130,
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: DropdownButton<FontWeight>(
                      isExpanded: true,
                      value: fontWeight,
                      underline: const SizedBox(),
                      onChanged: (FontWeight? newValue) {
                        setState(() {
                          fontWeight = newValue!;
                        });
                      },
                      items: fontWeights.map<DropdownMenuItem<FontWeight>>(
                          (FontWeight weight) {
                        return DropdownMenuItem<FontWeight>(
                          value: weight,
                          child: Text(
                            weight.toString().split('.').last,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              //-------------------------------------------------------------------------------------//
              const SizedBox(
                height: 15,
              ),
              Container(
                height: 70,
                padding: const EdgeInsets.only(left: 10, right: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //--------------------------------------------------------------------------//
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 55,
                          height: 30,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: DropdownButton<double>(
                            isExpanded: true,
                            value: fontSize,
                            iconSize: 15,
                            underline: const SizedBox(),
                            onChanged: (double? newValue) {
                              setState(() {
                                fontSize = newValue!;
                              });
                            },
                            items: fontSizes
                                .map<DropdownMenuItem<double>>((double size) {
                              return DropdownMenuItem<double>(
                                value: size,
                                child: Text(
                                  size.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Text(
                          'Font Size',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    //----------------------------------------------------------------------------------------------//
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ElevatedButton(
                            onPressed: _openColorPicker,
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(color)),
                            child: Text(
                              '',
                              style: TextStyle(
                                  fontSize: 1,
                                  color: useWhiteForeground(color)
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          ),
                        ),
                        const Text(
                          'Color',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    //---------------------------------------------------------------------------------//
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 55,
                            height: 30,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: DropdownButton<double>(
                              iconSize: 15,
                              isExpanded: true,
                              value: _lineHeight,
                              underline: const SizedBox(),
                              onChanged: (double? newValue) {
                                setState(() {
                                  _lineHeight = newValue!;
                                });
                              },
                              items: lineHeightOptions
                                  .map<DropdownMenuItem<double>>(
                                      (double value) {
                                return DropdownMenuItem<double>(
                                  value: value,
                                  child: Text(
                                    value.toString(),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                            )),
                        const Text(
                          'Line Height',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    //------------------------------------------------------------------------------//
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 55,
                            height: 30,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedTextAlign,
                              iconSize: 15,
                              isExpanded: true,
                              underline: const SizedBox(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedTextAlign = newValue!;
                                  textAlign =
                                      textAlignOptions[_selectedTextAlign]!;
                                });
                              },
                              items: textAlignOptions.keys
                                  .map<DropdownMenuItem<String>>((String key) {
                                return DropdownMenuItem<String>(
                                  value: key,
                                  child: Text(
                                    key,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                            )),
                        const Text(
                          'Alignment',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Done'),
          onPressed: () {
            widget.onSubmitted(
              text,
              fontSize,
              color,
              textAlign,
              fontWeight,
              _lineHeight,
              fontFamily,
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
