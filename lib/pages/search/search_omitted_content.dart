import 'package:anime_flow/models/item/search_item.dart';
import 'package:anime_flow/widget/image/animation_network_image.dart';
import 'package:flutter/cupertino.dart';

///简洁View
class SearchOmittedContent extends StatelessWidget {
  final SearchData searchData;
  final double itemHeight;

  const SearchOmittedContent({
    super.key,
    required this.searchData, required this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      width: 110,
      child: Stack(children: [
        Positioned.fill(
          child: AnimationNetworkImage(
            url: searchData.images.large,
            fit: BoxFit.cover,
          ),
        ),
      ]),
    );
  }
}
