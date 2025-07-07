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
import { 
  BookOpen, 
  TrendingUp, 
  Target, 
  Clock, 
  Star, 
  Flame, 
  Trophy, 
  ChevronRight,
  Zap,
  Brain,
  Users,
  Award
} from 'lucide-react-native';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';

const { width } = Dimensions.get('window');

export default function HomeScreen() {
  const { user } = useAuth();
  const { colors } = useTheme();

  const quickActions = [
    {
      id: '1',
      title: 'Start Learning',
      description: 'Ask a question or solve a problem',
      icon: Brain,
      color: colors.primary,
    },
    {
      id: '2',
      title: 'View Progress',
      description: 'Track your learning journey',
      icon: TrendingUp,
      color: colors.primaryDark,
    },
    {
      id: '3',
      title: 'Study Groups',
      description: 'Join collaborative sessions',
      icon: Users,
      color: '#6366F1',
    },
    {
      id: '4',
      title: 'Achievements',
      description: 'View your accomplishments',
      icon: Award,
      color: '#F59E0B',
    },
  ];

  const recentActivities = [
    {
      id: '1',
      title: 'Quadratic Equations',
      subject: 'Mathematics',
      timeAgo: '2 hours ago',
      difficulty: 'medium',
    },
    {
      id: '2',
      title: 'Photosynthesis Process',
      subject: 'Biology',
      timeAgo: '1 day ago',
      difficulty: 'easy',
    },
    {
      id: '3',
      title: 'Newton\'s Laws',
      subject: 'Physics',
      timeAgo: '2 days ago',
      difficulty: 'hard',
    },
  ];

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'easy': return '#10B981';
      case 'medium': return '#F59E0B';
      case 'hard': return '#EF4444';
      default: return colors.textSecondary;
    }
  };

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  };

  return (
    <ScrollView 
      style={[styles.container, { backgroundColor: colors.background }]}
      showsVerticalScrollIndicator={false}
    >
      {/* Header */}
      <LinearGradient colors={[colors.primary, colors.primaryDark]} style={styles.header}>
        <View style={styles.headerContent}>
          <View style={styles.welcomeSection}>
            <Text style={[styles.greeting, { color: colors.textSecondary }]}>
              {getGreeting()}, {user?.firstName || 'Learner'}! 👋
            </Text>
            <Text style={[styles.welcomeTitle, { color: colors.text }]}>
              Ready to learn something new?
            </Text>
          </View>

          {/* Stats Overview */}
          <View style={[styles.statsContainer, { backgroundColor: 'rgba(255,255,255,0.1)' }]}>
            <View style={styles.statItem}>
              <View style={[styles.statIcon, { backgroundColor: colors.primary + '30' }]}>
                <BookOpen size={20} color={colors.primary} />
              </View>
              <Text style={[styles.statNumber, { color: colors.text }]}>127</Text>
              <Text style={[styles.statLabel, { color: colors.textSecondary }]}>Problems</Text>
            </View>
            
            <View style={[styles.statDivider, { backgroundColor: 'rgba(255,255,255,0.2)' }]} />
            
            <View style={styles.statItem}>
              <View style={[styles.statIcon, { backgroundColor: colors.primaryDark + '30' }]}>
                <Clock size={20} color={colors.primaryDark} />
              </View>
              <Text style={[styles.statNumber, { color: colors.text }]}>42</Text>
              <Text style={[styles.statLabel, { color: colors.textSecondary }]}>Hours</Text>
            </View>
            
            <View style={[styles.statDivider, { backgroundColor: 'rgba(255,255,255,0.2)' }]} />
            
            <View style={styles.statItem}>
              <View style={[styles.statIcon, { backgroundColor: '#EF4444' + '30' }]}>
                <Flame size={20} color="#EF4444" />
              </View>
              <Text style={[styles.statNumber, { color: colors.text }]}>7</Text>
              <Text style={[styles.statLabel, { color: colors.textSecondary }]}>Day Streak</Text>
            </View>
          </View>
        </View>
      </LinearGradient>

      <View style={styles.content}>
        {/* Quick Actions */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.text }]}>Quick Actions</Text>
          <View style={styles.quickActionsGrid}>
            {quickActions.map((action) => (
              <TouchableOpacity
                key={action.id}
                style={[styles.quickActionCard, { backgroundColor: colors.surface }]}
                activeOpacity={0.8}
              >
                <LinearGradient
                  colors={[action.color + '20', action.color + '10']}
                  style={styles.quickActionGradient}
                >
                  <View style={[styles.quickActionIcon, { backgroundColor: action.color + '30' }]}>
                    <action.icon size={24} color={action.color} />
                  </View>
                  <Text style={[styles.quickActionTitle, { color: colors.text }]}>{action.title}</Text>
                  <Text style={[styles.quickActionDescription, { color: colors.textSecondary }]}>
                    {action.description}
                  </Text>
                </LinearGradient>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Recent Activity */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={[styles.sectionTitle, { color: colors.text }]}>Recent Activity</Text>
            <TouchableOpacity>
              <Text style={[styles.seeAllText, { color: colors.primary }]}>See All</Text>
            </TouchableOpacity>
          </View>
          
          {recentActivities.map((activity) => (
            <TouchableOpacity
              key={activity.id}
              style={[styles.activityCard, { backgroundColor: colors.surface }]}
              activeOpacity={0.8}
            >
              <View style={styles.activityContent}>
                <Text style={[styles.activityTitle, { color: colors.text }]}>{activity.title}</Text>
                <Text style={[styles.activitySubject, { color: colors.primary }]}>{activity.subject}</Text>
                <View style={styles.activityMeta}>
                  <Text style={[styles.activityTime, { color: colors.textSecondary }]}>{activity.timeAgo}</Text>
                  <View style={[styles.difficultyBadge, { backgroundColor: getDifficultyColor(activity.difficulty) + '20' }]}>
                    <Text style={[styles.difficultyText, { color: getDifficultyColor(activity.difficulty) }]}>
                      {activity.difficulty}
                    </Text>
                  </View>
                </View>
              </View>
              <ChevronRight size={20} color={colors.textTertiary} />
            </TouchableOpacity>
          ))}
        </View>

        {/* Motivational Quote */}
        <View style={styles.section}>
          <View style={[styles.quoteCard, { backgroundColor: colors.surface }]}>
            <LinearGradient
              colors={['#6366F1' + '20', '#6366F1' + '10']}
              style={styles.quoteGradient}
            >
              <Star size={32} color="#6366F1" />
              <Text style={[styles.quoteText, { color: colors.text }]}>
                "The beautiful thing about learning is that no one can take it away from you."
              </Text>
              <Text style={[styles.quoteAuthor, { color: colors.textSecondary }]}>— B.B. King</Text>
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
  welcomeSection: {
    alignItems: 'center',
    marginBottom: 24,
  },
  greeting: {
    fontSize: 16,
    marginBottom: 8,
  },
  welcomeTitle: {
    fontSize: 24,
    fontWeight: '700',
    textAlign: 'center',
    color: '#FFF',
  },
  statsContainer: {
    flexDirection: 'row',
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
    justifyContent: 'space-around',
    width: '100%',
  },
  statItem: {
    alignItems: 'center',
    flex: 1,
  },
  statIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  statNumber: {
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    textAlign: 'center',
  },
  statDivider: {
    width: 1,
    height: 40,
    marginHorizontal: 16,
  },
  content: {
    padding: 20,
  },
  section: {
    marginBottom: 30,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '700',
  },
  seeAllText: {
    fontSize: 14,
    fontWeight: '600',
  },
  quickActionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 16,
  },
  quickActionCard: {
    width: (width - 60) / 2,
    borderRadius: 16,
    overflow: 'hidden',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  quickActionGradient: {
    padding: 20,
    alignItems: 'center',
    minHeight: 140,
  },
  quickActionIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  quickActionTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 4,
    textAlign: 'center',
  },
  quickActionDescription: {
    fontSize: 12,
    textAlign: 'center',
    lineHeight: 16,
  },
  activityCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  activityContent: {
    flex: 1,
  },
  activityTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 4,
  },
  activitySubject: {
    fontSize: 14,
    marginBottom: 8,
  },
  activityMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  activityTime: {
    fontSize: 12,
  },
  difficultyBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
  },
  difficultyText: {
    fontSize: 10,
    fontWeight: '600',
    textTransform: 'uppercase',
  },
  quoteCard: {
    borderRadius: 16,
    overflow: 'hidden',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  quoteGradient: {
    padding: 24,
    alignItems: 'center',
  },
  quoteText: {
    fontSize: 16,
    fontStyle: 'italic',
    textAlign: 'center',
    lineHeight: 24,
    marginVertical: 16,
  },
  quoteAuthor: {
    fontSize: 14,
    fontWeight: '600',
  },
});