import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { TrendingUp, Target, Clock, Star, Trophy, Award, Zap } from 'lucide-react-native';
import { useTheme } from '@/contexts/ThemeContext';

const { width } = Dimensions.get('window');

export default function ProgressScreen() {
  const { colors } = useTheme();

  const stats = {
    problemsSolved: 127,
    hoursLearned: 42,
    dayStreak: 7,
    totalPoints: 2840,
    level: 12,
    rank: 'Learning Explorer',
  };

  const subjects = [
    {
      id: '1',
      name: 'Mathematics',
      progress: 85,
      color: colors.primary,
      problems: 47,
      totalProblems: 60,
    },
    {
      id: '2',
      name: 'Science',
      progress: 70,
      color: colors.primaryDark,
      problems: 32,
      totalProblems: 45,
    },
    {
      id: '3',
      name: 'History',
      progress: 60,
      color: '#6366F1',
      problems: 28,
      totalProblems: 50,
    },
  ];

  const achievements = [
    {
      id: '1',
      title: 'Problem Solver',
      description: 'Solved 50 problems',
      icon: Target,
      color: colors.primary,
      progress: 50,
      maxProgress: 50,
    },
    {
      id: '2',
      title: 'Streak Master',
      description: '7 days in a row',
      icon: Star,
      color: '#EF4444',
    },
    {
      id: '3',
      title: 'Quick Learner',
      description: 'Completed 5 topics',
      icon: Zap,
      color: '#F59E0B',
    },
  ];

  const StatCard = ({ icon: Icon, label, value, suffix = '', color = colors.primary }: any) => (
    <TouchableOpacity style={styles.statCard} activeOpacity={0.8}>
      <LinearGradient
        colors={[color + '20', color + '10']}
        style={styles.statGradient}
      >
        <View style={[styles.statIcon, { backgroundColor: color + '30' }]}>
          <Icon size={20} color={color} />
        </View>
        <Text style={[styles.statValue, { color }]}>{value}{suffix}</Text>
        <Text style={[styles.statLabel, { color: colors.textSecondary }]}>{label}</Text>
      </LinearGradient>
    </TouchableOpacity>
  );

  return (
    <ScrollView
      style={[styles.container, { backgroundColor: colors.background }]}
      showsVerticalScrollIndicator={false}
    >
      {/* Header */}
      <LinearGradient colors={[colors.primary, colors.primaryDark]} style={styles.header}>
        <View style={styles.headerContent}>
          <View style={styles.headerTop}>
            <View>
              <Text style={[styles.headerTitle, { color: colors.text }]}>Your Progress</Text>
              <Text style={[styles.headerSubtitle, { color: colors.textSecondary }]}>
                Level {stats.level} • {stats.rank}
              </Text>
            </View>
            <View style={[styles.pointsBadge, { backgroundColor: 'rgba(255,255,255,0.1)' }]}>
              <Zap size={16} color="#FFD700" />
              <Text style={[styles.pointsText, { color: colors.text }]}>{stats.totalPoints}</Text>
            </View>
          </View>

          {/* Stats Grid */}
          <View style={styles.statsGrid}>
            <StatCard
              icon={Target}
              label="Problems"
              value={stats.problemsSolved}
              color={colors.primary}
            />
            <StatCard
              icon={Clock}
              label="Hours"
              value={stats.hoursLearned}
              color={colors.primaryDark}
            />
            <StatCard
              icon={Star}
              label="Streak"
              value={stats.dayStreak}
              suffix=" days"
              color="#EF4444"
            />
          </View>
        </View>
      </LinearGradient>

      <View style={styles.content}>
        {/* Subjects Progress */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.text }]}>Subject Progress</Text>
          {subjects.map((subject) => (
            <TouchableOpacity key={subject.id} style={[styles.subjectCard, { backgroundColor: colors.surface }]}>
              <View style={styles.subjectLeft}>
                <View style={[styles.progressRing, { borderColor: subject.color }]}>
                  <Text style={[styles.progressPercentage, { color: colors.text }]}>{subject.progress}%</Text>
                </View>
                <View style={styles.subjectInfo}>
                  <Text style={[styles.subjectName, { color: colors.text }]}>{subject.name}</Text>
                  <Text style={[styles.subjectStats, { color: colors.textSecondary }]}>
                    {subject.problems}/{subject.totalProblems} problems
                  </Text>
                </View>
              </View>
            </TouchableOpacity>
          ))}
        </View>

        {/* Achievements */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.text }]}>Recent Achievements</Text>
          <View style={styles.achievementsGrid}>
            {achievements.map((achievement) => (
              <TouchableOpacity
                key={achievement.id}
                style={[styles.achievementCard, { backgroundColor: colors.surface }]}
              >
                <View style={[styles.achievementIcon, { backgroundColor: achievement.color + '20' }]}>
                  <achievement.icon size={24} color={achievement.color} />
                </View>
                <Text style={[styles.achievementTitle, { color: colors.text }]}>{achievement.title}</Text>
                <Text style={[styles.achievementDescription, { color: colors.textSecondary }]}>
                  {achievement.description}
                </Text>
                {achievement.progress && (
                  <View style={styles.progressContainer}>
                    <View style={[styles.progressBar, { backgroundColor: colors.border }]}>
                      <View
                        style={[
                          styles.progressFill,
                          {
                            width: `${(achievement.progress / achievement.maxProgress!) * 100}%`,
                            backgroundColor: achievement.color,
                          },
                        ]}
                      />
                    </View>
                    <Text style={[styles.progressText, { color: colors.textSecondary }]}>
                      {achievement.progress}/{achievement.maxProgress}
                    </Text>
                  </View>
                )}
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Insights */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.text }]}>Learning Insights</Text>
          <View style={[styles.insightCard, { backgroundColor: colors.surface }]}>
            <LinearGradient
              colors={[colors.surface, colors.surfaceSecondary]}
              style={styles.insightGradient}
            >
              <TrendingUp size={24} color={colors.primary} />
              <Text style={[styles.insightTitle, { color: colors.text }]}>You're on Fire! 🔥</Text>
              <Text style={[styles.insightText, { color: colors.textSecondary }]}>
                Your problem-solving speed has improved by 40% this week.
                Keep challenging yourself with harder problems!
              </Text>
            </LinearGradient>
          </View>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingTop: 60,
    paddingBottom: 30,
    paddingHorizontal: 20,
  },
  headerContent: {
    alignItems: 'center',
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%',
    marginBottom: 24,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#FFF',
    marginBottom: 4,
  },
  headerSubtitle: {
    fontSize: 16,
    color: '#E5E7EB',
  },
  pointsBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
  },
  pointsText: {
    fontWeight: '600',
    marginLeft: 4,
  },
  statsGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '100%',
    gap: 12,
  },
  statCard: {
    flex: 1,
    borderRadius: 12,
    overflow: 'hidden',
  },
  statGradient: {
    padding: 16,
    alignItems: 'center',
  },
  statIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  statValue: {
    fontSize: 24,
    fontWeight: '700',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    textAlign: 'center',
  },
  content: {
    padding: 20,
  },
  section: {
    marginBottom: 30,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 16,
  },
  subjectCard: {
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    flexDirection: 'row',
    alignItems: 'center',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  subjectLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  progressRing: {
    width: 60,
    height: 60,
    borderRadius: 30,
    borderWidth: 4,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  progressPercentage: {
    fontSize: 12,
    fontWeight: '600',
  },
  subjectInfo: {
    flex: 1,
  },
  subjectName: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 4,
  },
  subjectStats: {
    fontSize: 14,
  },
  achievementsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  achievementCard: {
    width: (width - 60) / 2,
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  achievementIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  achievementTitle: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 4,
    textAlign: 'center',
  },
  achievementDescription: {
    fontSize: 12,
    textAlign: 'center',
    marginBottom: 12,
  },
  progressContainer: {
    width: '100%',
  },
  progressBar: {
    height: 4,
    borderRadius: 2,
    marginBottom: 4,
  },
  progressFill: {
    height: '100%',
    borderRadius: 2,
  },
  progressText: {
    fontSize: 10,
    textAlign: 'center',
  },
  insightCard: {
    borderRadius: 12,
    overflow: 'hidden',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  insightGradient: {
    padding: 20,
    alignItems: 'center',
  },
  insightTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginTop: 12,
    marginBottom: 8,
  },
  insightText: {
    fontSize: 14,
    textAlign: 'center',
    lineHeight: 20,
  },
});