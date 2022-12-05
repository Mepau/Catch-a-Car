import "package:flutter/material.dart";

typedef void AddCallback(val);
typedef void RemoveCallback(val);
typedef void RefreshOuterState();

class GridPicker extends StatelessWidget {
  final AddCallback addCallback;
  final RemoveCallback removeCallback;
  final RefreshOuterState refreshOuterState;

  final List<dynamic> options;
  final List<dynamic> selectedOptions;

  const GridPicker({
    Key? key,
    required this.options,
    required this.addCallback,
    required this.removeCallback,
    required this.refreshOuterState,
    required this.selectedOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 100,
          childAspectRatio: 4 / 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10),
      itemCount: options.length,
      itemBuilder: (BuildContext ctx, index) {
        return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: selectedOptions.contains(options[index])
                    ? Colors.blue[200]
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(15)),
            child: SizedBox(
              width: double.infinity, // <-- match_parent
              height: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.greenAccent,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  minimumSize: Size(100, 40), //////// HERE
                ),
                onPressed: () {
                  if (!selectedOptions.contains(options[index])) {
                    addCallback(options[index]);
                  } else {
                    removeCallback(options[index]);
                  }
                  refreshOuterState();
                },
                child: Text(options[index]),
              ),
            ));
      },
    );
  }
}
