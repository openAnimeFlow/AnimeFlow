import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../models/item/bangumi/hot_item.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  Logger logger = Logger();
  Subject? subject;
  @override
  void initState() {
    super.initState();
  }



  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("排行榜"),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1400),
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: Wrap(children: [
                    Text('排名'),Text('年'),Text('月')
                  ]),
                ),
              ),
            ]),
          ),
        ));
  }
}
