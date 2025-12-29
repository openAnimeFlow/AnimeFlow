import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/enums/sort_type.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:anime_flow/widget/subject_carf.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  SubjectItem? subject;
  Logger logger = Logger();

  // 下拉菜单状态
  SortType _selectedSort = SortType.rank;
  int? _selectedYear;
  int? _selectedMonth;

  // 年份列表（从当前年份往前推20年）
  List<int> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(20, (index) => currentYear - index);
  }

  // 月份列表
  List<int> get _months => List.generate(12, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _getRanking();
  }

  void _getRanking() async {
    final response = await BgmRequest.rankService(
        page: 0, sort: _selectedSort, year: _selectedYear, month: _selectedMonth);
    setState(() {
      subject = response;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (subject == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      final subject = this.subject!.data;
      return Scaffold(
        appBar: AppBar(
          title: const Text('排行榜'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: PlayLayoutConstant.maxWidth),
            child: CustomScrollView(slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                title: Center(
                  child: Wrap(
                    spacing: 16,
                    children: [
                      // 排序类型下拉
                      DropdownButton<SortType>(
                        value: _selectedSort,
                        underline: const SizedBox(),
                        items: SortType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSort = value;
                            });
                            _getRanking();
                          }
                        },
                      ),
                      // 年份下拉
                      DropdownButton<int?>(
                        value: _selectedYear,
                        underline: const SizedBox(),
                        hint: const Text('全部年份'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('全部'),
                          ),
                          ..._years.map((year) {
                            return DropdownMenuItem(
                              value: year,
                              child: Text('$year年'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                          _getRanking();
                        },
                      ),
                      // 月份下拉
                      DropdownButton<int?>(
                        value: _selectedMonth,
                        underline: const SizedBox(),
                        hint: const Text('全部月份'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('全部'),
                          ),
                          ..._months.map((month) {
                            return DropdownMenuItem(
                              value: month,
                              child: Text('$month月'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                          });
                          _getRanking();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(10),
                sliver: SliverGrid.builder(
                  itemCount: subject.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: LayoutUtil.getCrossAxisCount(context),
                    crossAxisSpacing: 5, // 横向间距
                    mainAxisSpacing: 5, // 纵向间距
                    childAspectRatio: 0.7, // 宽高比
                  ),
                  itemBuilder: (context, index) {
                    final data = subject[index];
                    return SubjectCarfView(subject: data);
                  },
                ),
              )
            ]),
          ),
        ),
      );
    }
  }
}
