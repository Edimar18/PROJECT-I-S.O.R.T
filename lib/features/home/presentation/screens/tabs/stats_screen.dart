import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Future<Map<String, dynamic>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final leaderboardFutures = List.generate(
        10,
            (i) => FirebaseFirestore.instance
            .collection('leaderboard')
            .doc('rank_${i + 1}')
            .get());

    final userDocFuture =
    FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    final results =
    await Future.wait([Future.wait(leaderboardFutures), userDocFuture]);

    final leaderboardSnapshots = results[0] as List<DocumentSnapshot>;
    final userDoc = results[1] as DocumentSnapshot;

    final leaderboard = leaderboardSnapshots
        .where((doc) => doc.exists)
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    final currentUserData = userDoc.data() as Map<String, dynamic>? ?? {};

    return {'leaderboard': leaderboard, 'currentUser': currentUserData};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1de9b6)),
                ));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Error loading leaderboard',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          if (!snapshot.hasData ||
              snapshot.data!['leaderboard'] == null ||
              snapshot.data!['leaderboard'].isEmpty) {
            return _buildEmptyState();
          }

          final List<Map<String, dynamic>> leaderboard =
          List.from(snapshot.data!['leaderboard']);
          final Map<String, dynamic> currentUser =
          Map.from(snapshot.data!['currentUser']);
          final int currentUserRank = currentUser['rank'] ?? 0;
          final String currentUsername = currentUser['nickname'] ?? '';

          final List<Map<String, dynamic>> topThree =
          leaderboard.length > 3 ? leaderboard.sublist(0, 3) : leaderboard;
          final List<Map<String, dynamic>> others =
          leaderboard.length > 3 ? leaderboard.sublist(3) : [];

          bool isUserInTop10 =
          leaderboard.any((player) => player['username'] == currentUsername);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dataFuture = _fetchData();
              });
            },
            color: const Color(0xFF1de9b6),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHeader(currentUser),
                      const SizedBox(height: 20),
                      if (topThree.isNotEmpty)
                        _buildTopThree(context, topThree, currentUsername),
                      const SizedBox(height: 24),
                      if (others.isNotEmpty)
                        _buildLeaderboardList(context, others, currentUsername),
                      if (!isUserInTop10 && currentUserRank > 10) ...[
                        const SizedBox(height: 16),
                        _buildCurrentUserRank(context, currentUser),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1de9b6),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1de9b6),
                const Color(0xFF1de9b6).withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.emoji_events,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> currentUser) {
    final int rank = currentUser['rank'] ?? 0;
    final double totalPoints = (currentUser['totalPoints'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1de9b6).withValues(alpha: 0.15),
            const Color(0xFF1de9b6).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1de9b6).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1de9b6).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFF1de9b6),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Ranking',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      rank > 0 ? '#$rank' : 'Unranked',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1de9b6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${totalPoints.toInt()} pts',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Rankings Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Be the first to earn points!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree(BuildContext context, List<Map<String, dynamic>> topThree,
      String currentUsername) {
    final orderedTopThree = <Map<String, dynamic>>[];
    if (topThree.length > 1) orderedTopThree.add(topThree[1]); // 2nd
    if (topThree.isNotEmpty) orderedTopThree.add(topThree[0]); // 1st
    if (topThree.length > 2) orderedTopThree.add(topThree[2]); // 3rd

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Top 3 Champions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(orderedTopThree.length, (index) {
              int rank;
              Map<String, dynamic> playerData;
              if (index == 0) {
                rank = 2;
                playerData = orderedTopThree[index];
              } else if (index == 1) {
                rank = 1;
                playerData = orderedTopThree[index];
              } else {
                rank = 3;
                playerData = orderedTopThree[index];
              }

              bool isCurrentUser = playerData['username'] == currentUsername;

              return _buildTopPlayer(
                context,
                rank: rank,
                playerData: playerData,
                isFirst: rank == 1,
                isCurrentUser: isCurrentUser,
              );
            }),
            )),
        ],
      ),
    );
  }

  Widget _buildTopPlayer(
      BuildContext context, {
        required int rank,
        required Map<String, dynamic> playerData,
        bool isFirst = false,
        bool isCurrentUser = false,
      }) {
    final colors = [
      Colors.amber,
      Colors.grey.shade400,
      const Color(0xFFCD7F32)
    ]; // Gold, Silver, Bronze
    final color = colors[rank - 1];
    final double avatarRadius = isFirst ? 45 : 35;
    final double containerHeight = isFirst ? 140 : 120;

    return Container(
      width: 100,
      height: containerHeight+12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: CircleAvatar(
                    radius: avatarRadius - 4,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: color, size: avatarRadius),
                  ),
                ),
              ),
              if (isFirst)
                Positioned(
                  top: -5,
                  child: Icon(Icons.stars, color: color, size: 24),
                ),
              Positioned(
                bottom: -5,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (isCurrentUser)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1de9b6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            playerData['username'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 14 : 12,
              color: isCurrentUser ? const Color(0xFF1de9b6) : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${(playerData['total_points'] as num).toInt()}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'points',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(BuildContext context,
      List<Map<String, dynamic>> players, String currentUsername) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_list_numbered,
                  color: Color(0xFF1de9b6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Other Rankings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final rank = index + 4;
              final isCurrentUser = player['username'] == currentUsername;
              return _buildRankItem(
                context,
                player: player,
                rank: rank,
                isCurrentUser: isCurrentUser,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserRank(
      BuildContext context, Map<String, dynamic> currentUser) {
    final player = {
      'username': currentUser['nickname'],
      'total_points': currentUser['totalPoints'],
      'location': currentUser['address'],
    };
    final rank = currentUser['rank'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF1de9b6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Your Position',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRankItem(
            context,
            player: player,
            rank: rank,
            isCurrentUser: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(
      BuildContext context, {
        required Map<String, dynamic> player,
        required int rank,
        bool isCurrentUser = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF1de9b6).withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFF1de9b6)
              : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? const Color(0xFF1de9b6).withValues(alpha: 0.2)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser
                      ? const Color(0xFF1de9b6)
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? const Color(0xFF1de9b6).withValues(alpha: 0.2)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: isCurrentUser
                  ? const Color(0xFF1de9b6)
                  : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['username'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isCurrentUser
                        ? const Color(0xFF1de9b6)
                        : const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        player['location'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? const Color(0xFF1de9b6)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(player['total_points'] as num).toInt()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isCurrentUser ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}