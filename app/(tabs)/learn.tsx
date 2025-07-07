import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { 
  BookOpen, 
  Plus,
  Type,
  Mic,
  Camera,
} from 'lucide-react-native';
import { useTheme } from '@/contexts/ThemeContext';

export default function LearnScreen() {
  const { colors } = useTheme();

  const inputMethods = [
    {
      id: 'text',
      title: 'Type Problem',
      description: 'Enter your question or problem as text',
      icon: Type,
      color: colors.primary,
    },
    {
      id: 'voice',
      title: 'Voice Input',
      description: 'Record your question using voice',
      icon: Mic,
      color: colors.primaryDark,
    },
    {
      id: 'camera',
      title: 'Capture Image',
      description: 'Take a photo of your problem',
      icon: Camera,
      color: '#6366F1',
    },
  ];

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Header */}
      <LinearGradient colors={[colors.primary, colors.primaryDark]} style={styles.header}>
        <View style={styles.headerContent}>
          <Text style={[styles.headerTitle, { color: colors.text }]}>Start Learning</Text>
          <Text style={[styles.headerSubtitle, { color: colors.textSecondary }]}>
            How would you like to submit your problem?
          </Text>
        </View>
      </LinearGradient>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Input Methods */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.text }]}>Choose Input Method</Text>
          
          {inputMethods.map((method) => (
            <TouchableOpacity
              key={method.id}
              style={[styles.methodCard, { backgroundColor: colors.surface }]}
              activeOpacity={0.8}
            >
              <LinearGradient
                colors={[method.color + '20', method.color + '10']}
                style={styles.methodGradient}
              >
                <View style={[styles.methodIcon, { backgroundColor: method.color + '30' }]}>
                  <method.icon size={32} color={method.color} />
                </View>
                <View style={styles.methodContent}>
                  <Text style={[styles.methodTitle, { color: colors.text }]}>{method.title}</Text>
                  <Text style={[styles.methodDescription, { color: colors.textSecondary }]}>
                    {method.description}
                  </Text>
                </View>
                <Plus size={20} color={colors.textTertiary} />
              </LinearGradient>
            </TouchableOpacity>
          ))}
        </View>

        {/* Recent Problems */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.text }]}>Recent Problems</Text>
          
          <View style={[styles.emptyState, { backgroundColor: colors.surface }]}>
            <BookOpen size={48} color={colors.textTertiary} />
            <Text style={[styles.emptyTitle, { color: colors.text }]}>No problems yet</Text>
            <Text style={[styles.emptySubtitle, { color: colors.textSecondary }]}>
              Start by submitting your first problem above
            </Text>
          </View>
        </View>
      </ScrollView>
    </View>
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
  content: {
    flex: 1,
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
  methodCard: {
    borderRadius: 16,
    overflow: 'hidden',
    marginBottom: 16,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  methodGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 20,
  },
  methodIcon: {
    width: 60,
    height: 60,
    borderRadius: 30,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  methodContent: {
    flex: 1,
  },
  methodTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 4,
  },
  methodDescription: {
    fontSize: 14,
    lineHeight: 20,
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
    paddingHorizontal: 20,
    borderRadius: 16,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '600',
    marginTop: 16,
    marginBottom: 8,
  },
  emptySubtitle: {
    fontSize: 16,
    textAlign: 'center',
    lineHeight: 24,
  },
});