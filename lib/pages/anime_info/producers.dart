import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/staff_item.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ProducersView extends StatefulWidget {
  final int subjectId;

  const ProducersView({super.key, required this.subjectId});

  @override
  State<ProducersView> createState() => _ProducersViewState();
}

class _ProducersViewState extends State<ProducersView> {
  StaffItem? staff;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getStaff();
  }

  ///获取制作人信息
  void _getStaff() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final staffData = await BgmRequest.getProducersService(widget.subjectId,
          limit: 10, offset: 0);
      if (!mounted) return;
      setState(() {
        staff = staffData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      Logger().e(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final staffData = staff;
    if (staffData == null || staffData.data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '制作人',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: staffData.data.length,
            itemBuilder: (BuildContext context, int index) {
              final staffItem = staffData.data[index];
              return SizedBox(
                width: 90,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: AnimationNetworkImage(
                          borderRadius: BorderRadius.circular(10),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          url: staffItem.staff.images?.medium ??
                              Constants.notImage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      staffItem.staff.nameCN ?? staffItem.staff.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      staffItem.positions.isNotEmpty
                          ? staffItem.positions[0].type.cn
                          : '',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).disabledColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
