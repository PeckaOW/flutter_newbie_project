import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class StarRating extends HookWidget {
  StarRating({super.key, required this.userID});

  final String userID;

  @override
  Widget build(BuildContext context) {
    final rating = useState(0);

    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop()),
            centerTitle: true,
            title: Text('Please rate $userID')),
        body: Center(
            child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < rating.value ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 50.0,
              ),
              onPressed: () {
                rating.value = index + 1;
                final snackBar = SnackBar(
                    content: Text(
                        'You have given $userID ${rating.value} star(s).'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
            );
          }),
        )));
  }
}
