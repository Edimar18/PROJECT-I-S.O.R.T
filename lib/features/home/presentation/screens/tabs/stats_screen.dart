
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

    final leaderboardFutures = List.generate(10, (i) => 
        FirebaseFirestore.instance.collection('leaderboard').doc('rank_${i + 1}').get());
    
    final userDocFuture = FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    final results = await Future.wait([Future.wait(leaderboardFutures), userDocFuture]);

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
      appBar: AppBar(
        title: const Text('Leaderboard', style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!['leaderboard'] == null || snapshot.data!['leaderboard'].isEmpty) {
            return const Center(child: Text('Leaderboard is empty.'));
          }

          final List<Map<String, dynamic>> leaderboard = List.from(snapshot.data!['leaderboard']);
          final Map<String, dynamic> currentUser = Map.from(snapshot.data!['currentUser']);
          final int currentUserRank = currentUser['rank'] ?? 0;
          final String currentUsername = currentUser['nickname'] ?? '';

          final List<Map<String, dynamic>> topThree = leaderboard.length > 3 ? leaderboard.sublist(0, 3) : leaderboard;
          final List<Map<String, dynamic>> others = leaderboard.length > 3 ? leaderboard.sublist(3) : [];
          
          bool isUserInTop10 = leaderboard.any((player) => player['username'] == currentUsername);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dataFuture = _fetchData();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (topThree.isNotEmpty) _buildTopThree(context, topThree),
                  const SizedBox(height: 24),
                  if (others.isNotEmpty) _buildLeaderboardList(context, others),
                  if (!isUserInTop10 && currentUserRank > 10)
                    _buildCurrentUserRank(context, currentUser),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopThree(BuildContext context, List<Map<String, dynamic>> topThree) {
    final orderedTopThree = <Map<String, dynamic>>[];
    if (topThree.length > 1) orderedTopThree.add(topThree[1]); // 2nd
    if (topThree.isNotEmpty) orderedTopThree.add(topThree[0]); // 1st
    if (topThree.length > 2) orderedTopThree.add(topThree[2]); // 3rd

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(orderedTopThree.length, (index) {
        int rank;
        Map<String, dynamic> playerData;
        if(index == 0) { 
          rank = 2;
          playerData = orderedTopThree[index];
        } else if (index == 1) { 
          rank = 1;
          playerData = orderedTopThree[index];
        } else { 
          rank = 3;
          playerData = orderedTopThree[index];
        }
        
        return _buildTopPlayer(
          context,
          rank: rank,
          playerData: playerData,
          isFirst: rank == 1,
        );
      }),
    );
  }
  
  Widget _buildTopPlayer(BuildContext context, {required int rank, required Map<String, dynamic> playerData, bool isFirst = false}) {
    final colors = [Colors.amber, Colors.grey.shade400, const Color(0xFFCD7F32)]; // Gold, Silver, Bronze
    final color = colors[rank - 1];
    final double avatarRadius = isFirst ? 50 : 40;
    final double verticalPadding = isFirst ? 20 : 10;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: verticalPadding),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: color.withOpacity(0.3),
                child: CircleAvatar(
                  radius: avatarRadius - 5,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: color, size: avatarRadius),
                ),
              ),
              Positioned(
                bottom: 0,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: color,
                  child: Text('#$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(playerData['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('${(playerData['total_points'] as num).toInt()} pts', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(playerData['location'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(BuildContext context, List<Map<String, dynamic>> players) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final rank = index + 4;
        return _buildRankItem(context, player: player, rank: rank);
      },
    );
  }

  Widget _buildCurrentUserRank(BuildContext context, Map<String, dynamic> currentUser) {
     final player = {
       'username': currentUser['nickname'],
       'total_points': currentUser['totalPoints'],
       'location': currentUser['address'],
     };
     final rank = currentUser['rank'];
     return _buildRankItem(context, player: player, rank: rank, isCurrentUser: true);
  }

  Widget _buildRankItem(BuildContext context, {required Map<String, dynamic> player, required int rank, bool isCurrentUser = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFF1de9b6).withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isCurrentUser ? const Color(0xFF1de9b6) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text('#$rank', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.person, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(player['location'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text('${(player['total_points'] as num).toInt()} pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333))),
        ],
      ),
    );
  }
}
