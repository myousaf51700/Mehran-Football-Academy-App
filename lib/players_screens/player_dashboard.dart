import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:mehran_football_academy/my_components/my_drawers.dart';
import 'package:mehran_football_academy/admin_screens/uploading_module/pending_matches_screen.dart';
import 'package:mehran_football_academy/my_media/notifications.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:mehran_football_academy/admin_screens/uploading_module/matches_records.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlayerDashboard extends StatefulWidget {
  const PlayerDashboard({super.key});

  @override
  State<PlayerDashboard> createState() => _PlayerDashboardState();
}

class _PlayerDashboardState extends State<PlayerDashboard> {
  final PageController _pageController = PageController();
  final PageController _cardPageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  int _currentCardPage = 0;
  late Timer _timer;
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> goalsByPosition = [];
  List<Map<String, dynamic>> cumulativeGoalsOverTime = [];
  List<Map<String, dynamic>> topPlayersGoals = [];
  Map<String, dynamic>? topScorer;
  Map<String, dynamic>? topAssister;
  Map<String, dynamic>? lastMatch;
  bool isLoading = true;
  bool isRefreshing = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _loadData();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _cardPageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (mounted && _currentPage < 4) {
        _currentPage++;
      } else if (mounted) {
        _currentPage = 0;
      }
      if (mounted) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('player_dashboard_data');

