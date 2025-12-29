import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';


class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  SubjectItem? subjectItem;
  Logger logger = Logger();
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
          title: const Text('排行榜'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: const CustomScrollView(slivers: [
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
