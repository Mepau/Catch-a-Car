import 'package:flutter/material.dart';

import 'GridPicker.dart';

typedef void ListOptionsCallback(List<String> val);

class OptionsPicker extends StatefulWidget {
  final ListOptionsCallback callback;
  final List<String> options;
  final String optionTitle;
  const OptionsPicker(
      {super.key,
      required this.callback,
      required this.optionTitle,
      required this.options});

  @override
  _OptionsPickerState createState() => _OptionsPickerState(
      callback: callback, optionTitle: optionTitle, options: options);
}

class _OptionsPickerState extends State<OptionsPicker> {
  final ListOptionsCallback callback;
  final String optionTitle;
  final List<String> options;
  _OptionsPickerState(
      {required this.callback,
      required this.optionTitle,
      required this.options});

  List<String> _selectedOptions = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        child: StatefulBuilder(
          builder: (context, setOuterState) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.blue[100],
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue[50],
                      onPrimary: Colors.grey[900],
                      textStyle: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setInnerState) {
                              return Column(
                                children: <Widget>[
                                  Text("Selected ${optionTitle}:"),
                                  SizedBox(
                                    height: 60,
                                    child: GridPicker(
                                      options: _selectedOptions,
                                      addCallback: (val) =>
                                          setInnerState(() => {}),
                                      removeCallback: (val) {
                                        setInnerState(
                                            () => _selectedOptions.remove(val));
                                        callback(_selectedOptions);
                                      },
                                      refreshOuterState: () =>
                                          setOuterState(() => {}),
                                      selectedOptions: _selectedOptions,
                                    ),
                                  ),
                                  Text("${optionTitle}:"),
                                  Expanded(
                                    child: GridPicker(
                                      options: options!,
                                      addCallback: (val) {
                                        setInnerState(
                                            () => _selectedOptions.add(val));
                                        callback(_selectedOptions);
                                      },
                                      removeCallback: (val) {
                                        setInnerState(
                                            () => _selectedOptions.remove(val));
                                        callback(_selectedOptions);
                                      },
                                      refreshOuterState: () =>
                                          setOuterState(() => {}),
                                      selectedOptions: _selectedOptions,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Text(
                      'Filter by ${optionTitle}',
                      style: TextStyle(
                          color: Colors.grey[900],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6),
                    ),
                  ),
                ),
                Container(
                  height: 100,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 100,
                              childAspectRatio: 4 / 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10),
                      itemCount: _selectedOptions.length,
                      itemBuilder: (BuildContext ctx, index) {
                        return Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(15)),
                          child: Text(_selectedOptions[index]),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ));
  }
}