    if (cachedData != null) {
      final data = jsonDecode(cachedData);
      if (mounted) {
        setState(() {
          goalsByPosition = List<Map<String, dynamic>>.from(data['goalsByPosition']);
          cumulativeGoalsOverTime = List<Map<String, dynamic>>.from(data['cumulativeGoalsOverTime']);
          topPlayersGoals = List<Map<String, dynamic>>.from(data['topPlayersGoals']);
          topScorer = data['topScorer'] != null ? Map<String, dynamic>.from(data['topScorer']) : null;
          topAssister = data['topAssister'] != null ? Map<String, dynamic>.from(data['topAssister']) : null;
          lastMatch = data['lastMatch'] != null ? Map<String, dynamic>.from(data['lastMatch']) : null;
          isLoading = false;
        });
      }
    } else {
      await _fetchChartData();
    }
  }

  Future<void> _fetchChartData() async {
    if (mounted) {
      setState(() {
        isRefreshing = true;
        if (goalsByPosition.isEmpty && cumulativeGoalsOverTime.isEmpty && topPlayersGoals.isEmpty) {
          isLoading = true;
        }
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final positionResponse = await _supabase
          .from('player_statistics')
          .select('position, total_goals')
          .not('position', 'is', null);

      final Map<String, double> positionGoalsMap = {};
      for (var record in positionResponse) {
        final position = record['position'] as String;
        final goals = (record['total_goals'] as int).toDouble();
        positionGoalsMap[position] = (positionGoalsMap[position] ?? 0) + goals;
      }
      goalsByPosition = positionGoalsMap.entries
          .map((entry) => {'position': entry.key, 'goals': entry.value})
          .toList();

      final matchResponse = await _supabase
          .from('match')
          .select('match_time')
          .order('match_time', ascending: true);

      final playerStatsResponse = await _supabase
          .from('player_statistics')
          .select('total_goals');

      double cumulativeGoals = 0;
      for (var stat in playerStatsResponse) {
        cumulativeGoals += (stat['total_goals'] as int).toDouble();
      }

      cumulativeGoalsOverTime = [];
      double goalsPerMatch = matchResponse.isNotEmpty ? cumulativeGoals / matchResponse.length : 0;
      double runningTotal = 0;
      for (int i = 0; i < matchResponse.length; i++) {
        runningTotal += goalsPerMatch;
        cumulativeGoalsOverTime.add({
          'match_index': i.toDouble(),
          'cumulative_goals': runningTotal,
        });
      }

      final topPlayersResponse = await _supabase
          .from('player_statistics')
          .select('user_id, total_goals')
          .order('total_goals', ascending: false)
          .limit(3);

      topPlayersGoals = [];
      for (var record in topPlayersResponse) {
        final userId = record['user_id'].toString();
        final playerResponse = await _supabase
            .from('players_records')
            .select('full_name')
            .eq('user_id', userId)
            .single();

        topPlayersGoals.add({
          'user_id': userId,
          'goals': (record['total_goals'] as int).toDouble(),
          'full_name': playerResponse['full_name']?.toString() ?? 'Unknown',
        });
      }

      final topScorerResponse = await _supabase
          .from('player_statistics')
          .select('user_id, total_goals')
          .order('total_goals', ascending: false)
          .limit(1)
          .single();

      if (topScorerResponse != null) {
        final scorerUserId = topScorerResponse['user_id'].toString();
        final scorerDetails = await _supabase
            .from('players_records')
            .select('full_name, profile_url')
            .eq('user_id', scorerUserId)
            .single();

        final profileUrl = scorerDetails['profile_url']?.toString();
        if (profileUrl != null) {
          await prefs.setString('player_top_scorer_profile_$scorerUserId', profileUrl);
        }

        topScorer = {
          'full_name': scorerDetails['full_name']?.toString() ?? 'Unknown',
          'profile_url': profileUrl,
          'total_goals': (topScorerResponse['total_goals'] as int).toDouble(),
        };
      }

      final topAssisterResponse = await _supabase
          .from('player_statistics')
          .select('user_id, total_assists')
          .order('total_assists', ascending: false)
          .limit(1)
          .single();

      if (topAssisterResponse != null) {
        final assisterUserId = topAssisterResponse['user_id'].toString();
        final assisterDetails = await _supabase
            .from('players_records')
            .select('full_name, profile_url')
            .eq('user_id', assisterUserId)
            .single();

        final profileUrl = assisterDetails['profile_url']?.toString();
        if (profileUrl != null) {
          await prefs.setString('player_top_assister_profile_$assisterUserId', profileUrl);
        }

        topAssister = {
          'full_name': assisterDetails['full_name']?.toString() ?? 'Unknown',
          'profile_url': profileUrl,
          'total_assists': (topAssisterResponse['total_assists'] as int).toDouble(),
        };
      }

      final lastMatchResponse = await _supabase
          .from('match')
          .select('match_id, opponent_team, match_score, result_status, man_of_the_match')
          .order('match_time', ascending: false)
          .limit(1)
          .single();

      if (lastMatchResponse != null) {
        lastMatch = {
          'match_id': lastMatchResponse['match_id'].toString(),
          'opponent_team': lastMatchResponse['opponent_team']?.toString() ?? 'Unknown',
          'match_score': lastMatchResponse['match_score']?.toString() ?? 'N/A',
          'result_status': lastMatchResponse['result_status']?.toString() ?? 'Unknown',
          'man_of_the_match': lastMatchResponse['man_of_the_match']?.toString() ?? 'Unknown',
        };
      }

      await prefs.setString(
        'player_dashboard_data',
        jsonEncode({
          'goalsByPosition': goalsByPosition,
          'cumulativeGoalsOverTime': cumulativeGoalsOverTime,
          'topPlayersGoals': topPlayersGoals,
          'topScorer': topScorer,
          'topAssister': topAssister,
          'lastMatch': lastMatch,
        }),
      );

      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const PlayerDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _fetchChartData,
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: 5,
                            onPageChanged: (int page) {
                              if (mounted) {
                                setState(() {
                                  _currentPage = page;
                                });
                              }
                            },
                            itemBuilder: (context, index) {
                              return _buildDecoratedImageCard('assets/image${index + 1}.jpg');
                            },
                          ),
                          Builder(
                            builder: (context) => Positioned(
                              top: 10,
                              left: 10,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 50,
                            child: IconButton(
                              icon: const Icon(
                                Icons.call_to_action_sharp,
                                color: Colors.white,
                                size: 25,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MatchesRecords()),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Notifications()),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentPage == index ? Colors.blue : Colors.grey,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        'Academy Performance',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          fontFamily: 'RubikMedium',
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        SizedBox(
                          height: 210,
                          child: PageView(
                            controller: _cardPageController,
                            onPageChanged: (int page) {
                              if (mounted) {
                                setState(() {
                                  _currentCardPage = page;
                                });
                              }
                            },
                            children: [
                              if (topScorer != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 500),
                                    child: _buildStatCard(
                                      title: 'Top Scorer',
                                      value: topScorer!['total_goals'].toInt().toString(),
                                      lottieAsset: 'assets/scorer.json',
                                      gradient: const LinearGradient(
                                        colors: [Colors.orange, Colors.deepOrangeAccent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      subtitle: topScorer!['full_name'],
                                      imageUrl: topScorer!['profile_url'],
                                    ),
                                  ),
                                ),
                              if (topAssister != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 500),
                                    child: _buildStatCard(
                                      title: 'Top Assister',
                                      value: topAssister!['total_assists'].toInt().toString(),
                                      lottieAsset: 'assets/assister.json',
                                      gradient: const LinearGradient(
                                        colors: [Colors.green, Colors.greenAccent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      subtitle: topAssister!['full_name'],
                                      imageUrl: topAssister!['profile_url'],
                                    ),
                                  ),
                                ),
                              if (lastMatch != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 500),
                                    child: _buildStatCard(
                                      title: 'Man of the Match',
                                      value: lastMatch!['match_score'],
                                      lottieAsset: 'assets/mtm.json',
                                      gradient: const LinearGradient(
                                        colors: [Colors.blue, Colors.blueAccent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      subtitle: lastMatch!['man_of_the_match'],
                                      secondarySubtitle: 'vs ${lastMatch!['opponent_team']} (${lastMatch!['result_status']})',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Goal Distribution by Top Players',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            fontFamily: 'RubikMedium',
                            color: Color(0xff3E8530),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 150,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 30,
                              sections: topPlayersGoals.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value;
                                return PieChartSectionData(
                                  color: Colors.primaries[index % Colors.primaries.length],
                                  value: data['goals'] as double,
                                  title:
                                  '${((data['goals'] / topPlayersGoals.fold(0.0, (sum, item) => sum + (item['goals'] as double))) * 100).toStringAsFixed(1)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Rubik',
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: topPlayersGoals.asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    color: Colors.primaries[index % Colors.primaries.length],
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    data['full_name'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Rubik',
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Total Goals by Position',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            fontFamily: 'RubikMedium',
                            color: Color(0xff3E8530),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 150,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (goalsByPosition.isNotEmpty
                                  ? goalsByPosition
                                  .map((e) => e['goals'] as double)
                                  .reduce((a, b) => a > b ? a : b)
                                  : 0) *
                                  1.2,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      if (value.toInt() < 0 ||
                                          value.toInt() >= goalsByPosition.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        goalsByPosition[value.toInt()]['position'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'Rubik',
                                          color: Colors.black,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'Rubik',
                                          color: Colors.black,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: goalsByPosition.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data['goals'] as double,
                                      color: Colors.blue,
                                      width: 12,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Cumulative Goals Over Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            fontFamily: 'RubikMedium',
                            color: Color(0xff3E8530),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 150,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LineChart(
                            LineChartData(
                              lineTouchData: const LineTouchData(enabled: false),
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(
                                        'Match ${value.toInt() + 1}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'Rubik',
                                          color: Colors.black,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'Rubik',
                                          color: Colors.black,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: cumulativeGoalsOverTime.length > 0
                                  ? (cumulativeGoalsOverTime.length - 1).toDouble()
                                  : 0,
                              minY: 0,
                              maxY: cumulativeGoalsOverTime.isNotEmpty
                                  ? cumulativeGoalsOverTime
                                  .map((e) => e['cumulative_goals'] as double)
                                  .reduce((a, b) => a > b ? a : b) *
                                  1.2
                                  : 10,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: cumulativeGoalsOverTime
                                      .asMap()
                                      .entries
                                      .map((entry) => FlSpot(
                                    entry.key.toDouble(),
                                    entry.value['cumulative_goals'] as double,
                                  ))
                                      .toList(),
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 2,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blue.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ],
                ),
              ),
              if (isLoading && !isRefreshing)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecoratedImageCard(String imagePath) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 310,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    IconData? icon,
    String? lottieAsset,
    required LinearGradient gradient,
    String? subtitle,
    String? secondarySubtitle,
    String? imageUrl,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 210,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lottieAsset != null)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Lottie.asset(
                      lottieAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 60.0, top: 10),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Rubik',
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (imageUrl != null && imageUrl.isNotEmpty && (title == 'Top Scorer' || title == 'Top Assister'))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 20,
                    backgroundImage: imageProvider,
                    backgroundColor: Colors.white,
                  ),
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                    fontFamily: 'Rubik',
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (secondarySubtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  secondarySubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white70,
                    fontFamily: 'Rubik',
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}